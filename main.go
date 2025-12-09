package main

import (
	"adome/internal/app"
	"adome/internal/config"
	"adome/internal/d2"
	"adome/internal/files"
	"embed"
	"os"

	"github.com/wailsapp/wails/v2"
	"github.com/wailsapp/wails/v2/pkg/options"
	"github.com/wailsapp/wails/v2/pkg/options/assetserver"
	"github.com/wailsapp/wails/v2/pkg/options/linux"
)

//go:embed all:frontend/dist
var assets embed.FS

func main() {
	// LINUX COMPATIBILITY FIXES
	// -------------------------
	// 1. Disable Accessibility Bridge: Fixes freezes/crashes when interacting with inputs.
	os.Setenv("NO_AT_BRIDGE", "1")
	// 2. Force X11: More stable on Hybrid GPUs (Nouveau/AMD) than Wayland.
	os.Setenv("GDK_BACKEND", "x11")
	// 3. Disable DMABUF: Fixes rendering artifacts/crashes on NVIDIA.
	os.Setenv("WEBKIT_DISABLE_DMABUF_RENDERER", "1")
	// 4. Disable Compositing: Fallback to software rendering for maximum stability.
	os.Setenv("WEBKIT_DISABLE_COMPOSITING_MODE", "1")

	// Create services
	d2Service := d2.NewService()
	configService := config.NewService()
	filesService := files.NewService()

	// Create an instance of the app structure
	application := app.NewApp(d2Service, configService, filesService)

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
