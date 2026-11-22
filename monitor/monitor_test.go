package monitor

import (
	"errors"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"runtime"
	"sync"
	"sync/atomic"
	"testing"
)

func resetMonitorGlobals(t *testing.T) {
	t.Helper()
	origSettings := settings
	origPath := settingsPath
	origClient := client
	origLastStatus := lastStatus
	origLastModels := lastRunningModels
	origLogger := appLogger
	origNotify := notifyFn

	appLogger = log.New(io.Discard, "", 0)
	t.Cleanup(func() {
		settingsLock.Lock()
		settings = origSettings
		settingsPath = origPath
		settingsLock.Unlock()
		client = origClient
		lastStatus = origLastStatus
		lastRunningModels = origLastModels
		appLogger = origLogger
		notifyFn = origNotify
	})
}

func TestValidateAPIURL(t *testing.T) {
	valid := []struct {
		in   string
		want string
	}{
		{"http://localhost:11434", "http://localhost:11434"},
		{"  https://ollama.example.com///  ", "https://ollama.example.com"},
		{"http://bob:p%40ss@127.0.0.1:11434/", "http://bob:p%40ss@127.0.0.1:11434"},
	}
	for _, tc := range valid {
		got, u, err := validateAPIURL(tc.in)
		if err != nil {
			t.Fatalf("validateAPIURL(%q) unexpected error: %v", tc.in, err)
		}
		if got != tc.want || u == nil {
			t.Fatalf("validateAPIURL(%q) = %q, %v; want %q", tc.in, got, u, tc.want)
		}
	}

	invalid := []string{"", "   ", "httpfoo", "http://", "https://", "ftp://localhost:11434", "localhost:11434"}
	for _, raw := range invalid {
		if got, _, err := validateAPIURL(raw); err == nil {
			t.Fatalf("validateAPIURL(%q) succeeded with %q, want error", raw, got)
		}
	}
}

func TestRotatedWriter(t *testing.T) {
	dir := t.TempDir()
	logPath := filepath.Join(dir, "test.log")
	rw, err := NewRotatedWriter(logPath, 10)
	if err != nil {
		t.Fatalf("NewRotatedWriter: %v", err)
	}

	if _, err := rw.Write([]byte("123456")); err != nil {
		t.Fatalf("first Write: %v", err)
	}
	// Exceed maxSize (10) to trigger rotation.
	if _, err := rw.Write([]byte("abcdef")); err != nil {
		t.Fatalf("second Write (rotate): %v", err)
	}

	backups, err := filepath.Glob(logPath + ".*")
	if err != nil || len(backups) != 1 {
		t.Fatalf("expected 1 rotated backup, got %v (err=%v)", backups, err)
	}

	if err := rw.Close(); err != nil {
		t.Fatalf("Close: %v", err)
	}
	if _, err := rw.Write([]byte("after")); !errors.Is(err, os.ErrClosed) {
		t.Fatalf("Write after Close err = %v; want os.ErrClosed", err)
	}

	// Concurrent writes + Close must not panic or race.
	rw2, err := NewRotatedWriter(filepath.Join(dir, "race.log"), 64)
	if err != nil {
		t.Fatalf("NewRotatedWriter race: %v", err)
	}
	var wg sync.WaitGroup
	for range 4 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for range 20 {
				if _, wErr := rw2.Write([]byte("line\n")); wErr != nil && !errors.Is(wErr, os.ErrClosed) {
					t.Errorf("unexpected Write error: %v", wErr)
				}
			}
		}()
	}
	_ = rw2.Close()
	wg.Wait()
}

func TestConfigSaveLoad(t *testing.T) {
	resetMonitorGlobals(t)
	tmp := t.TempDir()
	t.Setenv("HOME", tmp)
	t.Setenv("XDG_CONFIG_HOME", tmp)
	t.Setenv("APPDATA", tmp)

	loadSettings()
	if settings.InsecureTLS {
		t.Fatal("default InsecureTLS should be false")
	}
	if settings.APIURL != "http://localhost:11434" {
		t.Fatalf("default APIURL = %q", settings.APIURL)
	}
	if runtime.GOOS != "windows" {
		info, err := os.Stat(settingsPath)
		if err != nil {
			t.Fatalf("Stat(%q): %v", settingsPath, err)
		}
		if mode := info.Mode().Perm(); mode != 0600 {
			t.Fatalf("settings.json mode = %o; want 0600", mode)
		}
	}

	settingsLock.Lock()
	settings.APIURL = "https://ollama.example.com"
	settings.InsecureTLS = true
	settingsLock.Unlock()
	saveSettings()

	settingsLock.Lock()
	settings = Settings{}
	settingsLock.Unlock()
	loadSettings()

	if settings.APIURL != "https://ollama.example.com" || !settings.InsecureTLS {
		t.Fatalf("reloaded settings = %+v; want updated APIURL and InsecureTLS=true", settings)
	}
}

func TestGetRunningModelsAndNotifications(t *testing.T) {
	resetMonitorGlobals(t)

	type note struct{ title, msg string }
	var notes []note
	notifyFn = func(title, msg string) {
		notes = append(notes, note{title, msg})
	}

	// 1. Cold start against closed server -> offline, no startup notification spam.
	dead := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	deadURL := dead.URL
	dead.Close()

	settingsLock.Lock()
	settings = Settings{APIURL: deadURL}
	settingsLock.Unlock()
	initHTTPClient()
	lastStatus = ""
	lastRunningModels = nil

	state, models := getRunningModels()
	if state != StateOffline || models != nil {
		t.Fatalf("cold offline = (%d, %v); want StateOffline, nil", state, models)
	}
	if len(notes) != 0 {
		t.Fatalf("cold offline sent notifications: %+v", notes)
	}

	// 2. Live server with Basic Auth, trailing slash, empty + non-empty parameter_size, and 500 error.
	var phase atomic.Int32
	var seenPath, seenAuth string
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		seenPath = r.URL.RequestURI()
		seenAuth = r.Header.Get("Authorization")
		switch phase.Load() {
		case 0:
			_, _ = io.WriteString(w, `{"models":[{"name":"gemma4:e4b","details":{"parameter_size":""}},{"name":"llama3.2:3b","details":{"parameter_size":"3.2B"}}]}`)
		case 1:
			_, _ = io.WriteString(w, `{"models":[{"name":"gemma4:e4b","details":{"parameter_size":""}},{"name":"qwen3:8b","details":{"parameter_size":"8B"}}]}`)
		default:
			http.Error(w, "boom", http.StatusInternalServerError)
		}
	}))
	defer srv.Close()

	// Insert credentials and trailing slash into srv.URL ("http://127.0.0.1:PORT").
	authURL := "http://bob:p%40ss@" + srv.Listener.Addr().String() + "/"
	settingsLock.Lock()
	settings.APIURL = authURL
	settingsLock.Unlock()
	lastStatus = ""
	lastRunningModels = nil
	notes = nil

	// Initial active poll populates state without startup spam.
	state, models = getRunningModels()
	if state != StateActive || len(models) != 2 || models[0] != "gemma4:e4b" || models[1] != "llama3.2:3b (3.2B)" {
		t.Fatalf("initial active = (%d, %v)", state, models)
	}
	if seenPath != "/api/ps" {
		t.Fatalf("request path = %q; want /api/ps", seenPath)
	}
	if seenAuth == "" {
		t.Fatal("expected Basic Authorization header")
	}
	if len(notes) != 0 {
		t.Fatalf("first active poll should not notify, got %+v", notes)
	}

	// Model swap triggers Started + Stopped notifications.
	phase.Store(1)
	state, models = getRunningModels()
	if state != StateActive || len(models) != 2 {
		t.Fatalf("swapped active = (%d, %v)", state, models)
	}
	if len(notes) != 2 || notes[0] != (note{"Model Started", "qwen3:8b (8B)"}) || notes[1] != (note{"Model Stopped", "llama3.2:3b (3.2B)"}) {
		t.Fatalf("swap notifications = %+v", notes)
	}

	// HTTP 500 notifies once, repeated 500 does not notify again.
	notes = nil
	phase.Store(2)
	state, _ = getRunningModels()
	if state != StateOffline || len(notes) != 1 || notes[0].title != "Ollama Service Stopped" {
		t.Fatalf("first 500 = (%d, %+v)", state, notes)
	}
	state, _ = getRunningModels()
	if state != StateOffline || len(notes) != 1 {
		t.Fatalf("second 500 should not re-notify, got (%d, %+v)", state, notes)
	}
}
