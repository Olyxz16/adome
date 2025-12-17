class AppThemeConfig {
  final String id;
  final String name;
  final bool isDark;
  final ThemeColors colors;
  final MermaidThemeConfig mermaid;
  final D2ThemeConfig d2;

  const AppThemeConfig({
    required this.id,
    required this.name,
    required this.isDark,
    required this.colors,
    required this.mermaid,
    required this.d2,
  });

  factory AppThemeConfig.fromJson(Map<String, dynamic> json) {
    return AppThemeConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      isDark: json['isDark'] as bool? ?? false,
      colors: ThemeColors.fromJson(json['colors'] as Map<String, dynamic>),
      mermaid: MermaidThemeConfig.fromJson(json['mermaid'] as Map<String, dynamic>),
      d2: D2ThemeConfig.fromJson(json['d2'] as Map<String, dynamic>),
    );
  }
}

class ThemeColors {
  final String primary;
  final String secondary;
  final String background;
  final String surface;
  final String text;
  final String line;

  const ThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.text,
    required this.line,
  });

  factory ThemeColors.fromJson(Map<String, dynamic> json) {
    return ThemeColors(
      primary: json['primary'] as String,
      secondary: json['secondary'] as String,
      background: json['background'] as String,
      surface: json['surface'] as String,
      text: json['text'] as String,
      line: json['line'] as String,
    );
  }
}

class MermaidThemeConfig {
  final String baseTheme;
  final Map<String, String> variables;

  const MermaidThemeConfig({
    required this.baseTheme,
    required this.variables,
  });

  factory MermaidThemeConfig.fromJson(Map<String, dynamic> json) {
    return MermaidThemeConfig(
      baseTheme: json['theme'] as String,
      variables: Map<String, String>.from(json['variables'] as Map),
    );
  }
}

class D2ThemeConfig {
  final int themeId;

  const D2ThemeConfig({required this.themeId});

  factory D2ThemeConfig.fromJson(Map<String, dynamic> json) {
    return D2ThemeConfig(
      themeId: json['themeId'] as int,
    );
  }
}
