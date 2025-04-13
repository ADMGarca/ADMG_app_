import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'avisos_table.dart';
import '../../utils/date_formatter.dart';

class AvisosPage extends StatefulWidget {
  const AvisosPage({super.key});

  @override
  _AvisosPageState createState() => _AvisosPageState();
}

class _AvisosPageState extends State<AvisosPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> avisos = [];
  List<Map<String, dynamic>> avisosFiltrados = [];
  bool carregando = true;
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarAvisos();
    // Adiciona um listener para atualizar os resultados conforme o usuário digita
    _buscaController.addListener(() {
      filtrarAvisos(_buscaController.text);
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> carregarAvisos() async {
    try {
      final response = await supabase
          .from('aviso')
          .select()
          .order('data', ascending: false);

      setState(() {
        avisos = List<Map<String, dynamic>>.from(response);
        avisosFiltrados = avisos;
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar avisos: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void filtrarAvisos(String textoBusca) {
    setState(() {
      if (textoBusca.isEmpty) {
        avisosFiltrados = avisos;
      } else {
        avisosFiltrados = avisos.where((aviso) {
          final descricao = aviso['descricao']?.toString().toLowerCase() ?? '';
          return descricao.contains(textoBusca.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                labelText: 'Buscar Avisos',
                prefixIcon: Icon(Icons.search, size: 28),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : avisosFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum aviso encontrado',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      )
                    : SingleChildScrollView(
                        child: AvisosTable(avisos: avisosFiltrados),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            carregando = true;
          });
          carregarAvisos();
        },
        child: const Icon(Icons.refresh, size: 28),
      ),
    );
  }
}