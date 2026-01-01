import 'package:flutter/material.dart';
import 'components/ribbon.dart';
import 'components/editor.dart';
import 'components/preview.dart';

import 'components/resizable_split_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Uses the Scaffold background color defined in the active App Theme (Light/Dark)
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Ribbon(),
          Expanded(
            child: ResizableSplitView(
              left: const Editor(),
              right: const Preview(),
            ),
          ),
        ],
      ),
    );
  }
}