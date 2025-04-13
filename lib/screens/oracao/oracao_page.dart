import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'oracao_table.dart';
import '../../utils/date_formatter.dart';

class PedidoOracaoPage extends StatefulWidget {
  const PedidoOracaoPage({super.key});

  @override
  _PedidoOracaoPageState createState() => _PedidoOracaoPageState();
}

class _PedidoOracaoPageState extends State<PedidoOracaoPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pedidos = [];
  List<Map<String, dynamic>> pedidosFiltrados = [];
  bool carregando = true;
  final TextEditingController _buscaController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    carregarPedidos();
    _buscaController.addListener(() {
      filtrarPedidos(_buscaController.text);
    });
    // Inicia o timer para consultar a cada 5 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      carregarPedidos();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela o timer
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> carregarPedidos() async {
    try {
      final response = await supabase
          .from('pedidodeoracao')
          .select()
          .order('data', ascending: false);

      if (response != null && response.isNotEmpty) {
        setState(() {
          pedidos = List<Map<String, dynamic>>.from(response);
          // Aplica o filtro de busca atual
          filtrarPedidos(_buscaController.text);
          carregando = false;
        });
      } else {
        setState(() {
          carregando = false;
          pedidos = [];
          pedidosFiltrados = [];
        });
      }
    } catch (e) {
      print('Erro ao carregar pedidos: $e');
      setState(() {
        carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedidos: ${e.toString()}')),
      );
    }
  }

  void filtrarPedidos(String textoBusca) {
    setState(() {
      if (textoBusca.isEmpty) {
        pedidosFiltrados = pedidos;
      } else {
        pedidosFiltrados = pedidos.where((pedido) {
          final descricao = pedido['descricao']?.toString().toLowerCase() ?? '';
          return descricao.contains(textoBusca.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido de Oração'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _buscaController,
              decoration: const InputDecoration(
                labelText: 'Buscar Pedidos',
                prefixIcon: Icon(Icons.search, size: 28),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator())
                : pedidosFiltrados.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum pedido encontrado',
                          style: TextStyle(fontSize: 18, color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: carregarPedidos,
                        child: SingleChildScrollView(
                          child: OracaoTable(pedidos: pedidosFiltrados),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => carregando = true);
          carregarPedidos();
        },
        child: const Icon(Icons.refresh, size: 28),
      ),
    );
  }
}