import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';

class Webview extends StatefulWidget {
  final String initialUrl;
  const Webview({required this.initialUrl});
  @override
  _WebviewState createState() => _WebviewState();
}

class _WebviewState extends State<Webview> {
  late final WebViewController controller;
  late Future<List<String>> adUrlsFuture;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    adUrlsFuture = _loadAdUrls();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    controller = WebViewController()
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) async {
          setState(() {
            isLoading = true;
          });

          await Future.delayed(const Duration(milliseconds: 500));

          await controller.runJavaScriptReturningResult(
              "document.getElementById('admad')?.remove();");
        },
        onProgress: (progress) {
          setState(() {
            isLoading = true;
          });
        },
        onPageFinished: (String url) {
          setState(() {
            isLoading = false;
          });
        },

        onNavigationRequest: (NavigationRequest request) async {
        List<String> adUrls = await adUrlsFuture;
        if (adUrls.any((adUrl) => request.url.contains(adUrl))) {
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      ))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(widget.initialUrl),
      );
  }
  Future<List<String>> _loadAdUrls() async {
    final String contents = await rootBundle.loadString('assets/txt/easylist.txt');
    return contents.split('\n').where((line) => line.isNotEmpty).toList();
  }

@override
void dispose() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(
            controller: controller,
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
