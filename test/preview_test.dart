import 'package:adome/models/app_theme_config.dart';
import 'package:adome/services/theme_service.dart';
import 'package:adome/state/app_state.dart';
import 'package:adome/ui/components/preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Fake AppState that implements only what is needed for Preview
class FakeAppState extends ChangeNotifier implements AppState {
  @override
  bool get isCompiling => false;

  @override
  RenderingEngine get engine => RenderingEngine.mermaid;

  @override
  AppThemeConfig get activeThemeConfig => ThemeService.defaultTheme;

  @override
  String get compiledMermaidSvg => '<svg height="100" width="100"><circle cx="50" cy="50" r="40" stroke="black" stroke-width="3" fill="red" /></svg>';

  @override
  String get compiledD2Svg => '';

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  testWidgets('Preview renders InteractiveViewer with SvgPicture', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AppState>(
          create: (_) => FakeAppState(),
          child: const Preview(),
        ),
      ),
    );

    // Verify InteractiveViewer is present
    expect(find.byType(InteractiveViewer), findsOneWidget);

    // Verify Listener is wrapping InteractiveViewer (or somewhere above it)
    expect(find.byType(Listener), findsAtLeastNWidgets(1));
    expect(find.ancestor(of: find.byType(InteractiveViewer), matching: find.byType(Listener)), findsWidgets);

    // Verify SvgPicture is present
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
