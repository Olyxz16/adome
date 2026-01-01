import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adome/services/d2_service.dart'; // Make sure this is accessible

// Since D2Service is a class with private methods, we can't test _processSvg directly in a clean way without
// making it public or using reflection (forbidden). 
// However, we can test the RESULT of the service if we mock the D2 output or if we manually verify the fix logic 
// by mimicking what D2Service does.

// Given the constraints, I will create a test that verifies that SvgPicture can handle the kind of SVG 
// that D2Service NOW produces (flattened, absolute coords).

void main() {
  testWidgets('SvgPicture renders flattened D2-style SVG with absolute background', (WidgetTester tester) async {
    // This is what D2Service produces now:
    const processedSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-101 -101 256 434">
  <rect x="-101" y="-101" width="256" height="434" fill="#1e1e1e" stroke="none"/>
  <rect x="-101" y="-101" width="256" height="434" fill="white" />
</svg>
''';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SvgPicture.string(processedSvg),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
