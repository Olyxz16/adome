package app

import (
	"adome/internal/config"
	"adome/internal/d2"
	"adome/internal/files"
	"context"
	"os/exec"
	"strings"
)

// App struct
type App struct {
	ctx    context.Context
	d2     *d2.Service
	config *config.Service
	files  *files.Service
}

// NewApp creates a new App application struct
func NewApp(d2 *d2.Service, config *config.Service, files *files.Service) *App {
	return &App{
		d2:     d2,
		config: config,
		files:  files,
	}
}

// Startup is called when the app starts. The context is saved
// so we can call the runtime methods
func (a *App) Startup(ctx context.Context) {
	a.ctx = ctx
	a.d2.Startup(ctx)
	a.config.Startup(ctx)
	a.files.Startup(ctx)
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
