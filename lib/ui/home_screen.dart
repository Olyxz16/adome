import 'package:flutter/material.dart';
import 'components/ribbon.dart';
import 'components/editor.dart';
import 'components/preview.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: Column(
        children: [
          const Ribbon(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: Editor()),
                Container(width: 1, color: Colors.grey[800]),
                const Expanded(child: Preview()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
