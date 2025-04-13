import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/date_formatter.dart';

class GerenciarAvisosPage extends StatefulWidget {
  const GerenciarAvisosPage({super.key});

  @override
  _GerenciarAvisosPageState createState() => _GerenciarAvisosPageState();
}

class _GerenciarAvisosPageState extends State<GerenciarAvisosPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> avisos = [];
  bool carregando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    carregarAvisos();
    // Consulta o banco a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      carregarAvisos();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
        avisos.sort((a, b) {
          final statusA = a['status']?.toString().toLowerCase() ?? 'normal';
          final statusB = b['status']?.toString().toLowerCase() ?? 'normal';
          if (statusA == 'urgente' && statusB != 'urgente') return -1;
          if (statusA != 'urgente' && statusB == 'urgente') return 1;
          return 0;
        });
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar avisos: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void _mostrarDialogoAdicionarAviso() {
    final TextEditingController descricaoController = TextEditingController();
    String statusSelecionado = 'NORMAL';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Adicionar Aviso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descricaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: statusSelecionado,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: ['URGENTE', 'NORMAL'].map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                statusSelecionado = value ?? 'NORMAL';
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              final descricao = descricaoController.text.trim();
              if (descricao.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A descrição não pode estar vazia')),
                );
                return;
              }

              try {
                await supabase.from('aviso').insert({
                  'data': DateTime.now().toIso8601String(),
                  'descricao': descricao,
                  'status': statusSelecionado,
                });
                Navigator.pop(context);
                carregarAvisos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aviso adicionado com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao adicionar aviso: $e')),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _excluirAviso(int id) async {
    try {
      await supabase.from('aviso').delete().eq('id', id);
      carregarAvisos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aviso excluído com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir aviso: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Avisos'),
        centerTitle: true,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : avisos.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum aviso encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: avisos.length,
                  itemBuilder: (context, index) {
                    final aviso = avisos[index];
                    final id = aviso['id']?.toString() ?? '';
                    final data = aviso['data']?.toString() ?? '';
                    final descricao = aviso['descricao']?.toString() ?? '';
                    final status = aviso['status']?.toString() ?? 'Normal';
                    final isUrgente = status.toLowerCase() == 'urgente';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isUrgente
                              ? const BorderSide(color: Colors.red, width: 2)
                              : BorderSide.none,
                        ),
                        color: isUrgente ? const Color(0xFFFFE6E6) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'ID: $id - ${formatarData(data)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isUrgente ? Colors.red : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      descricao,
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
                                onPressed: () => _excluirAviso(int.parse(id)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdicionarAviso,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}