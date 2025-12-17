import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/app_state.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late CodeController _codeController;
  RenderingEngine? _lastEngine;
  String? _lastContentFromState;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: markdown,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    
    // Sync state to controller only if needed
    if (_lastEngine != state.engine || (_codeController.text != state.currentContent && state.currentContent != _lastContentFromState)) {
       // Ideally we check if the state content is actually different from what we think we have.
       // The simplest heuristic for this single-user app:
       // If state.currentContent matches what we last sent to it, don't update (avoid cursor jumps).
       // If it's different, it must be from file load.
       
       if (_lastEngine != state.engine) {
          _codeController.text = state.currentContent;
       } else {
         // Check if update came from typing
         // If we just typed "A", state has "A". _codeController has "A".
         // Logic: OnChange updates state.
         // Only external updates (File Load) should trigger this.
         // AppState should ideally expose a stream or signal for "External Load".
         // But we can just check if the text is radically different?
         // No.
         // Let's just trust that if the text is exactly the same, we do nothing.
         if (_codeController.text != state.currentContent) {
           _codeController.text = state.currentContent;
         }
       }
       _lastEngine = state.engine;
    }
    
    // Cache what we have seen
    _lastContentFromState = state.currentContent;

    return CodeTheme(
      data: CodeThemeData(styles: monokaiSublimeTheme),
      child: Container(
        color: const Color(0xFF272822), // Monokai bg
        // Use expanded CodeField to fill the container and handle scrolling internally
        child: CodeField(
          controller: _codeController,
          textStyle: GoogleFonts.firaCode(fontSize: 14),
          onChanged: (value) => context.read<AppState>().updateContent(value),
          expands: true,
          wrap: false,
        ),
      ),
    );
  }
}
