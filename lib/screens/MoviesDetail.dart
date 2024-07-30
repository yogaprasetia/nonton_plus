import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:nonton_plus/screens/WebView.dart';

class MoviesDetail extends StatefulWidget {
  final String url;
  final String image;
  final String title;
  const MoviesDetail(this.url, this.image, this.title);
  @override
  _MoviesDetailState createState() => _MoviesDetailState();
}

class _MoviesDetailState extends State<MoviesDetail> {
  String iframeSrc = '';
  String sinopsis = '';

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
      final sinopsisElement = document.querySelector('blockquote');

      sinopsisElement!.querySelectorAll('strong, a, .hidden').forEach((element) {
      element.remove();
    });
    final rawSinopsisHtml = sinopsisElement.innerHtml.replaceAll(RegExp(r'<br\s*/?>'), ' ');
    final cleanedSinopsis = rawSinopsisHtml.trim().replaceAll(RegExp(r'\s+'), ' ');

    setState(() {
      iframeSrc = iframeElement?.attributes['src'] ?? '';
      sinopsis = cleanedSinopsis;
    });
    } else {
      print('Failed to load HTML');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f4f4),
      appBar: AppBar(
        backgroundColor: const Color(0xfff4f4f4),
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 20,
        ),
        child: Column(
          children: <Widget>[
            Center(
              child: Card(
                elevation: 5,
                child: Hero(
                  tag: 1,
                  child: Container(
                    height: 450,
                    width: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(
                          widget.image,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            ),
             Text(
              sinopsis,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
      bottomNavigationBar: Row(
        children: <Widget>[
          Expanded(
              child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Webview(initialUrl: iframeSrc,),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(
                  'Tonton',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
