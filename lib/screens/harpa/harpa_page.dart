import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:admg_app/screens/harpa/harpa_hymn_page.dart'; // Importar a página do hino da Harpa

class HarpaPage extends StatefulWidget {
  const HarpaPage({super.key});

  @override
  State<HarpaPage> createState() => _HarpaPageState();
}

class _HarpaPageState extends State<HarpaPage> {
  List<Map<String, dynamic>> _harpaContent = [];
  List<Map<String, dynamic>> _filteredContent = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHarpaContent();
  }

  Future<void> _loadHarpaContent() async {
    try {
      final String response = await rootBundle
          .loadString('assets/assets/harpa/harpa_crista_640_hinos.json');
      final Map<String, dynamic> data = await json.decode(response);
      setState(() {
        _harpaContent = data.values
            .where((value) =>
                value is Map<String, dynamic> && value.containsKey('hino'))
            .toList()
            .cast<Map<String, dynamic>>();
        _filteredContent = _harpaContent;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Erro ao carregar o conteúdo da Harpa: $e');
      // Tratar o erro, talvez mostrando uma mensagem ao usuário
    }
  }

  void _filterContent(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContent = _harpaContent;
      });
      return;
    }

    final String lowerCaseQuery = query.toLowerCase();
    final List<Map<String, dynamic>> results = _harpaContent.where((hymn) {
      final String hymnNumberAndTitle = hymn['hino'].toString().toLowerCase();
      final String hymnCorus = hymn['coro']?.toLowerCase() ?? '';
      final String hymnVerses =
          hymn['verses']?.values.join(' ').toLowerCase() ?? '';

      return hymnNumberAndTitle.contains(lowerCaseQuery) ||
          hymnCorus.contains(lowerCaseQuery) ||
          hymnVerses.contains(lowerCaseQuery);
    }).toList();

    setState(() {
      _filteredContent = results.cast<Map<String, dynamic>>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harpa Cristã ADMG'),
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
                  labelText: 'Pesquisar hino',
                  hintText: 'Digite o número ou o título do hino...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _harpaContent.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredContent.length,
                      itemBuilder: (context, index) {
                        final hymn = _filteredContent[index];
                        // Renderizar o conteúdo da Harpa aqui
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
                                      HarpaHymnPage(hymn: hymn),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hymn['hino'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    hymn['hino'],
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
