package monitor

import (
	"fmt"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/getlantern/systray"
	"github.com/ncruces/zenity"
)

var (
	lastStatus         = ""
	mStatusPlaceholder *systray.MenuItem
	mModelSlots        []*systray.MenuItem
	stopCh             chan struct{}
	stopOnce           sync.Once
)

func changeAPIURL() {
	settingsLock.Lock()
	currentAPIURL := settings.APIURL
	settingsLock.Unlock()

	newURL, err := zenity.Entry(
		"Enter Ollama API URL:",
		zenity.Title("Change API URL"),
		zenity.EntryText(currentAPIURL),
	)
	if err != nil {
		return
	}

	cleanedURL, parsedURL, err := validateAPIURL(newURL)
	if err != nil {
		_ = zenity.Error(
			"Invalid API URL format. It must start with http:// or https://",
			zenity.Title("Error"),
		)
		return
	}

	settingsLock.Lock()
	settings.APIURL = cleanedURL
	settingsLock.Unlock()

	saveSettings()

	sendNotification("Settings Saved", fmt.Sprintf("Ollama API URL updated to: %s", parsedURL.Redacted()))
}

func showAbout() {
	_ = zenity.Info(
		fmt.Sprintf("Ollama Monitor v%s\n\nCreated by %s\n\nA lightweight system tray tool to monitor Ollama AI models with real-time status updates.", Version, Author),
		zenity.Title("About Ollama Monitor"),
	)
}

func updateStatusLoop() {
	interval := 2 * time.Second
	for {
		state, models := getRunningModels()

		switch state {
		case StateOffline:
			systray.SetIcon(iconRed)
			systray.SetTooltip("Ollama Service: Offline")
			mStatusPlaceholder.SetTitle("Ollama Not Running")
			mStatusPlaceholder.Show()

			for _, m := range mModelSlots {
				m.Hide()
			}
			interval = 10 * time.Second

		case StateIdle:
			systray.SetIcon(iconBlue)
			systray.SetTooltip("Ollama Service: Idle")
			mStatusPlaceholder.SetTitle("No Model Running")
			mStatusPlaceholder.Show()

			for _, m := range mModelSlots {
				m.Hide()
			}
			interval = 10 * time.Second

		case StateActive:
			systray.SetIcon(iconGreen)

			status := strings.Join(models, ", ")
			tooltip := fmt.Sprintf("Models: %s", status)
			if len(tooltip) > 127 {
				tooltip = tooltip[:124] + "..."
			}
			systray.SetTooltip(tooltip)

			mStatusPlaceholder.Hide()

			overflow := len(models) > len(mModelSlots)
			limit := len(mModelSlots)
			if overflow {
				limit--
			}
			for i := 0; i < len(mModelSlots); i++ {
				if i < limit && i < len(models) {
					mModelSlots[i].SetTitle(models[i])
					mModelSlots[i].Show()
				} else if overflow && i == len(mModelSlots)-1 {
					mModelSlots[i].SetTitle(fmt.Sprintf("+%d more", len(models)-limit))
					mModelSlots[i].Show()
				} else {
					mModelSlots[i].Hide()
				}
			}
			interval = 3 * time.Second
		}

		select {
		case <-stopCh:
			return
		case <-time.After(interval):
		}
	}
}

func onReady() {
	stopCh = make(chan struct{})
	stopOnce = sync.Once{}

	systray.SetIcon(iconBlue)
	systray.SetTitle("Ollama Monitor")
	systray.SetTooltip("Ollama Monitor - Loading...")

	mStatusPlaceholder = systray.AddMenuItem("Waiting...", "")
	mStatusPlaceholder.Disable()

	for i := 0; i < 5; i++ {
		m := systray.AddMenuItem("", "")
		m.Disable()
		m.Hide()
		mModelSlots = append(mModelSlots, m)
	}
	
	systray.AddSeparator()
	
	var mStartup *systray.MenuItem
	var startupCh chan struct{}
	if runtime.GOOS == "windows" {
		mStartup = systray.AddMenuItem("Run at Startup", "")
		settingsLock.Lock()
		isStartup := settings.Startup
		settingsLock.Unlock()
		if isStartup {
			mStartup.Check()
		} else {
			mStartup.Uncheck()
		}
		startupCh = mStartup.ClickedCh
	}

	mAPI := systray.AddMenuItem("Change API URL...", "")
	mAbout := systray.AddMenuItem("About...", "")

	systray.AddSeparator()
	mExit := systray.AddMenuItem("Exit", "")

	// Start status updater loop
	go updateStatusLoop()

	// Wait for actions
	go func() {
		for {
			select {
			case <-stopCh:
				return

			case <-startupCh:
				settingsLock.Lock()
				want := !settings.Startup
				settingsLock.Unlock()

				if err := toggleStartup(want); err != nil {
					appLogger.Printf("Failed to configure startup (%v): %v", want, err)
					if want {
						_ = zenity.Error(fmt.Sprintf("Failed to configure Windows startup: %v", err), zenity.Title("Error"))
					}
					continue
				}

				settingsLock.Lock()
				settings.Startup = want
				settingsLock.Unlock()
				saveSettings()
				if want {
					mStartup.Check()
				} else {
					mStartup.Uncheck()
				}

			case <-mAPI.ClickedCh:
				appLogger.Println("Change API URL clicked")
				go changeAPIURL()

			case <-mAbout.ClickedCh:
				appLogger.Println("About clicked")
				go showAbout()

			case <-mExit.ClickedCh:
				appLogger.Println("Exit clicked, shutting down")
				systray.Quit()
			}
		}
	}()
}

func onExit() {
	if stopCh != nil {
		stopOnce.Do(func() { close(stopCh) })
	}
	appLogger.Println("Ollama Monitor stopped")
	if rotatedWriter != nil {
		_ = rotatedWriter.Close()
	}
}

func Run() {
	setupLogging()
	loadSettings()
	initHTTPClient()
	registerAUMID()
	initIcons()

	systray.Run(onReady, onExit)
}
