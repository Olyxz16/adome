import 'package:flutter_test/flutter_test.dart';
import 'package:adome/services/mermaid_service.dart';
import 'package:adome/models/app_theme_config.dart';

void main() {
  test('processSvg should not duplicate attributes', () {
    final service = MermaidService();
    const colors = ThemeColors(
      primary: '#0000FF',
      secondary: '#00FFFF',
      background: '#ffffff',
      surface: '#eeeeee',
      line: '#000000',
      text: '#333333',
    );

    const inputSvg = '''
<svg>
  <rect x="0" y="0" width="100" height="100" stroke-width="1" />
</svg>
''';

    final output = service.processSvg(inputSvg, colors);

    // Check that stroke-width appears only once in the rect tag
    // We expect: <rect ... stroke-width="2" ... /> (since we force 2)
    // It should NOT be <rect ... stroke-width="1" ... stroke-width="2" ... />
    
    // Simple string check might be tricky due to attribute order, but we can check occurrences.
    final rectTag = RegExp(r'<rect[^>]*>').firstMatch(output)?.group(0);
    expect(rectTag, isNotNull);
    
    final strokeWidthCount = 'stroke-width'.allMatches(rectTag!).length;
    expect(strokeWidthCount, equals(1), reason: 'rect tag should have exactly one stroke-width attribute: $rectTag');
    
    // Also verify it updated to our value "2"
    expect(rectTag, contains('stroke-width="2"'));
  });

  test('processSvg should correctly convert foreignObject to text', () {
    final service = MermaidService();
    const colors = ThemeColors(
      primary: '#0000FF',
      secondary: '#00FFFF',
      background: '#ffffff',
      surface: '#eeeeee',
      line: '#000000',
      text: '#333333',
    );

    const inputSvg = '''
<svg>
  <foreignObject x="10" y="10" width="100" height="20">
    <div xmlns="http://www.w3.org/1999/xhtml">
      <span>Hello World</span>
    </div>
  </foreignObject>
</svg>
''';

    final output = service.processSvg(inputSvg, colors);

    expect(output, isNot(contains('foreignObject')));
    expect(output, contains('<text'));
    expect(output, contains('>Hello World</text>'));
    expect(output, contains('dy="0.3em"'));
    
    // Check positioning logic (cx = 10 + 50 = 60, cy = 10 + 10 = 20)
    expect(output, contains('x="60.0"')); 
    expect(output, contains('y="20.0"'));
  });
  
  test('processSvg should correctly parse coordinates with px units', () {
    final service = MermaidService();
    const colors = ThemeColors(
      primary: '#0000FF',
      secondary: '#00FFFF',
      background: '#ffffff',
      surface: '#eeeeee',
      line: '#000000',
      text: '#333333',
    );

    const inputSvg = '''
<svg>
  <foreignObject x="-10px" y="-20px" width="100px" height="40px">
    <div xmlns="http://www.w3.org/1999/xhtml">
      <span>Unit Test</span>
    </div>
  </foreignObject>
</svg>
''';

    final output = service.processSvg(inputSvg, colors);

    // x = -10, w = 100 -> cx = -10 + 50 = 40
    // y = -20, h = 40  -> cy = -20 + 20 = 0
    
    expect(output, contains('x="40.0"')); 
    expect(output, contains('y="0.0"'));
  });

  test('processSvg consolidates dy on text elements (Case 1: Both exist)', () {
    final service = MermaidService();
    const colors = ThemeColors(
      primary: '#0000FF',
      secondary: '#00FFFF',
      background: '#ffffff',
      surface: '#eeeeee',
      line: '#000000',
      text: '#333333',
    );

    const inputSvg = '''
<svg>
  <g>
    <text dy="14px">
      <tspan dy="1em">Content</tspan>
    </text>
  </g>
</svg>
''';

    final output = service.processSvg(inputSvg, colors);
    
    // Text should KEEP dy="14px"
    expect(output, contains('<text dy="14px">'));
    // Tspan should LOSE dy
    expect(output, contains('<tspan>Content</tspan>'));
  });

  test('processSvg consolidates dy on text elements (Case 2: Tspan only)', () {
    final service = MermaidService();
    const colors = ThemeColors(
      primary: '#0000FF',
      secondary: '#00FFFF',
      background: '#ffffff',
      surface: '#eeeeee',
      line: '#000000',
      text: '#333333',
    );

    const inputSvg = '''
<svg>
  <g>
    <text>
      <tspan dy="1em">Content</tspan>
    </text>
  </g>
</svg>
''';

    final output = service.processSvg(inputSvg, colors);
    
    // Text should GAIN dy="1em"
    expect(output, contains('<text dy="1em">'));
    // Tspan should LOSE dy
    expect(output, contains('<tspan>Content</tspan>'));
  });

  test('processSvg handles XML safely', () {
     final service = MermaidService();
    const colors = ThemeColors(
      primary: '#0000FF',
      secondary: '#00FFFF',
      background: '#ffffff',
      surface: '#eeeeee',
      line: '#000000',
      text: '#333333',
    );
    
    // Malformed SVG input - checking resilience (xml package throws? or we catch?)
    // Our implementation has try-catch returning original string.
    const input = '<svg><unclosed tag';
    final output = service.processSvg(input, colors);
    expect(output, equals(input));
  });
}
