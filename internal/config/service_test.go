package config

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestSaveLoadPreferences(t *testing.T) {
	// Create a temporary config directory for testing
	tempDir, err := os.MkdirTemp("", "config_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir) // Clean up after test

	service := NewService()
	service.configDir = filepath.Join(tempDir, "DiagramEditor")
	_ = os.MkdirAll(service.configDir, 0755)

	// Test case 1: Save and load a preference
	testPrefs := Preferences{
		ActiveThemeName: "oceanic",
	}

	err = service.SavePreferences(testPrefs)
	if err != nil {
		t.Fatalf("SavePreferences failed: %v", err)
	}

	loadedPrefs, err := service.LoadPreferences()
	if err != nil {
		t.Fatalf("LoadPreferences failed: %v", err)
	}

	if loadedPrefs.ActiveThemeName != testPrefs.ActiveThemeName {
		t.Errorf("Expected ActiveThemeName %s, got %s", testPrefs.ActiveThemeName, loadedPrefs.ActiveThemeName)
	}

	// Test case 2: Load non-existent preferences (should return defaults)
	// Remove the preferences file
	err = os.Remove(filepath.Join(service.configDir, preferencesFileName))
	if err != nil {
		t.Fatalf("Failed to remove preferences file: %v", err)
	}

	loadedPrefs, err = service.LoadPreferences()
	if err != nil {
		t.Fatalf("LoadPreferences failed for non-existent file: %v", err)
	}

	if loadedPrefs.ActiveThemeName != "" {
		t.Errorf("Expected default ActiveThemeName '', got %s", loadedPrefs.ActiveThemeName)
	}
}

func TestSaveLoadPalettes(t *testing.T) {
	// Create a temporary config directory for testing
	tempDir, err := os.MkdirTemp("", "palette_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir) // Clean up after test

	service := NewService()
	service.configDir = filepath.Join(tempDir, "DiagramEditor")
	_ = os.MkdirAll(service.configDir, 0755)

	testPalettes := `[{"name":"Custom1","isDark":false}]`

	err = service.SavePalettes(testPalettes)
	if err != nil {
		t.Fatalf("SavePalettes failed: %v", err)
	}

	loadedPalettes, err := service.LoadPalettes()
	if err != nil {
		t.Fatalf("LoadPalettes failed: %v", err)
	}

	if loadedPalettes != testPalettes {
		t.Errorf("Expected palettes %s, got %s", testPalettes, loadedPalettes)
	}

	// Test case 2: Load non-existent palettes (should return "[]")
	// Remove the palettes file
	err = os.Remove(filepath.Join(service.configDir, "user-palettes.json"))
	if err != nil {
		t.Fatalf("Failed to remove palettes file: %v", err)
	}

	loadedPalettes, err = service.LoadPalettes()
	if err != nil {
		t.Fatalf("LoadPalettes failed for non-existent file: %v", err)
	}

	if loadedPalettes != "[]" {
		t.Errorf("Expected default palettes \"[]\", got %s", loadedPalettes)
	}
}

func TestStartup(t *testing.T) {
	service := NewService()
	service.Startup(context.Background())

	if service.configDir == "" {
		t.Errorf("configDir should not be empty after Startup")
	}

	// Verify that the directory was created
	info, err := os.Stat(service.configDir)
	if err != nil {
		t.Fatalf("Config directory %s not found: %v", service.configDir, err)
	}
	if !info.IsDir() {
		t.Errorf("Config directory %s is not a directory", service.configDir)
	}
}