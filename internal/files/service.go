package files

import (
	"context"
	"encoding/base64"
	"os"

	"github.com/wailsapp/wails/v2/pkg/runtime"
)

type Service struct {
	ctx context.Context
}

func NewService() *Service {
	return &Service{}
}

func (s *Service) Startup(ctx context.Context) {
	s.ctx = ctx
}

func (s *Service) LoadFileByPath(filePath string) (string, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return "", err
	}
	return string(content), nil
}

func (s *Service) LoadFile() (string, error) {
	path, err := runtime.OpenFileDialog(s.ctx, runtime.OpenDialogOptions{
		Title: "Open Diagram",
		Filters: []runtime.FileFilter{
			{DisplayName: "Diagram Files", Pattern: "*.mmd;*.mermaid;*.d2"},
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

func (s *Service) SaveFile(content string, engine string) (string, error) {
	println("Go Backend: SaveFile received engine:", engine)
	defaultFilename := "diagram"
	filters := []runtime.FileFilter{}

	switch engine {
	case "mermaid":
		defaultFilename += ".mmd"
		filters = []runtime.FileFilter{
			{DisplayName: "Mermaid Files (*.mmd, *.mermaid)", Pattern: "*.mmd;*.mermaid"},
			{DisplayName: "All Files (*.*)", Pattern: "*.*"},
		}
	case "d2":
		defaultFilename += ".d2"
		filters = []runtime.FileFilter{
			{DisplayName: "D2 Files (*.d2)", Pattern: "*.d2"},
			{DisplayName: "All Files (*.*)", Pattern: "*.*"},
		}
	default: // Fallback for unknown engine
		defaultFilename += ".txt"
		filters = []runtime.FileFilter{
			{DisplayName: "Text Files (*.txt)", Pattern: "*.txt"},
			{DisplayName: "All Files (*.*)", Pattern: "*.*"},
		}
	}

	path, err := runtime.SaveFileDialog(s.ctx, runtime.SaveDialogOptions{
		Title:           "Save Diagram",
		DefaultFilename: defaultFilename,
		Filters:         filters,
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

func (s *Service) ExportSVG(content string) (string, error) {
	path, err := runtime.SaveFileDialog(s.ctx, runtime.SaveDialogOptions{
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

func (s *Service) ExportPNG(base64Data string) (string, error) {
	path, err := runtime.SaveFileDialog(s.ctx, runtime.SaveDialogOptions{
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
