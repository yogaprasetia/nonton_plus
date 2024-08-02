import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:nonton_plus/screens/WebView.dart';

class SeriesDetail extends StatefulWidget {
  final String url;
  final String image;
  final String title;
  const SeriesDetail(this.url, this.image, this.title);
  @override
  _SeriesDetailState createState() => _SeriesDetailState();
}

class _SeriesDetailState extends State<SeriesDetail> {
  String iframeSrc = '';
  String sinopsis = '';
  List<String> seasons = [];
  List<Map<String, List<String>>> episodesPerSeason = [];
  int selectedSeasonIndex = 0;
  String? selectedEpisodeUrl;
  String selectedEpisodeTitle = 'Pilih Episode';
  int indexLur = 1;

  @override
  void initState() {
    super.initState();
    fetchAndParseHtml();
  }

  Future<void> fetchAndParseHtml([String? episodeUrl]) async {
    final url = episodeUrl ?? widget.url;
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = parse(response.body);
      final iframeElement = document.querySelector('#loadPlayer iframe');
      final sinopsisElement = document.querySelector('blockquote');
      final seasonElements = document.querySelectorAll('.season-list');

      seasons.clear();
      episodesPerSeason.clear();

      for (var seasonElement in seasonElements) {
  final seasonTitle = seasonElement.querySelector('h4')?.text.trim();
  if (seasonTitle != null) {
    seasons.add(seasonTitle);
    var episodeListElement = seasonElement.nextElementSibling;
    if (episodeListElement != null &&
        episodeListElement.classes.contains('episode-list')) {
      final episodeLinks = episodeListElement.querySelectorAll('a.btn.btn-primary');
      List<String> episodes = episodeLinks
          .map((link) => link.attributes['href'] ?? '')
          .toList()
          .reversed
          .toList();
      List<String> titleEpisode = episodeLinks
          .map((link) => link.text)
          .toList()
          .reversed
          .toList();
      episodesPerSeason.add({
        'episodes': episodes,
        'titleEpisode': titleEpisode,
      });
    } else {
      episodesPerSeason.add({
        'episodes': [],
        'titleEpisode': [],
      });
    }
  }
}

      sinopsisElement
          ?.querySelectorAll('strong, a, .hidden')
          .forEach((element) {
        element.remove();
      });
      final rawSinopsisHtml =
          sinopsisElement?.innerHtml.replaceAll(RegExp(r'<br\s*/?>'), ' ') ??
              '';
      final cleanedSinopsis =
          rawSinopsisHtml.trim().replaceAll(RegExp(r'\s+'), ' ');

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
    if (episodesPerSeason.isNotEmpty &&
    episodesPerSeason[selectedSeasonIndex]['episodes'] != null &&
    episodesPerSeason[selectedSeasonIndex]['episodes']!.isNotEmpty &&
    !episodesPerSeason[selectedSeasonIndex]['episodes']!.contains(selectedEpisodeUrl)) {
  selectedEpisodeUrl = episodesPerSeason[selectedSeasonIndex]['episodes']![0];
}
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
            if (seasons.isNotEmpty)
              DropdownButton<String>(
                value: seasons.length > selectedSeasonIndex
                    ? seasons[selectedSeasonIndex]
                    : null,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSeasonIndex = seasons.indexOf(newValue!);
                    selectedEpisodeUrl = null;
                  });
                },
                items: seasons.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            if (episodesPerSeason.isNotEmpty &&
                episodesPerSeason[selectedSeasonIndex].isNotEmpty)
               DropdownButton<String>(
    value: selectedEpisodeUrl,
    onChanged: (String? newValue) {
  if (newValue != null) {
    // Cari judul episode yang sesuai berdasarkan URL yang dipilih
    int selectedEpisodeIndex = episodesPerSeason[selectedSeasonIndex]['episodes']!.indexOf(newValue);
    String newSelectedEpisodeTitle = episodesPerSeason[selectedSeasonIndex]['titleEpisode']![selectedEpisodeIndex];

    setState(() {
      selectedEpisodeUrl = newValue;
      selectedEpisodeTitle = newSelectedEpisodeTitle;
    });

    fetchAndParseHtml(newValue);
  }
},
    items: episodesPerSeason[selectedSeasonIndex]['episodes']!
      .asMap()
      .entries
      .map<DropdownMenuItem<String>>((entry) {
        int idx = entry.key;
        String episodeUrl = entry.value;
        String title = episodesPerSeason[selectedSeasonIndex]['titleEpisode']![idx];
        return DropdownMenuItem<String>(
          value: episodeUrl,
          child: Text(title),
        );
      }).toList(),
  selectedItemBuilder: (BuildContext context) {
    return episodesPerSeason[selectedSeasonIndex]['episodes']!
        .asMap()
        .entries
        .map<Widget>((entry) {
          String title = selectedEpisodeTitle;
          return Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        }).toList();
  },
  ),
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
              onPressed: selectedEpisodeUrl != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Webview(
                            initialUrl: iframeSrc,
                          ),
                        ),
                      );
                    }
                  : null,
              child: const Text(
                'Tonton',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
