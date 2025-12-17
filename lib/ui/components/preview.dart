import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class Preview extends StatelessWidget {
  const Preview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Common Loading State
    if (state.isCompiling) {
      return const Center(child: CircularProgressIndicator());
    }

    String svgContent = '';
    if (state.engine == RenderingEngine.d2) {
      svgContent = state.compiledD2Svg;
    } else {
      svgContent = state.compiledMermaidSvg;
    }

    if (svgContent.isEmpty) {
      return const Center(child: Text('No Output', style: TextStyle(color: Colors.white)));
    }

    return Container(
      color: Colors.white,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 8.0,
        child: Center(
          child: SvgPicture.string(
            svgContent,
            placeholderBuilder: (BuildContext context) => Container(
               padding: const EdgeInsets.all(30.0),
               child: const CircularProgressIndicator(),
            ),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red.withValues(alpha: 0.1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    const Text('Failed to render SVG', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(error.toString(), style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}