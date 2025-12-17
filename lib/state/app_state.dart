import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/d2_service.dart';
import '../services/mermaid_service.dart';
import '../services/file_service.dart';
import '../services/theme_service.dart';
import '../models/app_theme_config.dart';

enum RenderingEngine { d2, mermaid }

class AppState extends ChangeNotifier {
  final D2Service _d2Service = D2Service();
  final MermaidService _mermaidService = MermaidService();
  final FileService _fileService = FileService();

  RenderingEngine _engine = RenderingEngine.mermaid;
  RenderingEngine get engine => _engine;

  String _d2Content = 'x -> y';
  String _mermaidContent = '''graph TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]
''';

  String get currentContent => _engine == RenderingEngine.d2 ? _d2Content : _mermaidContent;

  String _compiledD2Svg = '';
  String get compiledD2Svg => _compiledD2Svg;

  String _compiledMermaidSvg = '';
  String get compiledMermaidSvg => _compiledMermaidSvg;

  String? _currentFilePath;
  String? get currentFilePath => _currentFilePath;

  bool _isCompiling = false;
  bool get isCompiling => _isCompiling;

  // Ribbon State
  bool _autoRender = true;
  bool get autoRender => _autoRender;

  String _mermaidLayout = 'default';
  String get mermaidLayout => _mermaidLayout;

  String _mermaidElkAlgorithm = 'layered';
  String get mermaidElkAlgorithm => _mermaidElkAlgorithm;

  // Theme State
  AppThemeConfig _activeThemeConfig = ThemeService.defaultTheme;
  AppThemeConfig get activeThemeConfig => _activeThemeConfig;
  
  // This controls the overall App UI mode (Light/Dark/System)
  // We can optionally sync this with the diagram theme or keep it separate.
  // For now, we'll keep it separate but default to system.
  ThemeMode _appThemeMode = ThemeMode.system;
  ThemeMode get appThemeMode => _appThemeMode;

  Timer? _debounce;

  AppState() {
    _compile(); // Initial compile
  }

  // Setters
  void setAutoRender(bool value) {
    _autoRender = value;
    notifyListeners();
    if (_autoRender) _compile();
  }

  void setMermaidLayout(String value) {
    _mermaidLayout = value;
    notifyListeners();
    if (_autoRender) _compile();
  }

  void setMermaidElkAlgorithm(String value) {
    _mermaidElkAlgorithm = value;
    notifyListeners();
    if (_autoRender) _compile();
  }

  void setAppThemeMode(ThemeMode mode) {
    _appThemeMode = mode;
    notifyListeners();
  }

  void setDiagramTheme(AppThemeConfig theme) {
    _activeThemeConfig = theme;
    notifyListeners();
    if (_autoRender) _compile();
  }

  void setEngine(RenderingEngine engine) {
    if (_engine != engine) {
      _engine = engine;
      notifyListeners();
      _compile();
    }
  }

  void updateContent(String content) {
    if (_engine == RenderingEngine.d2) {
      _d2Content = content;
    } else {
      _mermaidContent = content;
    }
    if (_autoRender) {
      _debounceCompile();
    }
  }

  void manualRender() {
    _compile();
  }

  void _debounceCompile() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _compile);
  }

  Future<void> _compile() async {
    print('AppState: _compile called. Engine: $_engine');
    _isCompiling = true;
    notifyListeners();
    
    try {
      if (_engine == RenderingEngine.d2) {
        _compiledD2Svg = await _d2Service.compile(
          _d2Content, 
          themeId: _activeThemeConfig.d2.themeId
        );
        print('AppState: D2 compiled. SVG length: ${_compiledD2Svg.length}');
      } else {
        _compiledMermaidSvg = await _mermaidService.compile(
          _mermaidContent, 
          config: _activeThemeConfig,
          layout: _mermaidLayout,
          elkAlgorithm: _mermaidElkAlgorithm
        );
        print('AppState: Mermaid compiled. SVG length: ${_compiledMermaidSvg.length}');
      }
    } catch (e) {
      print('AppState: Compilation error: $e');
    } finally {
      _isCompiling = false;
      notifyListeners();
    }
  }

  Future<void> openFile() async {
    final path = await _fileService.openFilePath();
    if (path != null) {
      final content = await File(path).readAsString();
      _currentFilePath = path;
      if (path.endsWith('.d2')) {
        _engine = RenderingEngine.d2;
        _d2Content = content;
      } else {
        _engine = RenderingEngine.mermaid;
        _mermaidContent = content;
      }
      notifyListeners();
      _compile();
    }
  }

  Future<void> saveFile() async {
    if (_currentFilePath != null) {
      await _fileService.saveFile(currentContent, _currentFilePath);
    } else {
      await saveFileAs();
    }
  }

  Future<void> saveFileAs() async {
    String suggestedFileName;
    if (_engine == RenderingEngine.d2) {
      suggestedFileName = 'diagram.d2';
    } else {
      suggestedFileName = 'diagram.mmd';
    }
    final path = await _fileService.saveFileAs(currentContent, suggestedFileName: suggestedFileName);
    if (path != null) {
      _currentFilePath = path;
      notifyListeners();
    }
  }
  
  Future<void> exportSvg() async {
    String content = _engine == RenderingEngine.d2 ? _compiledD2Svg : _compiledMermaidSvg;
    if (content.isEmpty) return;
    
    // Use FileService to save with .svg extension
    await _fileService.saveFileAs(content, suggestedFileName: 'diagram.svg'); 
  }
}