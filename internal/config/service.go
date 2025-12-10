package config

import (
	"context"
	"encoding/json" // Import json package
	"os"
	"path/filepath"
)

const preferencesFileName = "preferences.json"

// Preferences struct to hold application settings
type Preferences struct {
	ActiveThemeName string `json:"activeThemeName"`
	// Add other preferences here as needed
}

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

// LoadPreferences reads application preferences from a JSON file.
func (s *Service) LoadPreferences() (Preferences, error) {
	path := filepath.Join(s.configDir, preferencesFileName)
	prefs := Preferences{
		ActiveThemeName: "", // Default active theme name
	}

	if _, err := os.Stat(path); os.IsNotExist(err) {
		// File does not exist, return default preferences
		return prefs, nil
	}

	content, err := os.ReadFile(path)
	if err != nil {
		return prefs, err
	}

	err = json.Unmarshal(content, &prefs)
	if err != nil {
		return prefs, err
	}

	return prefs, nil
}

// SavePreferences writes application preferences to a JSON file.
func (s *Service) SavePreferences(prefs Preferences) error {
	path := filepath.Join(s.configDir, preferencesFileName)
	content, err := json.MarshalIndent(prefs, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(path, content, 0644)
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