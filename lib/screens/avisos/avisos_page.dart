import 'dart:async';
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    carregarAvisos();
    _buscaController.addListener(() {
      filtrarAvisos(_buscaController.text);
    });
    // Inicia o timer para consultar a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      carregarAvisos();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela o timer
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
        // Ordena por status: "URGENTE" no topo
        avisos.sort((a, b) {
          final statusA = a['status']?.toString().toLowerCase() ?? 'normal';
          final statusB = b['status']?.toString().toLowerCase() ?? 'normal';
          if (statusA == 'urgente' && statusB != 'urgente') return -1;
          if (statusA != 'urgente' && statusB == 'urgente') return 1;
          return 0;
        });
        // Aplica o filtro de busca atual
        filtrarAvisos(_buscaController.text);
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