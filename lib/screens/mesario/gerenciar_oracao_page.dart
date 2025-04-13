import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/date_formatter.dart';

class GerenciarOracaoPage extends StatefulWidget {
  const GerenciarOracaoPage({super.key});

  @override
  _GerenciarOracaoPageState createState() => _GerenciarOracaoPageState();
}

class _GerenciarOracaoPageState extends State<GerenciarOracaoPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pedidos = [];
  bool carregando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    carregarPedidos();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      carregarPedidos();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> carregarPedidos() async {
    try {
      final response = await supabase
          .from('pedidodeoracao')
          .select()
          .order('data', ascending: false);

      setState(() {
        pedidos = List<Map<String, dynamic>>.from(response);
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar pedidos: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void _mostrarDialogoAdicionarPedido() {
    final TextEditingController descricaoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Adicionar Pedido de Oração'),
        content: TextField(
          controller: descricaoController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descrição',
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
              final descricao = descricaoController.text.trim();
              if (descricao.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A descrição não pode estar vazia')),
                );
                return;
              }

              try {
                await supabase.from('pedidodeoracao').insert({
                  'data': DateTime.now().toIso8601String(),
                  'descricao': descricao,
                });
                Navigator.pop(context);
                carregarPedidos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pedido adicionado com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao adicionar pedido: $e')),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _excluirPedido(int id) async {
    try {
      await supabase.from('pedidodeoracao').delete().eq('id', id);
      carregarPedidos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido excluído com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir pedido: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Pedidos de Oração'),
        centerTitle: true,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : pedidos.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum pedido encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final id = pedido['id']?.toString() ?? '';
                    final data = pedido['data']?.toString() ?? '';
                    final descricao = pedido['descricao']?.toString() ?? '';

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
                                onPressed: () => _excluirPedido(int.parse(id)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoAdicionarPedido,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}