package files

import (
	"context"
	"os"
	"path/filepath"
	"testing"
)

func TestLoadFileByPath(t *testing.T) {
	service := NewService()
	service.Startup(context.Background()) // Initialize context

	// Create a temporary file for testing
	tempFileContent := "test content for LoadFileByPath"
	tempFilePath := filepath.Join(os.TempDir(), "testfile.mmd")
	err := os.WriteFile(tempFilePath, []byte(tempFileContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create temporary file: %v", err)
	}
	defer os.Remove(tempFilePath) // Clean up the temporary file

	// Test case 1: Load an existing file
	content, err := service.LoadFileByPath(tempFilePath)
	if err != nil {
		t.Errorf("LoadFileByPath failed for existing file: %v", err)
	}
	if content != tempFileContent {
		t.Errorf("Expected content '%s', got '%s'", tempFileContent, content)
	}

	// Test case 2: Load a non-existent file
	nonExistentPath := filepath.Join(os.TempDir(), "nonexistent.mmd")
	_, err = service.LoadFileByPath(nonExistentPath)
	if err == nil {
		t.Errorf("LoadFileByPath expected an error for non-existent file, got none")
	}
}

// Add more tests for LoadFile, SaveFile, ExportSVG, ExportPNG if desired,
// by mocking wails runtime functions. For now, focusing on LoadFileByPath.
