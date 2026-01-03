import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class Preview extends StatefulWidget {
  const Preview({super.key});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetView() {
    setState(() {
      _transformationController.value = Matrix4.identity();
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final double scaleChange = event.scrollDelta.dy < 0 ? 1.1 : 0.9;
      final Matrix4 matrix = _transformationController.value;
      final double currentScale = matrix.getMaxScaleOnAxis();
      
      double newScale = currentScale * scaleChange;
      if (newScale < 0.1) newScale = 0.1;
      if (newScale > 20.0) newScale = 20.0;
      
      final double effectiveScaleChange = newScale / currentScale;

      final Offset focalPoint = event.localPosition;
      
      // Zoom around focal point
      final Matrix4 translation = Matrix4.translationValues(focalPoint.dx, focalPoint.dy, 0);
      final Matrix4 scale = Matrix4.diagonal3Values(effectiveScaleChange, effectiveScaleChange, 1);
      final Matrix4 translationInv = Matrix4.translationValues(-focalPoint.dx, -focalPoint.dy, 0);
      
      // M_new = T * S * T_inv * M_old
      _transformationController.value = translation * scale * translationInv * matrix;
    }
  }

  Color _parseColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

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
      color: _parseColor(state.activeThemeConfig.colors.background),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                onPointerSignal: _onPointerSignal,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.1,
                  maxScale: 20.0,
                  trackpadScrollCausesScale: true,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: SvgPicture.string(
                      svgContent,
                      fit: BoxFit.contain,
                      placeholderBuilder: (BuildContext context) => Container(
                         padding: const EdgeInsets.all(30.0),
                         child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Container(
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            }
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _resetView,
              tooltip: 'Center & Fit',
              child: const Icon(Icons.center_focus_strong),
            ),
          ),
        ],
      ),
    );
  }
}
