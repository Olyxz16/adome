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
      
      // Prevent deadlock: Listen to output streams BEFORE writing to stdin
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      print('D2Service: Writing content to stdin...');
      // Use add for bytes or write for string. Write is fine but ensure encoding.
      process.stdin.write(content);
      await process.stdin.close();
      print('D2Service: Stdin closed.');

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
    // 1. Try to extract bundled asset (Only for Linux/Mac as the asset is likely ELF)
    // If we are on Windows, we shouldn't overwrite d2.exe with an ELF binary unless we have a Windows binary asset.
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        final appDir = await getApplicationSupportDirectory();
        final binDir = Directory('${appDir.path}/bin');
        if (!await binDir.exists()) {
          await binDir.create(recursive: true);
        }
        final d2File = File('${binDir.path}/d2');

        if (!await d2File.exists()) {
          print('D2Service: Extracting bundled d2 binary...');
          final byteData = await rootBundle.load('assets/bin/d2');
          await d2File.writeAsBytes(byteData.buffer.asUint8List());
          await Process.run('chmod', ['+x', d2File.path]);
          print('D2Service: Extracted to ${d2File.path}');
        }
        return d2File.path;
      }
    } catch (e) {
      print('D2Service: Failed to extract bundled binary ($e). Falling back to system paths.');
    }

    // 2. Fallback to existing checks
    final home = Platform.environment['HOME'];
    if (home != null) {
      final localBin = '$home/.local/bin/d2';
      if (await File(localBin).exists()) return localBin;
    }

    if (Platform.isWindows) {
      return 'd2.exe';
    }

    if (await File('/usr/local/bin/d2').exists()) return '/usr/local/bin/d2';
    
    return 'd2';
  }

  String _processSvg(String svg) {
    var processed = svg;

    // 1. Remove style blocks
    processed = processed.replaceAll(RegExp(r'<style[\s\S]*?<\/style>'), '');
    
    // 2. Remove mask attributes
    processed = processed.replaceAll(RegExp(r'\smask="[^"]*"'), '');

    // 3. Unwrap nested SVGs
    final svgTagStart = RegExp(r'<svg[^>]*>');
    final matches = svgTagStart.allMatches(processed).toList();
    
    if (matches.length >= 2) {
      print('D2Service: Detected nested SVGs. Unwrapping...');
      
      final innerStart = matches[1].start;
      // We expect the structure: <svg outer> ... <svg inner> ... </svg inner> ... </svg outer>
      // The outer SVG closes at the very end.
      // The inner SVG closes before that.
      
      final lastSvgClose = processed.lastIndexOf('</svg>');
      if (lastSvgClose > innerStart) {
        // Find the closing tag BEFORE the last one
        final innerSvgClose = processed.substring(0, lastSvgClose).lastIndexOf('</svg>');
        
        if (innerSvgClose > innerStart) {
           // We take from innerStart to innerSvgClose + length of </svg>
           processed = processed.substring(innerStart, innerSvgClose + 6);
        } else {
           // Fallback: If we couldn't find a second closing tag, maybe there is only one at the end?
           // (e.g. invalid nesting). Just take everything inside?
           // Let's stick to the previous behavior but safer: take until lastSvgClose if no inner found?
           // No, that strips the closing tag.
           // Let's assume the previous code meant to take the content OF the inner SVG?
           // No, we want the inner SVG element itself.
           
           // If we can't find proper nesting, leave it as is.
           print('D2Service: Could not find inner closing tag. Returning original.');
        }
      }
    }
    
    return processed;
  }
}
