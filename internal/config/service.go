package config

import (
	"context"
	"os"
	"path/filepath"
)

type Service struct {
	ctx       context.Context
	configDir string
}

func NewService() *Service {
	return &Service{}
}

func (s *Service) Startup(ctx context.Context) {
	s.ctx = ctx
	configDir, err := os.UserConfigDir()
	if err != nil {
		configDir = "."
	}
	s.configDir = filepath.Join(configDir, "DiagramEditor")
	_ = os.MkdirAll(s.configDir, 0755)
}

func (s *Service) SavePalettes(palettes string) error {
	path := filepath.Join(s.configDir, "user-palettes.json")
	return os.WriteFile(path, []byte(palettes), 0644)
}

func (s *Service) LoadPalettes() (string, error) {
	path := filepath.Join(s.configDir, "user-palettes.json")
	if _, err := os.Stat(path); os.IsNotExist(err) {
		return "[]", nil
	}
	content, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}
	return string(content), nil
}