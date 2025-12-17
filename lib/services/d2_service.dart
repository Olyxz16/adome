import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class D2Service {
  Future<String> compile(String content, {int themeId = 0}) async {
    print('D2Service: Starting compilation...');
    try {
      final executablePath = await _resolveExecutablePath();
      print('D2Service: Spawning d2 process at $executablePath...');
      final process = await Process.start(executablePath, ['-', '-', '--no-xml-tag', '--theme', themeId.toString()]);
      
      print('D2Service: Writing content to stdin...');
      process.stdin.write(content);
      await process.stdin.close();
      print('D2Service: Stdin closed.');

      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      final results = await Future.wait([stdoutFuture, stderrFuture, process.exitCode]);
      final stdout = results[0] as String;
      final stderr = results[1] as String;
      final exitCode = results[2] as int;

      print('D2Service: Exit Code: $exitCode');
      if (stderr.isNotEmpty) print('D2Service: Stderr: $stderr');

      if (exitCode != 0) {
        throw Exception('D2 Error: $stderr');
      }

      print('D2Service: Success. Output length: ${stdout.length}');
      return _processSvg(stdout);
    } catch (e) {
      print('D2Service: Exception caught: $e');
      print('D2Service: PATH environment: ${Platform.environment['PATH']}');
      // Return a placeholder SVG or error message in SVG format
      return '''
<svg width="400" height="200" xmlns="http://www.w3.org/2000/svg">
  <rect width="100%" height="100%" fill="#f0f0f0"/>
  <text x="50%" y="50%" font-family="monospace" font-size="14" fill="red" text-anchor="middle" dominant-baseline="middle">
    Error compiling D2: ${e.toString().replaceAll('<', '&lt;').replaceAll('>', '&gt;')}
  </text>
  <text x="50%" y="70%" font-family="monospace" font-size="12" fill="#555" text-anchor="middle" dominant-baseline="middle">
    Ensure 'd2' is installed and in your PATH.
  </text>
</svg>
''';
    }
  }

  Future<String> _resolveExecutablePath() async {
    // 1. Try to extract bundled asset
    try {
      final appDir = await getApplicationSupportDirectory();
      final binDir = Directory('${appDir.path}/bin');
      if (!await binDir.exists()) {
        await binDir.create(recursive: true);
      }
      final fileName = Platform.isWindows ? 'd2.exe' : 'd2';
      final d2File = File('${binDir.path}/$fileName');

      // Check if we need to copy it (e.g. does not exist). 
      // ideally check version or checksum, but simplistic check for now.
      if (!await d2File.exists()) {
        print('D2Service: Extracting bundled d2 binary...');
        // The asset key in pubspec is always 'assets/bin/d2' regardless of platform
        final byteData = await rootBundle.load('assets/bin/d2');
        await d2File.writeAsBytes(byteData.buffer.asUint8List());
        
        // Make executable
        if (Platform.isLinux || Platform.isMacOS) {
          await Process.run('chmod', ['+x', d2File.path]);
        }
        print('D2Service: Extracted to ${d2File.path}');
      }
      return d2File.path;
    } catch (e) {
      print('D2Service: Failed to extract bundled binary ($e). Falling back to system paths.');
    }

    // 2. Fallback to existing checks
    // We check explicit paths first because Flutter environment PATH might be minimal.
    final home = Platform.environment['HOME'];
    if (home != null) {
      final localBin = '$home/.local/bin/d2';
      if (await File(localBin).exists()) return localBin;
    }

    if (Platform.isWindows) {
      // Check common windows paths or just return 'd2.exe'
      return 'd2.exe';
    }

    if (await File('/usr/local/bin/d2').exists()) return '/usr/local/bin/d2';
    
    // Fallback to expecting it in PATH
    return 'd2';
  }

  String _processSvg(String svg) {
    var processed = svg;

    // 1. Remove style blocks
    processed = processed.replaceAll(RegExp(r'<style[\s\S]*?<\/style>'), '');
    
    // 2. Remove mask attributes
    processed = processed.replaceAll(RegExp(r'\smask="[^"]*"'), '');

    // 3. Unwrap nested SVGs
    // D2 output: <svg ...><svg ...> content </svg></svg>
    // We want the inner SVG.
    // Regex to find the inner <svg ...> ... </svg>
    // We assume the outer SVG wraps the inner one directly.
    
    // Find the first occurrence of <svg ...> that is NOT the start of the string (ignoring xml decl)
    // Actually, simpler: find the *second* <svg tag start.
    
    final svgTagStart = RegExp(r'<svg[^>]*>');
    final matches = svgTagStart.allMatches(processed).toList();
    
    if (matches.length >= 2) {
      print('D2Service: Detected nested SVGs. Unwrapping...');
      // We assume the structure is <svg outer><svg inner>...</svg></svg>
      // We want to extract from the start of the second match to the end of the string, 
      // minus the last </svg> (which belongs to the outer one).
      
      final innerStart = matches[1].start;
      final lastSvgClose = processed.lastIndexOf('</svg>');
      
      if (innerStart > 0 && lastSvgClose > innerStart) {
         // Check if there is a closing tag for the inner SVG before the last one?
         // D2 usually outputs exactly two closing tags at the end: </svg></svg>
         // So taking from innerStart to lastSvgClose should give us <svg inner>...</svg> 
         // provided we assume the last tag is the outer one's closer.
         
         processed = processed.substring(innerStart, lastSvgClose).trim();
         
         // If the result doesn't end with >, it might have been whitespace trimmed weirdly, 
         // but substring includes the char at innerStart up to lastSvgClose (exclusive).
         // Wait, substring(start, end) -> exclusive end.
         // If string ends with ...</svg></svg>
         // lastIndex is the index of the last <.
         // We want to keep the inner </svg>. 
         // The outer </svg> is at the very end.
         // So we strip the *last* </svg> tag string.
      }
    }
    
    print('D2Service: Processed SVG (first 200 chars): ${processed.substring(0, processed.length > 200 ? 200 : processed.length)}');
    return processed;
  }
}
