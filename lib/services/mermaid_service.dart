import 'package:xml/xml.dart';
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
    
    return processSvg(svg, config.colors);
  }

  @visibleForTesting
  String processSvg(String svg, ThemeColors colors) {
    try {
      final document = XmlDocument.parse(svg);
      
      // 1. Remove style blocks
      document.findAllElements('style').toList().forEach((node) => node.remove());

      // 2. Remove switch tags (keep children if needed? Usually for compatibility, let's remove for now as per prev logic)
      document.findAllElements('switch').toList().forEach((node) => node.remove());

      // 3. Process Shapes (Rect, Polygon, Circle, Ellipse)
      final shapes = ['rect', 'polygon', 'circle', 'ellipse'];
      for (final element in document.rootElement.descendants.whereType<XmlElement>()) {
        final tagName = element.name.local;

        if (shapes.contains(tagName)) {
           // Don't overwrite if it's a specific UI element like a button (rare in mermaid output but possible)
           // But generally we want to enforce theme.
           element.setAttribute('fill', colors.surface);
           element.setAttribute('stroke', colors.line);
           element.setAttribute('stroke-width', '2');
        } else if (tagName == 'path') {
           final id = element.getAttribute('id') ?? '';
           final classes = element.getAttribute('class') ?? '';
           final style = element.getAttribute('style') ?? '';
           
           if (id.contains('arrowMarker') || classes.contains('arrowMarkerPath') || style.contains('arrowMarkerPath')) {
              element.setAttribute('fill', colors.line);
              element.setAttribute('stroke', 'none');
           } else if (classes.contains('flowchart-link') || classes.contains('edge-pattern')) {
              element.setAttribute('fill', 'none');
              element.setAttribute('stroke', colors.line);
              element.setAttribute('stroke-width', '2');
           } else {
              // Generic path handling
              final currentFill = element.getAttribute('fill');
              if (currentFill == 'none' || currentFill == null) {
                 // Likely a line
                 // Only set if not already set? Or force?
                 // Force consistent line style
                 element.setAttribute('stroke', colors.line);
                 element.setAttribute('stroke-width', '2');
                 element.setAttribute('fill', 'none');
              } else {
                 // Likely a filled shape
                 element.setAttribute('fill', colors.surface);
                 element.setAttribute('stroke', colors.line); // Optional: add stroke to filled paths?
              }
           }
        }
      }

      // 4. Convert foreignObject to text
      // We need to collect them first to avoid modification during iteration issues if we change tree structure
      final foreignObjects = document.findAllElements('foreignObject').toList();
      
      double parseValue(String? v) {
        if (v == null) return 0;
        final cleaned = v.replaceAll('px', '').trim();
        return double.tryParse(cleaned) ?? 0;
      }
      
      for (final fo in foreignObjects) {
        final x = parseValue(fo.getAttribute('x'));
        final y = parseValue(fo.getAttribute('y'));
        final w = parseValue(fo.getAttribute('width'));
        final h = parseValue(fo.getAttribute('height'));
        
        // Extract text content recursively
        final textContent = fo.innerText.trim();
        
        if (textContent.isNotEmpty) {
           final cx = x + w / 2;
           final cy = y + h / 2;

           // Check if it's an edge label
           final contentHtml = fo.innerXml; // check raw XML for classes?
           bool isEdgeLabel = contentHtml.contains('edgeLabel') || contentHtml.contains('labelBkg');
           
           final parent = fo.parent;
           if (parent != null) {
             final index = parent.children.indexOf(fo);
             
             if (isEdgeLabel) {
               final rect = XmlElement(XmlName('rect'), [
                 XmlAttribute(XmlName('x'), x.toString()),
                 XmlAttribute(XmlName('y'), y.toString()),
                 XmlAttribute(XmlName('width'), w.toString()),
                 XmlAttribute(XmlName('height'), h.toString()),
                 XmlAttribute(XmlName('fill'), colors.background),
                 XmlAttribute(XmlName('rx'), '4'),
                 XmlAttribute(XmlName('ry'), '4'),
               ]);
               parent.children.insert(index, rect);
             }
             
             final textNode = XmlElement(XmlName('text'), [
                XmlAttribute(XmlName('x'), cx.toString()),
                XmlAttribute(XmlName('y'), cy.toString()),
                XmlAttribute(XmlName('dy'), '0.3em'),
                XmlAttribute(XmlName('text-anchor'), 'middle'),
                XmlAttribute(XmlName('fill'), colors.text),
                XmlAttribute(XmlName('font-family'), 'sans-serif'),
             ], [XmlText(textContent)]);
             
             parent.children.insert(isEdgeLabel ? index + 1 : index, textNode);
             fo.remove();
           }
        } else {
          fo.remove();
        }
      }

      // 5. Fix Mermaid's double-dy issue on native text elements
      // Consolidate vertical offset on the parent <text> element.
      // flutter_svg seems to respect dy on <text> but ignores/misinterprets dy on the first <tspan>.
      // Browsers sum them up.
      // Solution: Ensure offset is on <text>, and first <tspan> has dy="0" (or removed).
      for (final text in document.findAllElements('text')) {
        final tspans = text.children.whereType<XmlElement>().where((e) => e.name.local == 'tspan');
        if (tspans.isNotEmpty) {
           final firstTspan = tspans.first;
           final textDy = text.getAttribute('dy');
           final tspanDy = firstTspan.getAttribute('dy');

           if (textDy != null && textDy.isNotEmpty) {
             // Case 1: Text has dy (e.g. 14px). Tspan has dy (e.g. 1em).
             // Browser shows 14px + 1em (Too low). Flutter shows 14px (Good).
             // Fix: Keep text dy. Remove tspan dy.
             firstTspan.removeAttribute('dy');
           } else if (tspanDy != null && tspanDy.isNotEmpty) {
             // Case 2: Text has no dy. Tspan has dy (e.g. 1em).
             // Browser shows 1em. Flutter shows 0 (Too high).
             // Fix: Move dy to text.
             text.setAttribute('dy', tspanDy);
             firstTspan.removeAttribute('dy');
           }
        }
      }

      return document.toXmlString();
    } catch (e) {
      debugPrint('MermaidService: XML processing error: $e');
      return svg; // Fallback to raw SVG
    }
  }

  void dispose() {
    _webviewService.dispose();
  }
}
