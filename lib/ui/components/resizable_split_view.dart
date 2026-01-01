import 'package:flutter/material.dart';

class ResizableSplitView extends StatefulWidget {
  final Widget left;
  final Widget right;
  final double initialLeftWidth;
  final double minLeftWidth;
  final double minRightWidth;

  const ResizableSplitView({
    super.key,
    required this.left,
    required this.right,
    this.initialLeftWidth = 500,
    this.minLeftWidth = 200,
    this.minRightWidth = 200,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  late double _leftWidth;

  @override
  void initState() {
    super.initState();
    _leftWidth = widget.initialLeftWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Ensure _leftWidth is within bounds
        if (_leftWidth > maxWidth - widget.minRightWidth) {
           _leftWidth = maxWidth - widget.minRightWidth;
        }
        if (_leftWidth < widget.minLeftWidth) {
           _leftWidth = widget.minLeftWidth;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _leftWidth,
              child: widget.left,
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _leftWidth += details.delta.dx;
                  if (_leftWidth < widget.minLeftWidth) {
                    _leftWidth = widget.minLeftWidth;
                  }
                  if (_leftWidth > maxWidth - widget.minRightWidth) {
                    _leftWidth = maxWidth - widget.minRightWidth;
                  }
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: Container(
                  width: 9,
                  color: Colors.transparent, // Invisible hit area
                  alignment: Alignment.center,
                  child: Container(
                    width: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: widget.right,
            ),
          ],
        );
      },
    );
  }
}
