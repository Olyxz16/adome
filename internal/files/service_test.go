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

func TestGetFileOptions(t *testing.T) {
	service := NewService()

	tests := []struct {
		name             string
		engine           string
		expectedFilename string
		expectedFilters  string // Just checking the pattern of the first filter for simplicity
	}{
		{"Mermaid", "mermaid", "diagram.mmd", "*.mmd;*.mermaid"},
		{"D2", "d2", "diagram.d2", "*.d2"},
		{"Unknown", "unknown", "diagram.txt", "*.txt"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			filename, filters := service.getFileOptions(tt.engine)

			if filename != tt.expectedFilename {
				t.Errorf("expected filename %s, got %s", tt.expectedFilename, filename)
			}

			if len(filters) == 0 {
				t.Fatal("expected filters, got empty list")
			}

			if filters[0].Pattern != tt.expectedFilters {
				t.Errorf("expected filter pattern %s, got %s", tt.expectedFilters, filters[0].Pattern)
			}
		})
	}
}