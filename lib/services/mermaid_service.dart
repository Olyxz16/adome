import 'package:flutter/foundation.dart';
import '../models/app_theme_config.dart';
import 'webview_service.dart'; // Import the new WebviewService

class MermaidService {
  final WebviewService _webviewService = WebviewService(); // Instantiate WebviewService

  Future<String> compile(String content, {
    required AppThemeConfig config,
    String layout = 'default',
    String elkAlgorithm = 'layered',
  }) async {
    // Initialize the webview service if it hasn't been yet.
    if (!_webviewService.isInitialized) {
      await _webviewService.initialize();
    }
    return await _compileWithWebview(content, config: config, layout: layout, elkAlgorithm: elkAlgorithm);
  }

  Future<String> _compileWithWebview(String content, {
    required AppThemeConfig config,
    required String layout,
    required String elkAlgorithm,
  }) async {
    final Map<String, dynamic> mermaidConfig = {
      'theme': config.mermaid.baseTheme,
      'themeVariables': config.mermaid.variables,
      'flowchart': {
        'htmlLabels': false,
        'defaultRenderer': layout == 'elk' ? 'elk' : 'dagre',
      },
      'sequence': {'useMaxWidth': false},
      'securityLevel': 'loose',
    };

    if (layout == 'elk') {
      mermaidConfig['elk'] = {
        'algorithm': elkAlgorithm,
      };
    }

    final svg = await _webviewService.renderMermaid(content, mermaidConfig);
    debugPrint('Mermaid Raw SVG (first 500): ${svg.substring(0, svg.length > 500 ? 500 : svg.length)}');
    
    return _processSvg(svg, config.colors);
  }

  String _processSvg(String svg, ThemeColors colors) {
    debugPrint('MermaidService: Raw SVG contains "foreignObject": ${svg.contains('foreignObject')}');
    
    var processed = svg;

    // 1. Remove style blocks (Commented out to test if flutter_svg can handle them)
    // processed = processed.replaceAll(RegExp(r'<style[\s\S]*?<\/style>'), '');

    // Remove <switch> tags
    processed = processed.replaceAll(RegExp(r'<\/?switch[^>]*>'), '');

    // 2. Inject default styles for shapes (Rect, Polygon, Circle, Ellipse)
    final shapeStyle = ' fill="${colors.surface}" stroke="${colors.line}" stroke-width="2" ';
    final lineStyle = ' fill="none" stroke="${colors.line}" stroke-width="2" ';
    final markerStyle = ' fill="${colors.line}" stroke="none" ';
    final textStyle = ' fill="${colors.text}" font-family="sans-serif" ';

    processed = processed.replaceAll('<rect', '<rect$shapeStyle');
    processed = processed.replaceAll('<polygon', '<polygon$shapeStyle');
    processed = processed.replaceAll('<circle', '<circle$shapeStyle');
    processed = processed.replaceAll('<ellipse', '<ellipse$shapeStyle');
    
    // 3. Lines & Markers (Path)
    processed = processed.replaceAllMapped(RegExp(r'<path([^>]*)>'), (match) {
      final attrs = match.group(1) ?? '';
      if (attrs.contains('arrowMarkerPath')) {
        return '<path$markerStyle$attrs>';
      } else if (attrs.contains('flowchart-link') || attrs.contains('edge-pattern')) {
        return '<path$lineStyle$attrs>';
      }
      
      if (attrs.contains('fill="')) {
         if (attrs.contains('fill="none"')) {
           return match.group(0)!; 
         } else {
           final newAttrs = attrs.replaceAll(RegExp(r'fill="[^"]*"'), 'fill="${colors.surface}"');
           return '<path$newAttrs>';
         }
      }
      return '<path$lineStyle$attrs>';
    });

    // 4. Convert foreignObject to text
    final foreignObjectRegex = RegExp(r'<foreignObject([^>]*)>([\s\S]*?)<\/foreignObject>');
    
    processed = processed.replaceAllMapped(foreignObjectRegex, (match) {
      final attributes = match.group(1) ?? '';
      final content = match.group(2) ?? '';
      
      final xMatch = RegExp(r'x="([^"]*)"').firstMatch(attributes);
      final yMatch = RegExp(r'y="([^"]*)"').firstMatch(attributes);
      final widthMatch = RegExp(r'width="([^"]*)"').firstMatch(attributes);
      final heightMatch = RegExp(r'height="([^"]*)"').firstMatch(attributes);
      
      double x = double.tryParse(xMatch?.group(1) ?? '0') ?? 0;
      double y = double.tryParse(yMatch?.group(1) ?? '0') ?? 0;
      double h = double.tryParse(heightMatch?.group(1) ?? '0') ?? 0;
      double w = double.tryParse(widthMatch?.group(1) ?? '0') ?? 0;

      var textContent = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      
      textContent = textContent
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
      
      if (textContent.isEmpty) return '';

      final cx = x + w / 2;
      // Adjusted for vertical centering without dominant-baseline
      // Heuristic: Move text down by about 70% of the font size to align baseline.
      // Assuming a default font-size around 14px, 14 * 0.7 = ~9.8.
      // So, y + h/2 - (h/2 - baseline_offset)
      // Let's try y + h/2 + some manual adjustment.
      final cy = y + h / 2 + (h * 0.2); // Adjust based on height, maybe 20% from center?

      debugPrint('MermaidService: foreignObject -> Text Conversion: x=$x, y=$y, w=$w, h=$h, cx=$cx, cy=$cy, text="$textContent"');
      
      bool isEdgeLabel = content.contains('edgeLabel') || content.contains('labelBkg');

      String result = '';
      if (isEdgeLabel) {
        result += '<rect x="$x" y="$y" width="$w" height="$h" fill="${colors.background}" rx="4" ry="4" />';
      }

      // Removing font-size, text-anchor, dominant-baseline to let Flutter SVG default or CSS take over
      result += '<text x="$cx" y="$cy">$textContent</text>';
      return result;
    });
    
    // 5. Text
    // Commented out to avoid overriding inlined styles or creating duplicate attributes
    /*
    processed = processed.replaceAllMapped(RegExp(r'<text(\s|>)'), (match) {
      return '<text$textStyle${match.group(1)}';
    });
    */

    return processed;
  }

  void dispose() {
    _webviewService.dispose();
  }
}
