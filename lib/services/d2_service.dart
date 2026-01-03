import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import '../models/app_theme_config.dart';

class D2Service {
  Future<String> compile(String content, {int themeId = 0, String? backgroundColor, ThemeColors? themeColors}) async {
    debugPrint('D2Service: Starting compilation...');
    try {
      final executablePath = await _resolveExecutablePath();
      debugPrint('D2Service: Spawning d2 process at $executablePath...');
      final process = await Process.start(executablePath, ['-', '-', '--no-xml-tag', '--theme', themeId.toString()]);
      
      // Prevent deadlock: Listen to output streams BEFORE writing to stdin
      final stdoutFuture = process.stdout.transform(utf8.decoder).join();
      final stderrFuture = process.stderr.transform(utf8.decoder).join();

      debugPrint('D2Service: Writing content to stdin...');
      // Use add for bytes or write for string. Write is fine but ensure encoding.
      process.stdin.write(content);
      await process.stdin.close();
      debugPrint('D2Service: Stdin closed.');

      final results = await Future.wait([stdoutFuture, stderrFuture, process.exitCode]);
      final stdout = results[0] as String;
      final stderr = results[1] as String;
      final exitCode = results[2] as int;

      debugPrint('D2Service: Exit Code: $exitCode');
      if (stderr.isNotEmpty) debugPrint('D2Service: Stderr: $stderr');

      if (exitCode != 0) {
        throw Exception('D2 Error: $stderr');
      }

      debugPrint('D2Service: Success. Output length: ${stdout.length}');
      return _processSvg(stdout, backgroundColor, themeColors);
    } catch (e) {
      debugPrint('D2Service: Exception caught: $e');
      debugPrint('D2Service: PATH environment: ${Platform.environment['PATH']}');
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
          debugPrint('D2Service: Extracting bundled d2 binary...');
          final byteData = await rootBundle.load('assets/bin/d2');
          await d2File.writeAsBytes(byteData.buffer.asUint8List());
          await Process.run('chmod', ['+x', d2File.path]);
          debugPrint('D2Service: Extracted to ${d2File.path}');
        }
        return d2File.path;
      }
    } catch (e) {
      debugPrint('D2Service: Failed to extract bundled binary ($e). Falling back to system paths.');
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

  String _processSvg(String svg, String? backgroundColor, ThemeColors? colors) {
    try {
      final document = XmlDocument.parse(svg);

      // 1. Remove all style blocks
      document.findAllElements('style').toList().forEach((node) => node.remove());

      // 2. Flatten Nested SVG (D2 outputs an outer SVG wrapping an inner SVG)
      // This seems to confuse some renderers or cause layout loops.
      final root = document.rootElement;
      final innerSvgs = root.findAllElements('svg').toList();
      
      if (innerSvgs.isNotEmpty) {
        final inner = innerSvgs.first;
        // Move all children of inner SVG to root
        final children = inner.children.toList(); // Copy list
        for (final child in children) {
           child.remove(); // Detach
           root.children.add(child); // Re-attach
        }
        
        // Copy viewBox from inner if root doesn't have one or if we prefer inner
        final innerViewBox = inner.getAttribute('viewBox');
        if (innerViewBox != null) {
          root.setAttribute('viewBox', innerViewBox);
        }
        
        // Remove the inner SVG element
        inner.remove(); 
      }

      // 3. Remove mask attributes
      for (final element in document.rootElement.descendants.whereType<XmlElement>()) {
        element.removeAttribute('mask');
      }

      // 4. Remove Existing Background Rects (Direct children of SVG that are white)
      // This prevents white backgrounds from blocking our themed background or being stuck white.
      final whiteRectsToRemove = <XmlElement>[];
      for (final rect in document.findAllElements('rect')) {
         // Check if parent is SVG (direct child)
         if (rect.parent is XmlElement && (rect.parent as XmlElement).name.local == 'svg') {
            final fill = rect.getAttribute('fill')?.toLowerCase().trim();
            if (fill != null) {
               final isWhite = fill == 'white' || 
                               fill == '#ffffff' || 
                               fill == '#fff' || 
                               fill == 'rgb(255,255,255)' ||
                               fill == 'rgb(255, 255, 255)';
               if (isWhite) {
                 whiteRectsToRemove.add(rect);
               }
            }
         }
      }
      for (final r in whiteRectsToRemove) {
        r.remove();
      }

      // 5. Inject Proper Background
      if (backgroundColor != null && backgroundColor.isNotEmpty) {
          String x = '0';
          String y = '0';
          String w = '100%';
          String h = '100%';

          // Try to use viewBox dimensions
          final root = document.rootElement;
          final viewBox = root.getAttribute('viewBox');
          if (viewBox != null) {
            final parts = viewBox.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
            if (parts.length == 4) {
              x = parts[0];
              y = parts[1];
              w = parts[2];
              h = parts[3];
            }
          }

          final bgRect = XmlElement(XmlName('rect'), [
             XmlAttribute(XmlName('x'), x),
             XmlAttribute(XmlName('y'), y),
             XmlAttribute(XmlName('width'), w),
             XmlAttribute(XmlName('height'), h),
             XmlAttribute(XmlName('fill'), backgroundColor),
             XmlAttribute(XmlName('stroke'), 'none'),
          ]);
          
          if (root.children.isNotEmpty) {
             root.children.insert(0, bgRect);
          } else {
             root.children.add(bgRect);
          }
      }

      // 5. Force Apply Theme Colors (Inline Attributes)
      if (colors != null) {
        final shapes = ['rect', 'circle', 'ellipse', 'polygon'];
        final lines = ['path', 'line', 'polyline'];
        
        for (final element in document.rootElement.descendants.whereType<XmlElement>()) {
          final tagName = element.name.local;
          
          // Skip if this is our newly injected background rect (it won't match shapes logic easily but good to be safe)
          // We can check if fill == backgroundColor.
          final currentFill = element.getAttribute('fill');
          if (currentFill == backgroundColor) continue;

          if (shapes.contains(tagName)) {
             element.removeAttribute('style');
             element.setAttribute('stroke', colors.line);
             element.setAttribute('stroke-width', '2');
             element.setAttribute('fill', colors.surface);
          } else if (lines.contains(tagName)) {
             element.removeAttribute('style');
             
             if (currentFill == 'none' || currentFill == null) {
               element.setAttribute('stroke', colors.line);
               element.setAttribute('stroke-width', '2');
               element.setAttribute('fill', 'none');
             } else {
               element.setAttribute('fill', colors.line);
               element.setAttribute('stroke', 'none');
             }
          } else if (tagName == 'text') {
             final style = element.getAttribute('style') ?? '';
             final anchor = RegExp(r'text-anchor\s*:\s*([^;]+)').firstMatch(style)?.group(1)?.trim();
             final baseline = RegExp(r'dominant-baseline\s*:\s*([^;]+)').firstMatch(style)?.group(1)?.trim();
             final fontSize = RegExp(r'font-size\s*:\s*([^;]+)').firstMatch(style)?.group(1)?.trim();

             element.setAttribute('fill', colors.text);
             element.removeAttribute('style');
             element.setAttribute('font-family', 'sans-serif');
             
             if (anchor != null) element.setAttribute('text-anchor', anchor);
             if (baseline != null) element.setAttribute('dominant-baseline', baseline);
             if (fontSize != null) element.setAttribute('font-size', fontSize);
          }
        }
      }

      return document.toXmlString();
    } catch (e) {
      debugPrint('D2Service: XML Parse Error ($e). Returning original (sanitized).');
      var processed = svg;
      processed = processed.replaceAll(RegExp(r'<style[\s\S]*?<\/style>'), '');
      processed = processed.replaceAll(RegExp(r'\smask="[^"]*"'), '');
      return processed;
    }
  }
}
