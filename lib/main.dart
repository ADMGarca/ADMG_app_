import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADMG App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADMG - Início')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AvisosPage()),
                );
              },
              child: const Text('Avisos'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PedidoOracaoPage()),
                );
              },
              child: const Text('Pedido de Oração'),
            ),
            ElevatedButton(
              onPressed: () {
                exit(0);
              },
              child: const Text('Sair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela de Avisos
class AvisosPage extends StatefulWidget {
  const AvisosPage({super.key});

  @override
  _AvisosPageState createState() => _AvisosPageState();
}

class _AvisosPageState extends State<AvisosPage> {
  List<Map<String, dynamic>> avisos = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarAvisos();
  }

  Future<void> carregarAvisos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.15.22:5001/api/avisos'));
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() {
          avisos = result;
          carregando = false;
        });
      } else {
        throw Exception('Falha ao carregar avisos');
      }
    } catch (e) {
      print('Erro ao carregar avisos: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : avisos.isEmpty
              ? const Center(child: Text('Nenhum Aviso disponível'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Data')),
                      DataColumn(label: Text('Importância')),
                      DataColumn(label: Text('Descrição')),
                    ],
                    rows: avisos.map((aviso) {
                      final importancia = aviso['status'] ?? 'Normal';
                      final data = aviso['data'] ?? '';
                      final descricao = aviso['descricao'] ?? '';

                      return DataRow(
                        cells: [
                          DataCell(Text(data)),
                          DataCell(
                            Text(
                              importancia,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: importancia == 'Urgente' ? Colors.red : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              descricao,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Aumentando o tamanho da fonte
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            carregando = true;
          });
          carregarAvisos(); // Atualiza as informações
        },
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

/// Tela de Pedidos de Oração
class PedidoOracaoPage extends StatefulWidget {
  const PedidoOracaoPage({super.key});

  @override
  _PedidoOracaoPageState createState() => _PedidoOracaoPageState();
}

class _PedidoOracaoPageState extends State<PedidoOracaoPage> {
  List<Map<String, dynamic>> pedidos = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarPedidos();
  }

  Future<void> carregarPedidos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.15.22:5001/api/pedidos'));
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() {
          pedidos = result;
          carregando = false;
        });
      } else {
        throw Exception('Falha ao carregar pedidos de oração');
      }
    } catch (e) {
      print('Erro ao carregar pedidos de oração: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedido de Oração')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : pedidos.isEmpty
              ? const Center(child: Text('Nenhum pedido disponível'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Data')),
                      DataColumn(label: Text('Descrição')),
                    ],
                    rows: pedidos.map((pedido) {
                      final data = pedido['data'] ?? '';
                      final descricao = pedido['descricao'] ?? '';

                      return DataRow(
                        cells: [
                          DataCell(Text(data)),
                          DataCell(
                            Text(
                              descricao,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Aumentando o tamanho da fonte
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            carregando = true;
          });
          carregarPedidos(); // Atualiza as informações
        },
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
