import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/date_formatter.dart';

class GerenciarLouvorPage extends StatefulWidget {
  const GerenciarLouvorPage({super.key});

  @override
  _GerenciarLouvorPageState createState() => _GerenciarLouvorPageState();
}

class _GerenciarLouvorPageState extends State<GerenciarLouvorPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> louvores = [];
  bool carregando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    carregarLouvores();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      carregarLouvores();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar louvores: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void _mostrarDialogoAdicionarLouvor() {
    final TextEditingController louvorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Adicionar Louvor'),
        content: TextField(
          controller: louvorController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Texto do Louvor',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final louvor = louvorController.text.trim();
              if (louvor.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('O texto do louvor não pode estar vazio')),
                );
                return;
              }

              try {
                await supabase.from('louvor').insert({
                  'data': DateTime.now().toIso8601String(),
                  'louvor_': louvor,
                });
                Navigator.pop(context);
                carregarLouvores();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Louvor adicionado com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao adicionar louvor: $e')),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _excluirLouvor(int id) async {
    try {
      await supabase.from('louvor').delete().eq('id', id);
      carregarLouvores();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Louvor excluído com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir louvor: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Louvores'),
        centerTitle: true,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : louvores.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum louvor encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: louvores.length,
                  itemBuilder: (context, index) {
                    final louvor = louvores[index];
                    final id = louvor['id']?.toString() ?? '';
                    final data = louvor['data']?.toString() ?? '';
                    final textoLouvor = louvor['louvor_']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatarData(data),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      textoLouvor,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _excluirLouvor(int.parse(id)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdicionarLouvor,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}