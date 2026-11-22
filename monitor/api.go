package monitor

import (
	"crypto/tls"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"slices"
	"strings"
	"time"
)

// States
const (
	StateOffline = iota
	StateIdle
	StateActive
)

// Ollama API response structures
type ModelDetails struct {
	ParameterSize string `json:"parameter_size"`
}

type ModelInfo struct {
	Name    string       `json:"name"`
	Details ModelDetails `json:"details"`
}

type PSResponse struct {
	Models []ModelInfo `json:"models"`
}

var (
	client            *http.Client
	lastRunningModels []string
	notifyFn          = sendNotification
)

func initHTTPClient() {
	settingsLock.Lock()
	insecureTLS := settings.InsecureTLS
	settingsLock.Unlock()

	tr := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
	}
	if insecureTLS {
		tr.TLSClientConfig = &tls.Config{
			InsecureSkipVerify: true, // Opt-in TLS bypass for proxies and self-signed certs
		}
	}
	client = &http.Client{
		Transport: tr,
		Timeout:   2 * time.Second,
	}
}

func validateAPIURL(raw string) (string, *url.URL, error) {
	cleaned := strings.TrimRight(strings.TrimSpace(raw), "/")
	u, err := url.Parse(cleaned)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
		return "", nil, errors.New("invalid API URL: must start with http:// or https://")
	}
	return cleaned, u, nil
}

func notifyModelChanges(currentModels []string) {
	// If it's the first run, populate lastRunningModels but don't notify to avoid startup spam
	if lastStatus == "" {
		lastRunningModels = currentModels
		lastStatus = strings.Join(currentModels, ", ")
		return
	}

	var started []string
	for _, m := range currentModels {
		if !slices.Contains(lastRunningModels, m) {
			started = append(started, m)
		}
	}

	var stopped []string
	for _, m := range lastRunningModels {
		if !slices.Contains(currentModels, m) {
			stopped = append(stopped, m)
		}
	}

	if len(started) > 0 {
		notifyFn("Model Started", strings.Join(started, ", "))
	}
	if len(stopped) > 0 {
		notifyFn("Model Stopped", strings.Join(stopped, ", "))
	}

	lastRunningModels = currentModels
	lastStatus = strings.Join(currentModels, ", ")
}

func markOffline(logMsg string) {
	if lastStatus == "Ollama Not Running" {
		return
	}
	appLogger.Print(logMsg)
	if lastStatus != "" {
		notifyFn("Ollama Service Stopped", "Could not connect to Ollama")
	}
	lastStatus = "Ollama Not Running"
	lastRunningModels = nil
}

func getRunningModels() (int, []string) {
	settingsLock.Lock()
	apiURL := settings.APIURL
	settingsLock.Unlock()

	cleanedURL, parsedURL, err := validateAPIURL(apiURL)
	if err != nil {
		markOffline(fmt.Sprintf("Invalid API URL: %v", err))
		return StateOffline, nil
	}

	endpoint := fmt.Sprintf("%s/api/ps", cleanedURL)
	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		markOffline(fmt.Sprintf("Failed to create request: %v", err))
		return StateOffline, nil
	}

	// Support basic authentication if username/password is present in the URL
	if parsedURL.User != nil {
		password, _ := parsedURL.User.Password()
		req.SetBasicAuth(parsedURL.User.Username(), password)
	}

	resp, err := client.Do(req)
	if err != nil {
		markOffline(fmt.Sprintf("Connection error: %v", err))
		return StateOffline, nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		markOffline(fmt.Sprintf("API returned status code: %d", resp.StatusCode))
		return StateOffline, nil
	}

	var psResp PSResponse
	if err := json.NewDecoder(resp.Body).Decode(&psResp); err != nil {
		markOffline(fmt.Sprintf("Failed to decode response: %v", err))
		return StateOffline, nil
	}

	if len(psResp.Models) > 0 {
		var models []string
		for _, m := range psResp.Models {
			if m.Details.ParameterSize != "" {
				models = append(models, fmt.Sprintf("%s (%s)", m.Name, m.Details.ParameterSize))
			} else {
				models = append(models, m.Name)
			}
		}

		notifyModelChanges(models)
		return StateActive, models
	}

	if lastStatus != "No Model Running" {
		appLogger.Println("No model running")
		notifyModelChanges(nil)
		lastStatus = "No Model Running"
	}
	return StateIdle, nil
}
