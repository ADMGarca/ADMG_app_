import 'package:flutter/material.dart';

class BibleBookPage extends StatefulWidget {
  final Map<String, dynamic> book;

  const BibleBookPage({super.key, required this.book});

  @override
  State<BibleBookPage> createState() => _BibleBookPageState();
}

class _BibleBookPageState extends State<BibleBookPage> {
  final Set<String> _selectedVerses =
      {}; // Conjunto para armazenar versículos selecionados

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book['name']),
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
          itemCount: widget.book['chapters'].length,
          itemBuilder: (context, chapterIndex) {
            final chapters = widget.book['chapters'] as List<dynamic>;
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
                  String verseId =
                      '${chapterIndex + 1}-$verseNum'; // ID único para o versículo
                  bool isSelected = _selectedVerses.contains(verseId);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedVerses.remove(verseId);
                        } else {
                          _selectedVerses.add(verseId);
                        }
                      });
                    },
                    child: Container(
                      color: isSelected
                          ? Colors.yellow.withOpacity(0.3)
                          : Colors.transparent, // Cor de destaque
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 4.0),
                      child: Text(
                        '$verseNum. $verseText',
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
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
