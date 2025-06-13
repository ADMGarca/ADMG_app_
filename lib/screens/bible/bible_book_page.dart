import 'package:flutter/material.dart';

class BibleBookPage extends StatelessWidget {
  final Map<String, dynamic> book;

  const BibleBookPage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book['name']),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA), // Light Cyan
              Color(0xFFBBDEFB), // Light Blue
            ],
          ),
        ),
        child: ListView.builder(
          itemCount: book['chapters'].length,
          itemBuilder: (context, chapterIndex) {
            final chapters = book['chapters'] as List<dynamic>;
            final verses = chapters[chapterIndex] as List<dynamic>;
            return Card(
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text(
                  'Capítulo ${chapterIndex + 1}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                children: verses.asMap().entries.map<Widget>((entry) {
                  int verseNum = entry.key + 1;
                  String verseText = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    child: Text(
                      '$verseNum. $verseText',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
