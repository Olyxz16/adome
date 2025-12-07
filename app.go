package main

import (
	"context"
	"encoding/base64"
	"os"
	"os/exec"
	"strings"

	"github.com/wailsapp/wails/v2/pkg/runtime"
)

// App struct
type App struct {
	ctx context.Context
}

// NewApp creates a new App application struct
func NewApp() *App {
	return &App{}
}

// startup is called when the app starts. The context is saved
// so we can call the runtime methods
func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
}

// IsDarkTheme checks if the system is using a dark theme (Linux/GNOME support)
func (a *App) IsDarkTheme() bool {
	// Check standard GTK3/GNOME setting
	cmd := exec.Command("gsettings", "get", "org.gnome.desktop.interface", "color-scheme")
	out, err := cmd.Output()
	if err == nil {
		s := strings.ToLower(strings.TrimSpace(string(out)))
		// usually returns 'prefer-dark' or 'default'
		if strings.Contains(s, "dark") {
			return true
		}
	}
	return false
}

// SaveMermaid saves the mermaid content to a file
func (a *App) SaveMermaid(content string) (string, error) {
	path, err := runtime.SaveFileDialog(a.ctx, runtime.SaveDialogOptions{
		Title:           "Save Mermaid Diagram",
		DefaultFilename: "diagram.mmd",
		Filters: []runtime.FileFilter{
			{DisplayName: "Mermaid Files", Pattern: "*.mmd;*.mermaid"},
		},
	})
	if err != nil {
		return "", err
	}
	if path == "" {
		return "Cancelled", nil
	}

	err = os.WriteFile(path, []byte(content), 0644)
	if err != nil {
		return "", err
	}
	return "Saved to " + path, nil
}

// ExportSVG saves the mermaid diagram as SVG
func (a *App) ExportSVG(content string) (string, error) {
	path, err := runtime.SaveFileDialog(a.ctx, runtime.SaveDialogOptions{
		Title:           "Export SVG",
		DefaultFilename: "diagram.svg",
		Filters: []runtime.FileFilter{
			{DisplayName: "SVG Files", Pattern: "*.svg"},
		},
	})
	if err != nil {
		return "", err
	}
	if path == "" {
		return "Cancelled", nil
	}

	err = os.WriteFile(path, []byte(content), 0644)
	if err != nil {
		return "", err
	}
	return "Exported to " + path, nil
}

// ExportPNG saves the mermaid diagram as PNG
func (a *App) ExportPNG(base64Data string) (string, error) {
	path, err := runtime.SaveFileDialog(a.ctx, runtime.SaveDialogOptions{
		Title:           "Export PNG",
		DefaultFilename: "diagram.png",
		Filters: []runtime.FileFilter{
			{DisplayName: "PNG Files", Pattern: "*.png"},
		},
	})
	if err != nil {
		return "", err
	}
	if path == "" {
		return "Cancelled", nil
	}

	data, err := base64.StdEncoding.DecodeString(base64Data)
	if err != nil {
		return "", err
	}

	err = os.WriteFile(path, data, 0644)
	if err != nil {
		return "", err
	}
	return "Exported to " + path, nil
}

// LoadMermaid loads a mermaid file
func (a *App) LoadMermaid() (string, error) {
	path, err := runtime.OpenFileDialog(a.ctx, runtime.OpenDialogOptions{
		Title: "Open Mermaid Diagram",
		Filters: []runtime.FileFilter{
			{DisplayName: "Mermaid Files", Pattern: "*.mmd;*.mermaid"},
		},
	})
	if err != nil {
		return "", err
	}
	if path == "" {
		return "", nil
	}

	content, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(content), nil
}
