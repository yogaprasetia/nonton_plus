import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:nonton_plus/screens/MoviesDetail.dart';
import 'package:nonton_plus/screens/SeriesDetail.dart';

class AllMovies extends StatefulWidget {
  @override
  _AllMoviesState createState() => _AllMoviesState();
}

class _AllMoviesState extends State<AllMovies> {
  List<Map<String, String>> items = [];
  bool _isLoading = false;
  int _currentPage = 1;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _currentPage = 1;
        items.clear();
        fetchAndParseHtml();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchAndParseHtml();
  }

  Future<void> fetchAndParseHtml() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String url = _searchQuery.isEmpty
        ? 'https://tv4.lk21official.mom/latest/page/$_currentPage/'
        : 'https://tv4.lk21official.mom/search.php?s=$_searchQuery';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = parse(response.body);
      List<Map<String, String>> extractedItems = [];

      if (_searchQuery.isEmpty) {
        final currentPageSelector =
            _currentPage == 1 ? '0' : _currentPage.toString();
        final divs = document.querySelectorAll(
            'div.col-lg-2.col-sm-3.col-xs-4.page-$currentPageSelector.infscroll-item');
        extractedItems = divs.map((div) {
          final articleElement = div.querySelector('article.mega-item');
          final posterElement =
              articleElement?.querySelector('figure.grid-poster a');
          final imageElement = posterElement?.querySelector('img');
          final titleElement = articleElement
              ?.querySelector('header.grid-header h1.grid-title a');
          final ratingElement =
              articleElement?.querySelector('div.grid-meta div.rating');
          final qualityElement =
              articleElement?.querySelector('div.grid-meta div.quality');
          final durationElement =
              articleElement?.querySelector('div.grid-meta div.duration');
          return {
            'title': titleElement?.text ?? '',
            'href': posterElement?.attributes['href'] ?? '',
            'image':
                imageElement?.attributes['src']?.startsWith('http') ?? false
                    ? imageElement!.attributes['src']!
                    : 'http:${imageElement!.attributes['src']}',
            'rating': ratingElement?.text ?? '',
            'quality': qualityElement?.text ?? '',
            'duration': durationElement?.text ?? '',
          };
        }).toList();
      } else {
        final searchItems = document.querySelectorAll('div.search-item');
        extractedItems = List.castFrom<dynamic, Map<String, String>>(searchItems
            .map((div) {
              final posterElement =
                  div.querySelector('div.search-poster a[rel="bookmark"]');
              final imageElement = posterElement?.querySelector('img');
              final titleElement =
                  div.querySelector('div.search-content h3 a[rel="bookmark"]');

              if (titleElement?.text.contains("Daftar Film") == true) {
                return null;
              }
              final detailsElements =
                  div.querySelectorAll('div.search-content p');
              Map<String, String> details = {};
              for (var element in detailsElements) {
                final split = element.text.split(':');
                if (split.length > 1) {
                  final key = split[0].trim();
                  final value = split.sublist(1).join(':').trim();
                  details[key] = value;
                }
              }
              return {
                'title': titleElement?.text ?? '',
                'href': titleElement!.text.contains('- Series')
                    ? 'https://tv13.nontondrama.click/${posterElement?.attributes['href']}'
                    : 'https://tv4.lk21official.mom/${posterElement?.attributes['href']}',
                'image':
                    'https://tv4.lk21official.mom/${imageElement?.attributes['src']}',
                'details': details.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join(', '),
              };
            })
            .where((item) => item != null)
            .toList());
      }

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
    _currentPage++;
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoading) {
      _currentPage++;
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
        title: !_isSearching
            ? const Text('Nonton Plus')
            : TextField(
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: "Masukkan Pencarian...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _currentPage = 1;
                  items.clear();
                  fetchAndParseHtml();
                },
              ),
        actions: <Widget>[
          IconButton(
            icon: Icon(_isSearching ? Icons.cancel : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 3 / 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final item = items[index];
                return GestureDetector(
                  onTap: () {
                    bool isSeries =
                        item['title']?.contains('- Series') ?? false;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => isSeries
                            ? SeriesDetail(item['href'] ?? '',
                                item['image'] ?? '', item['title'] ?? '')
                            : MoviesDetail(item['href'] ?? '',
                                item['image'] ?? '', item['title'] ?? ''),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
                          Image.network(item['image'] ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              color: Colors.black.withOpacity(0.5),
                              child: Text(item['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: fetchAndParseHtml,
                      child: const Text('Load More..'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
