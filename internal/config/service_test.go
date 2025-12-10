package config

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestService_SaveAndLoadPalettes(t *testing.T) {
	// Create a temporary directory for config
	tmpDir, err := os.MkdirTemp("", "adome-config-test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Mock UserConfigDir via environment variable
	// Note: This works on Linux/Unix if os.UserConfigDir respects XDG_CONFIG_HOME.
	// For cross-platform reliability, we might need a different approach,
	// but for this environment it should suffice.
	t.Setenv("XDG_CONFIG_HOME", tmpDir)
    // Also set APPDATA for Windows just in case logic changes or test runs there
    t.Setenv("APPDATA", tmpDir)

	svc := NewService()
	svc.Startup(context.Background())

	// Verify the directory was created
	expectedDir := filepath.Join(tmpDir, "DiagramEditor")
	if _, err := os.Stat(expectedDir); os.IsNotExist(err) {
		t.Errorf("Config directory was not created at %s", expectedDir)
	}

	// Test LoadPalettes when file doesn't exist
	initialPalettes, err := svc.LoadPalettes()
	if err != nil {
		t.Errorf("LoadPalettes failed on empty: %v", err)
	}
	if initialPalettes != "[]" {
		t.Errorf("Expected '[]', got '%s'", initialPalettes)
	}

	// Test SavePalettes
	testData := `[{"name":"test"}]`
	err = svc.SavePalettes(testData)
	if err != nil {
		t.Errorf("SavePalettes failed: %v", err)
	}

	// Test LoadPalettes again
	loadedPalettes, err := svc.LoadPalettes()
	if err != nil {
		t.Errorf("LoadPalettes failed after save: %v", err)
	}
	if loadedPalettes != testData {
		t.Errorf("Expected '%s', got '%s'", testData, loadedPalettes)
	}
}
