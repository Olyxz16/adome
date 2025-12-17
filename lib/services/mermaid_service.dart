import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class MermaidService {
  // Use a local mmdc executable if available
  final String _mmdcPath = 'mmdc';

  Future<String> compile(String content, {
    String theme = 'neutral',
    String layout = 'default',
    String elkAlgorithm = 'layered',
  }) async {
    // 1. Try local mmdc
    try {
      // Check if mmdc exists? Or just run it.
      // We assume if it fails, we fall back.
      // mmdc -i - -o - (stdin to stdout)?
      // mmdc usually requires files.
      // Let's create a temp file.
      
      // Since we know the environment is likely missing chrome deps, 
      // we can skip this check or make it robust.
      // Let's rely on online fallback primarily if local fails.
      
      return await _compileLocal(content);
    } catch (e) {
      print('MermaidService: Local compilation failed ($e). Falling back to online.');
      return await _compileOnline(content, theme: theme, layout: layout, elkAlgorithm: elkAlgorithm);
    }
  }

  Future<String> _compileLocal(String content) async {
      // This is a placeholder for local compilation if mmdc was working.
      // Given the environment, this will likely throw.
      final process = await Process.start(_mmdcPath, ['-i', '-', '-o', '-']);
      process.stdin.write(content);
      await process.stdin.close();
      
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      
      if (exitCode != 0) {
        throw Exception('mmdc failed');
      }
      return stdout;
  }

  Future<String> _compileOnline(String content, {
    required String theme,
    required String layout,
    required String elkAlgorithm,
  }) async {
    // Use mermaid.ink
    // Base64 encode the graph definition
    
    // Mermaid.ink expects: https://mermaid.ink/svg/BASE64
    // where BASE64 is a JSON object { "code": "..." } encoded
    
    final Map<String, dynamic> mermaidConfig = {
      'theme': theme,
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

    final jsonString = jsonEncode({
      'code': content, 
      'mermaid': mermaidConfig,
    });
    final base64String = base64Url.encode(utf8.encode(jsonString));
    
    final url = Uri.parse('https://mermaid.ink/svg/$base64String');
    
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return _processSvg(response.body);
    } else {
      throw Exception('Online compilation failed: ${response.statusCode}');
    }
  }

  String _processSvg(String svg) {
    print('MermaidService: Raw SVG contains "foreignObject": ${svg.contains('foreignObject')}');
    
    var processed = svg;

    // 1. Remove style blocks
    processed = processed.replaceAll(RegExp(r'<style[\s\S]*?<\/style>'), '');

    // 2. Remove foreignObject blocks (flutter_svg doesn't support them)
    // We try to remove the tag and its content.
    // processed = processed.replaceAll(RegExp(r'<foreignObject[\s\S]*?<\/foreignObject>'), ''); // Old naive way

    // Remove <switch> tags (keep content) as they might confuse flutter_svg when foreignObject is replaced
    processed = processed.replaceAll(RegExp(r'<\/?switch[^>]*>'), '');

    // 2. Inject default styles for shapes (Rect, Polygon, Circle, Ellipse)
    const shapeStyle = ' fill="#ffffff" stroke="#333333" stroke-width="2" ';
    const lineStyle = ' fill="none" stroke="#333333" stroke-width="2" ';
    // Text style for existing text tags (if any)
    const textStyle = ' fill="#333333" font-family="sans-serif" ';

    processed = processed.replaceAll('<rect', '<rect$shapeStyle');
    processed = processed.replaceAll('<polygon', '<polygon$shapeStyle');
    processed = processed.replaceAll('<circle', '<circle$shapeStyle');
    processed = processed.replaceAll('<ellipse', '<ellipse$shapeStyle');
    
    // 3. Lines
    processed = processed.replaceAll('<path', '<path$lineStyle');

    // 4. Convert foreignObject to text
    // Regex to capture foreignObject attributes and content
    // <foreignObject ...> ... content ... </foreignObject>
    final foreignObjectRegex = RegExp(r'<foreignObject([^>]*)>([\s\S]*?)<\/foreignObject>');
    
    processed = processed.replaceAllMapped(foreignObjectRegex, (match) {
      final attributes = match.group(1) ?? '';
      final content = match.group(2) ?? '';
      
      // Extract x and y
      final xMatch = RegExp(r'x="([^"]*)"').firstMatch(attributes);
      final yMatch = RegExp(r'y="([^"]*)"').firstMatch(attributes);
      final widthMatch = RegExp(r'width="([^"]*)"').firstMatch(attributes);
      final heightMatch = RegExp(r'height="([^"]*)"').firstMatch(attributes);
      
      double x = double.tryParse(xMatch?.group(1) ?? '0') ?? 0;
      double y = double.tryParse(yMatch?.group(1) ?? '0') ?? 0;
      double h = double.tryParse(heightMatch?.group(1) ?? '0') ?? 0;
      double w = double.tryParse(widthMatch?.group(1) ?? '0') ?? 0;

      // Extract text from content (remove HTML tags)
      // Content usually looks like: <div ...><span ...>Text</span></div>
      // We strip all tags.
      var textContent = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      
      // XML Escape the content
      textContent = textContent
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
      
      if (textContent.isEmpty) return '';

      // Center text
      // Simple centering: x + width/2, y + height/2 + adjustment
      final cx = x + w / 2;
      final cy = y + h / 2 + 5; // heuristic vertical center
      
      // Check if it's an edge label to add background
      bool isEdgeLabel = content.contains('edgeLabel') || content.contains('labelBkg');

      String result = '';
      if (isEdgeLabel) {
        // Add background rect for edge labels
        result += '<rect x="$x" y="$y" width="$w" height="$h" fill="#ffffff" rx="4" ry="4" />';
      }

      // Return a text element
      // We don't add fill/font-family here, as step 5 will add them globally.
      result += '<text x="$cx" y="$cy" font-size="14" text-anchor="middle" dominant-baseline="middle">$textContent</text>';
      return result;
    });
    
    // 5. Text
    // Use replaceAllMapped to correctly handle backreferences
    processed = processed.replaceAllMapped(RegExp(r'<text(\s|>)'), (match) {
      return '<text$textStyle${match.group(1)}';
    });

    return processed;
  }
}
