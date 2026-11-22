package monitor

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
)

// Settings structure
type Settings struct {
	Startup     bool   `json:"startup"`
	APIURL      string `json:"api_url"`
	InsecureTLS bool   `json:"insecure_tls,omitempty"`
}

var (
	settings     Settings
	settingsPath string
	settingsLock sync.Mutex
)

func appDataDir() string {
	if dir, err := os.UserConfigDir(); err == nil && dir != "" {
		return filepath.Join(dir, AppName)
	}
	return AppName
}

func loadSettings() {
	settingsPath = filepath.Join(appDataDir(), "settings.json")

	settingsLock.Lock()
	defer settingsLock.Unlock()

	file, err := os.Open(settingsPath)
	if err == nil {
		defer file.Close()
		decoder := json.NewDecoder(file)
		if err := decoder.Decode(&settings); err == nil {
			appLogger.Println("Settings loaded successfully")
			return
		}
	}

	// Default settings
	settings = Settings{
		Startup: false,
		APIURL:  fmt.Sprintf("http://%s:%s", APIHost, APIPort),
	}
	if err := saveSettingsLocked(); err != nil {
		appLogger.Printf("Failed to save default settings: %v", err)
		return
	}
	appLogger.Println("Created default settings")
}

func saveSettingsLocked() error {
	if err := os.MkdirAll(filepath.Dir(settingsPath), 0700); err != nil {
		return err
	}
	file, err := os.OpenFile(settingsPath, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0600)
	if err != nil {
		return err
	}

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "    ")
	if err := encoder.Encode(settings); err != nil {
		_ = file.Close()
		return err
	}
	return file.Close()
}

func saveSettings() {
	settingsLock.Lock()
	err := saveSettingsLocked()
	settingsLock.Unlock()
	if err != nil {
		appLogger.Printf("Failed to save settings: %v", err)
		return
	}
	appLogger.Println("Settings saved successfully")
}
