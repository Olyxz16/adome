package app

import (
	"testing"
)

func TestStartupFilePath(t *testing.T) {
	app := NewApp(nil, nil, nil) // Dependencies are not needed for this test

	expectedPath := "/path/to/my/diagram.mmd"

	// Initially empty
	if app.GetStartupFilePath() != "" {
		t.Errorf("Expected empty startup path, got %s", app.GetStartupFilePath())
	}

	// Set path
	app.SetStartupFilePath(expectedPath)

	// Get path
	if app.GetStartupFilePath() != expectedPath {
		t.Errorf("Expected startup path %s, got %s", expectedPath, app.GetStartupFilePath())
	}
}
