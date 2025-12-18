import 'package:flutter/material.dart';
import 'components/ribbon.dart';
import 'components/editor.dart';
import 'components/preview.dart';

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: Editor()),
                VerticalDivider(width: 1, color: Theme.of(context).dividerColor),
                const Expanded(child: Preview()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}