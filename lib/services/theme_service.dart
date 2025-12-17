import '../models/app_theme_config.dart';

class ThemeService {
  static final List<AppThemeConfig> availableThemes = [
    AppThemeConfig(
      id: 'light',
      name: 'Default Light',
      isDark: false,
      colors: const ThemeColors(
        primary: '#F0F4F8',
        secondary: '#ffffde',
        background: '#FFFFFF',
        surface: '#F8F9FA', // Very light grey for nodes
        text: '#212121', // Darker text for better contrast
        line: '#212121',
      ),
      mermaid: const MermaidThemeConfig(
        baseTheme: 'default',
        variables: {
          'primaryColor': '#F8F9FA',
          'primaryTextColor': '#212121',
          'primaryBorderColor': '#212121',
          'lineColor': '#212121',
          'secondaryColor': '#ffffde',
          'tertiaryColor': '#ffffff',
          'mainBkg': '#FFFFFF',
        },
      ),
      d2: const D2ThemeConfig(themeId: 0),
    ),
    AppThemeConfig(
      id: 'oceanic',
      name: 'Oceanic',
      isDark: false,
      colors: const ThemeColors(
        primary: '#E0F7FA',
        secondary: '#B2EBF2',
        background: '#FFFFFF',
        surface: '#E0F7FA',
        text: '#006064',
        line: '#00838F',
      ),
      mermaid: const MermaidThemeConfig(
        baseTheme: 'base',
        variables: {
          'primaryColor': '#E0F7FA',
          'primaryTextColor': '#006064',
          'primaryBorderColor': '#00BCD4',
          'lineColor': '#00838F',
          'secondaryColor': '#B2EBF2',
          'tertiaryColor': '#FFFFFF',
          'mainBkg': '#FFFFFF',
        },
      ),
      d2: const D2ThemeConfig(themeId: 1),
    ),
    AppThemeConfig(
      id: 'forest',
      name: 'Forest',
      isDark: false,
      colors: const ThemeColors(
        primary: '#E8F5E9',
        secondary: '#C8E6C9',
        background: '#FFFFFF',
        surface: '#E8F5E9',
        text: '#1B5E20',
        line: '#2E7D32',
      ),
      mermaid: const MermaidThemeConfig(
        baseTheme: 'forest',
        variables: {
          'lineColor': '#2E7D32',
        },
      ),
      d2: const D2ThemeConfig(themeId: 4),
    ),
    AppThemeConfig(
      id: 'dark',
      name: 'Dark Mode',
      isDark: true,
      colors: const ThemeColors(
        primary: '#2C2C2C',
        secondary: '#424242',
        background: '#121212', // Deep dark background
        surface: '#2C2C2C', // Lighter node background
        text: '#FFFFFF',    // High contrast text
        line: '#FFFFFF',    // High contrast lines
      ),
      mermaid: const MermaidThemeConfig(
        baseTheme: 'dark',
        variables: {
          'primaryColor': '#2C2C2C',
          'primaryTextColor': '#FFFFFF',
          'primaryBorderColor': '#FFFFFF',
          'lineColor': '#FFFFFF',
          'secondaryColor': '#424242',
          'tertiaryColor': '#1E1E1E',
          'mainBkg': '#121212',
          'nodeBorder': '#FFFFFF',
          'clusterBkg': '#1E1E1E',
          'clusterBorder': '#FFFFFF',
          'titleColor': '#FFFFFF',
          'edgeLabelBackground': '#121212',
        },
      ),
      d2: const D2ThemeConfig(themeId: 200),
    ),
  ];

  static AppThemeConfig get defaultTheme => availableThemes.first;
}