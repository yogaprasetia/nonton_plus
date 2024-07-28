import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:nonton_plus/screens/WebView.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MoviesDetail extends StatefulWidget {
  final String url;
  const MoviesDetail(this.url);
  @override
  _MoviesDetailState createState() => _MoviesDetailState();
}

class _MoviesDetailState extends State<MoviesDetail> {
  String iframeSrc = '';

  @override
  void initState() {
    super.initState();
    fetchAndParseHtml();
  }

  Future<void> fetchAndParseHtml() async {
    final response = await http.get(Uri.parse(widget.url));

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final iframeElement = document.querySelector('#loadPlayer iframe');

      setState(() {
        iframeSrc = iframeElement?.attributes['src'] ?? '';
      });

      print('Iframe src: $iframeSrc');
    } else {
      print('Failed to load HTML');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movies Detail'),
      ),
      body: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Webview(
                initialUrl: iframeSrc,
              ),
            ),
          );
        },
        child: Text('Watch Movie'),
      ),
    );
  }
}