import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:admg_app/screens/bible/bible_book_page.dart';

class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  List<dynamic> _bibleContent = [];
  List<dynamic> _filteredContent = [];
  final TextEditingController _searchController = TextEditingController();

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
      // ignore: avoid_print
      print('Erro ao carregar o conteúdo da Bíblia: $e');
      // Tratar o erro, talvez mostrando uma mensagem ao usuário
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

      // Verifica se o nome do livro contém a consulta
      if (bookName.contains(lowerCaseQuery)) {
        return true;
      }

      // Verifica se algum versículo em qualquer capítulo contém a consulta
      final List<dynamic> chapters = book['chapters'];
      for (final chapter in chapters) {
        final List<dynamic> verses =
            chapter as List<dynamic>; // Cada capítulo é uma lista de versículos
        for (final verseText in verses) {
          if (verseText.toLowerCase().contains(lowerCaseQuery)) {
            return true; // Encontrou uma correspondência em um versículo, incluir este livro
          }
        }
      }
      return false; // Nenhuma correspondência encontrada no nome do livro ou em qualquer versículo
    }).toList();

    setState(() {
      _filteredContent = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bíblia ADMG'),
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
                        // Renderizar o conteúdo da Bíblia aqui
                        // Você precisará iterar sobre capítulos e versículos dentro de cada livro
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BibleBookPage(book: book),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book['name'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  // Placeholder para capítulos e versículos
                                  // Você precisará de outra ListView.builder ou similar para isso
                                  Text(
                                    'Capítulos: ${book['chapters'].length}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
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
