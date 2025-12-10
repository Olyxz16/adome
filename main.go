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
	// Check if we are already detached or running in dev mode
	// WAILS_FRONTEND_DEV is set by `wails dev` command
	if os.Getenv("ADOME_DETACHED") != "1" && os.Getenv("WAILS_FRONTEND_DEV") != "true" {
		cmd := exec.Command(os.Args[0], os.Args[1:]...)
		
		app.SetupDetachment(cmd) // Call the OS-specific function

		cmd.Env = append(os.Environ(), "ADOME_DETACHED=1") // Prevent infinite loop

		err := cmd.Start()
		if err != nil {
			println("Failed to detach process:", err.Error())
			os.Exit(1)
		}
		println("Adome started.")
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

	// Process command-line arguments for file path
	if len(os.Args) > 1 {
		filePath := os.Args[1]
		// You might want to add more robust validation here,
		// e.g., check if the file exists and is a regular file.
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
