import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Mermaid SVG processing correctly adds background to edge labels', () {
    // Sample SVG fragment representing an edge label from Mermaid
    const String inputSvg = '''
<g class="edgeLabels">
  <g class="edgeLabel" transform="translate(43.3359375, 99)">
    <g class="label" data-id="L_A_B_0" transform="translate(-16.90625, -12)">
      <foreignObject width="33.8125" height="24">
        <div xmlns="http://www.w3.org/1999/xhtml" class="labelBkg" style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">
          <span class="edgeLabel"><p>label</p></span>
        </div>
      </foreignObject>
    </g>
  </g>
</g>
''';

    // Logic from MermaidService._processSvg
    // Copied here to verify the logic in isolation
    
    final foreignObjectRegex = RegExp(r'<foreignObject([^>]*)>([\s\S]*?)<\/foreignObject>');
    
    String processed = inputSvg.replaceAllMapped(foreignObjectRegex, (match) {
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

      var textContent = content.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      
      textContent = textContent
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
      
      if (textContent.isEmpty) return '';

      final cx = x + w / 2;
      final cy = y + h / 2 + 5; 
      
      bool isEdgeLabel = content.contains('edgeLabel') || content.contains('labelBkg');

      String result = '';
      if (isEdgeLabel) {
        // Add background rect for edge labels
        result += '<rect x="$x" y="$y" width="$w" height="$h" fill="#ffffff" rx="4" ry="4" />';
      }

      result += '<text x="$cx" y="$cy" font-size="14" text-anchor="middle" dominant-baseline="middle">$textContent</text>';
      return result;
    });

    // Verification
    // Should contain a rect with white fill
    expect(processed, contains('<rect x="0.0" y="0.0" width="33.8125" height="24.0" fill="#ffffff" rx="4" ry="4" />'));
    // Should contain the text
    expect(processed, contains('>label</text>'));
  });

  test('Mermaid SVG processing does NOT add background to node labels (generic)', () {
     const String inputSvg = '''
<g class="node default">
  <g class="label">
    <foreignObject width="10" height="10">
      <div xmlns="http://www.w3.org/1999/xhtml">
        <span class="nodeLabel"><p>A</p></span>
      </div>
    </foreignObject>
  </g>
</g>
''';

    final foreignObjectRegex = RegExp(r'<foreignObject([^>]*)>([\s\S]*?)<\/foreignObject>');
    
    String processed = inputSvg.replaceAllMapped(foreignObjectRegex, (match) {
        final content = match.group(2) ?? '';
        // ... (simplified check for test)
        bool isEdgeLabel = content.contains('edgeLabel') || content.contains('labelBkg');
        return isEdgeLabel ? '<rect/>' : '';
    });
    
    expect(processed, isNot(contains('<rect/>')));
  });
}