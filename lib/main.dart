import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart' as dom;
import 'package:nonton_plus/screens/MoviesDetail.dart';
import 'package:nonton_plus/screens/WebView.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: HtmlGridView(),
      ),
    );
  }
}

class HtmlGridView extends StatefulWidget {
  @override
  _HtmlGridViewState createState() => _HtmlGridViewState();
}

class _HtmlGridViewState extends State<HtmlGridView> {
  List<Map<String, String>> items = [];
  bool _isLoading = false;
  int _currentPage = 0;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchAndParseHtml();
  }

  Future<void> fetchAndParseHtml() async {
    final url = 'https://tv4.lk21official.mom/populer/page/$_currentPage/';
    final response = await http.get(Uri.parse(url));
    setState(() {
      _isLoading = true;
    });

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final divs = document.querySelectorAll('div.col-lg-2.col-sm-3.col-xs-4.page-$_currentPage.infscroll-item');

      List<Map<String, String>> extractedItems = divs.map((div) {
        final articleElement = div.querySelector('article.mega-item');
        final posterElement = articleElement?.querySelector('figure.grid-poster a');
        final imageElement = posterElement?.querySelector('img');
        final titleElement = articleElement?.querySelector('header.grid-header h1.grid-title a');
        final ratingElement = articleElement?.querySelector('div.grid-meta div.rating');
        final qualityElement = articleElement?.querySelector('div.grid-meta div.quality');
        final durationElement = articleElement?.querySelector('div.grid-meta div.duration');

        return {
          'title': titleElement?.text ?? '',
          'href': posterElement?.attributes['href'] ?? '',
          'image': imageElement?.attributes['src'] ?? '',
          'rating': ratingElement?.text ?? '',
          'quality': qualityElement?.text ?? '',
          'duration': durationElement?.text ?? '',
        };
      }).toList();

      setState(() {
        items.addAll(extractedItems);
        _isLoading = false;
      });
    } else {
      print('Failed to load HTML: ${response.statusCode}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
      _currentPage++;
      fetchAndParseHtml();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTML Grid View'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MoviesDetail(item['href'] ?? '')));
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Text(item['title'] ?? ''),
                        Text(item['rating'] ?? ''),
                        Text(item['quality'] ?? ''),
                        Text(item['duration'] ?? ''),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}