package main

import (
	"adome/internal/app"
	"adome/internal/config"
	"adome/internal/d2"
	"adome/internal/files"
	"embed"
	"os"
	"os/exec"

	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
	"github.com/wailsapp/wails/v2/pkg/options/linux"
)

//go:embed all:frontend/dist
var assets embed.FS

func main() {
	// Parse command line arguments manually to check for flags
	args := os.Args[1:]
	detach := false
	filePath := ""

	// Filter args
	filteredArgs := []string{}
	for _, arg := range args {
		if arg == "-d" {
			detach = true
		} else {
			filteredArgs = append(filteredArgs, arg)
			if filePath == "" && len(arg) > 0 && arg[0] != '-' {
				filePath = arg
			}
		}
	}

	// Detachment Logic
	if detach && os.Getenv("ADOME_DETACHED") != "1" {
		// Re-execute the binary without the -d flag but with ADOME_DETACHED env var
		// to indicate it's the child process.
		// Use os.Executable() to get the path to the current binary
		exePath, err := os.Executable()
		if err != nil {
			println("Failed to get executable path:", err.Error())
			os.Exit(1)
		}

		cmd := exec.Command(exePath, filteredArgs...)
		app.SetupDetachment(cmd)
		cmd.Env = append(os.Environ(), "ADOME_DETACHED=1")

		err = cmd.Start()
		if err != nil {
			println("Failed to detach process:", err.Error())
			os.Exit(1)
		}
		println("Application detached. PID:", cmd.Process.Pid)
		os.Exit(0)
	}

	// LINUX COMPATIBILITY FIXES
	// -------------------------
	// 1. Disable Accessibility Bridge: Fixes freezes/crashes when interacting with inputs.
	os.Setenv("NO_AT_BRIDGE", "1")
	// 2. Force X11: More stable on Hybrid GPUs (Nouveau/AMD) than Wayland.
	os.Setenv("GDK_BACKEND", "x11")
	// 3. Disable DMABUF: Fixes rendering artifacts/crashes on NVIDIA.
	// 4. Disable Compositing: Fallback to software rendering for maximum stability.
	os.Setenv("WEBKIT_DISABLE_COMPOSITING_MODE", "1")

	// Create services
	d2Service := d2.NewService()
	configService := config.NewService()
	filesService := files.NewService()

	// Create an instance of the app structure
	application := app.NewApp(d2Service, configService, filesService)

	// Set startup file path if found
	if filePath != "" {
		if _, err := os.Stat(filePath); err == nil {
			application.SetStartupFilePath(filePath)
		}
	}

	// Create application with options
	err := wails.Run(&options.App{
		Title:  "adome",
		Width:  1024,
		Height: 768,
		AssetServer: &assetserver.Options{
			Assets: assets,
		},
		OnStartup: application.Startup,
		Linux: &linux.Options{
			WebviewGpuPolicy: linux.WebviewGpuPolicyNever,
		},
		Bind: []interface{}{
			application,
			d2Service,
			configService,
			filesService,
		},
	})

	if err != nil {
		println("Error:", err.Error())
	}
}
