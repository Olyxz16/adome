import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class WebviewService {
  Webview? _webview;
  HttpServer? _server;
  Completer<void>? _webviewReadyCompleter;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Completer<String>? _renderResultCompleter;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _webviewReadyCompleter = Completer<void>();

    try {
      // 1. Prepare the temporary directory
      final supportDir = await getApplicationSupportDirectory();
      final rendererDir = Directory(p.join(supportDir.path, 'renderer'));
      if (!await rendererDir.exists()) {
        await rendererDir.create(recursive: true);
      }

      // 2. Copy mermaid.min.js
      final mermaidJsData = await rootBundle.load('assets/mermaid.min.js');
      final jsFile = File(p.join(rendererDir.path, 'mermaid.min.js'));
      await jsFile.writeAsBytes(
        mermaidJsData.buffer.asUint8List(
          mermaidJsData.offsetInBytes, 
          mermaidJsData.lengthInBytes
        )
      );

      // 3. Copy mermaid.html
      final htmlData = await rootBundle.loadString('assets/mermaid.html');
      final htmlFile = File(p.join(rendererDir.path, 'mermaid_renderer.html'));
      await htmlFile.writeAsString(htmlData);

      debugPrint('WebviewService: Assets copied to ${rendererDir.path}');

      // 4. Start Local Server (Bypass file:// restrictions)
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      
      // Helper to handle messages
      void handleMessage(String body) {
         if (body == 'READY') {
          if (_webviewReadyCompleter != null && !_webviewReadyCompleter!.isCompleted) {
            _webviewReadyCompleter!.complete();
            debugPrint('WebviewService: READY signal received.');
          }
        } else if (body.startsWith('SVG:')) {
          _renderResultCompleter?.complete(Uri.decodeComponent(body.substring(4)));
        } else if (body.startsWith('ERROR:')) {
          _renderResultCompleter?.completeError(Exception(Uri.decodeComponent(body.substring(6))));
        } else if (body.startsWith('LOG:')) {
           // debugPrint('WebviewJS: ${Uri.decodeComponent(body.substring(4))}');
        }
      }

      _server!.listen((request) async {
        // BRIDGE HANDLER
        if (request.uri.path == '/BRIDGE') {
           final msg = request.uri.queryParameters['msg'];
           if (msg != null) {
              handleMessage(msg);
           }
           request.response.headers.add('Access-Control-Allow-Origin', '*');
           request.response.statusCode = HttpStatus.ok;
           request.response.close();
           return;
        }

        var path = request.uri.path;
        if (path == '/') path = '/mermaid_renderer.html';
        
        final safePath = p.join(rendererDir.path, path.startsWith('/') ? path.substring(1) : path);
        // Ensure path stays within rendererDir for security (basic check)
        if (!p.isWithin(rendererDir.path, safePath) && safePath != rendererDir.path) {
           request.response.statusCode = HttpStatus.forbidden;
           request.response.close();
           return;
        }

        final file = File(safePath);
        if (await file.exists()) {
          if (path.endsWith('.html')) {
             request.response.headers.contentType = ContentType.html;
          } else if (path.endsWith('.js')) {
             request.response.headers.contentType = ContentType.parse('application/javascript');
          }
          await file.openRead().pipe(request.response);
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.close();
        }
      });

      final url = 'http://127.0.0.1:${_server!.port}/';
      debugPrint('WebviewService: Serving at $url');

      // 5. Create Headless Webview
      _webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          title: "Mermaid Renderer (Headless)",
          windowWidth: 1, 
          windowHeight: 1,
          windowPosX: -10000, 
          windowPosY: -10000,
          titleBarTopPadding: 0, 
        ),
      );

      // 6. Launch URL
      debugPrint('WebviewService: Launching $url');
      _webview?.launch(url);

      _isInitialized = true;
      
      // Wait for READY
      await _webviewReadyCompleter!.future.timeout(
        const Duration(seconds: 10), 
        onTimeout: () {
          debugPrint('WebviewService: Timed out waiting for READY signal.');
          throw TimeoutException('Webview READY timeout');
        }
      );
      
    } catch (e) {
      debugPrint('WebviewService: Initialization failed: $e');
      dispose(); // Cleanup partial init
      rethrow;
    }
  }

  Future<String> renderMermaid(String content, Map<String, dynamic> config, {bool retry = true}) async {
    if (!_isInitialized) {
      await initialize();
    }

    _renderResultCompleter = Completer<String>();

    final configJson = jsonEncode(config);
    final escapedContent = jsonEncode(content);

    final jsCode = '''
      renderMermaid($escapedContent, $configJson)
        .then(svg => {
           send('SVG:' + encodeURIComponent(svg));
        })
        .catch(err => {
           send('ERROR:' + encodeURIComponent(err.toString()));
        });
      null;
    ''';
    
    try {
      await _webview?.evaluateJavaScript(jsCode);
      return await _renderResultCompleter!.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      debugPrint('WebviewService: Render timed out.');
      if (retry) {
        debugPrint('WebviewService: Retrying render (re-initializing)...');
        dispose();
        return renderMermaid(content, config, retry: false);
      }
      throw Exception('Mermaid rendering timed out.');
    } catch (e) {
      if (retry && (e.toString().contains('Webview') || e.toString().contains('closed'))) {
         debugPrint('WebviewService: Error caught ($e). Retrying...');
         dispose();
         return renderMermaid(content, config, retry: false);
      }
      rethrow;
    }
  }

  void dispose() {
    _server?.close(force: true);
    _webview?.close();
    _webview = null;
    _server = null;
    _isInitialized = false;
    _webviewReadyCompleter = null;
    debugPrint('WebviewService: Disposed.');
  }
}
