
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class BibleSharePage extends StatefulWidget {
  const BibleSharePage({super.key});

  @override
  State<BibleSharePage> createState() => _BibleSharePageState();
}

class _BibleSharePageState extends State<BibleSharePage> {
  bool _compartilhando = false;
  String? _versoGrifadoId;
  List<dynamic> _bibleContent = [];
  List<dynamic> _filteredContent = [];
  final TextEditingController _searchController = TextEditingController();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadBibleContent();
  }

  Future<void> _loadBibleContent() async {
    try {
      final String response =
          await rootBundle.loadString('assets/assets/biblia/ACF.json');
      final data = await json.decode(response);
      setState(() {
        _bibleContent = data;
        _filteredContent = data;
      });
    } catch (e) {
      print('Erro ao carregar o conteúdo da Bíblia: $e');
    }
  }

  void _filterContent(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContent = _bibleContent;
      });
      return;
    }
    final String lowerCaseQuery = query.toLowerCase();
    final List<dynamic> results = _bibleContent.where((book) {
      final String bookName = book['name'].toLowerCase();
      if (bookName.contains(lowerCaseQuery)) {
        return true;
      }
      final List<dynamic> chapters = book['chapters'];
      for (final chapter in chapters) {
        final List<dynamic> verses = chapter as List<dynamic>;
        for (final verseText in verses) {
          if (verseText.toLowerCase().contains(lowerCaseQuery)) {
            return true;
          }
        }
      }
      return false;
    }).toList();
    setState(() {
      _filteredContent = results;
    });
  }

  void _onShareVerse(Map<String, dynamic> book, int chapter, int verse, String text) async {
    final versoId = '${book['name']}:${chapter}_$verse';
    setState(() {
      _versoGrifadoId = versoId;
    });
    if (_compartilhando) {
      await supabase.from('leitura_atual').upsert({
        'id': 1,
        'livro': book['name'],
        'capitulo': chapter,
        'versiculo': verse,
        'texto': text,
        'verso_id': versoId,
        'atualizado_em': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Versículo compartilhado com sucesso!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compartilhar Palavra'),
        centerTitle: true,
        actions: [
          Row(
            children: [
              const Text('Compartilhar', style: TextStyle(fontSize: 16)),
              Switch(
                value: _compartilhando,
                onChanged: (v) {
                  setState(() {
                    _compartilhando = v;
                  });
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA),
              Color(0xFFBBDEFB),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterContent,
                decoration: InputDecoration(
                  labelText: 'Pesquisar na Bíblia',
                  hintText: 'Digite para pesquisar palavras ou livros...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _bibleContent.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredContent.length,
                      itemBuilder: (context, index) {
                        final book = _filteredContent[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              book['name'],
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            children: (book['chapters'] as List<dynamic>).asMap().entries.map<Widget>((chapterEntry) {
                              int chapterIndex = chapterEntry.key;
                              List<dynamic> verses = chapterEntry.value as List<dynamic>;
                              return ExpansionTile(
                                title: Text('Capítulo ${chapterIndex + 1}'),
                                children: verses.asMap().entries.map<Widget>((verseEntry) {
                                  int verseIndex = verseEntry.key;
                                  String verseText = verseEntry.value;
                                  final versoId = '${book['name']}:${chapterIndex + 1}_${verseIndex + 1}';
                                  final grifado = _versoGrifadoId == versoId;
                                  return ListTile(
                                    title: Text(
                                      '${verseIndex + 1}. $verseText',
                                      style: grifado
                                          ? const TextStyle(
                                              backgroundColor: Colors.yellow,
                                              fontWeight: FontWeight.bold,
                                            )
                                          : null,
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.share, color: _compartilhando ? Colors.green : Colors.blue),
                                      tooltip: _compartilhando ? 'Compartilhar este versículo' : 'Ative o compartilhamento',
                                      onPressed: () => _onShareVerse(
                                        book,
                                        chapterIndex + 1,
                                        verseIndex + 1,
                                        verseText,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
