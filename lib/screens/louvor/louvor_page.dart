import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'louvor_table.dart';
import '../../utils/date_formatter.dart';

class LouvorPage extends StatefulWidget {
  const LouvorPage({super.key});

  @override
  _LouvorPageState createState() => _LouvorPageState();
}

class _LouvorPageState extends State<LouvorPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> louvores = [];
  List<Map<String, dynamic>> louvoresFiltrados = [];
  bool carregando = true;
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarLouvores();
    _buscaController.addListener(() {
      filtrarLouvores(_buscaController.text);
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> carregarLouvores() async {
    try {
      final response = await supabase
          .from('louvor')
          .select()
          .order('data', ascending: false);

      setState(() {
        louvores = List<Map<String, dynamic>>.from(response);
        louvoresFiltrados = louvores;
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar louvores: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void filtrarLouvores(String textoBusca) {
    setState(() {
      if (textoBusca.isEmpty) {
        louvoresFiltrados = louvores;
      } else {
        louvoresFiltrados = louvores.where((louvor) {
          final textoLouvor = louvor['louvor_']?.toString().toLowerCase() ?? '';
          return textoLouvor.contains(textoBusca.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Louvores'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                labelText: 'Buscar Louvores',
                prefixIcon: Icon(Icons.search, size: 28),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : louvoresFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum louvor encontrado',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      )
                    : SingleChildScrollView(
                        child: LouvorTable(louvores: louvoresFiltrados),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            carregando = true;
          });
          carregarLouvores();
        },
        child: const Icon(Icons.refresh, size: 28),
      ),
    );
  }
}