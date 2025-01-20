import 'dart:io'; // Importando o pacote para usar 'exit'
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Para fazer requisições HTTP
import 'dart:convert'; // Para manipular o JSON de resposta da API

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
                exit(0); // Encerra o aplicativo, agora com o import 'dart:io'
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

// Função para fazer requisição à API e carregar avisos
Future<List<Map<String, dynamic>>> carregarAvisos() async {
  try {
    final response = await http.get(Uri.parse('http://localhost:5001/api/avisos'));

    if (response.statusCode == 200) {
      // Converte a resposta para uma lista de mapas
      List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(json.decode(response.body));
      return result;
    } else {
      throw Exception('Falha ao carregar avisos');
    }
  } catch (e) {
    print('Erro ao carregar avisos: $e');
    throw e;
  }
}

// Tela de Avisos
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
    final response = await http.get(Uri.parse('http://localhost:5001/api/avisos'));

    if (response.statusCode == 200) {
      // Converte a resposta para uma lista de mapas
      List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(json.decode(response.body));
      setState(() {
        avisos = result;  // Agora você vai atualizar o estado com os dados recebidos
        carregando = false; // Alterar o carregamento para false
      });
    } else {
      throw Exception('Falha ao carregar avisos');
    }
  } catch (e) {
    print('Erro ao carregar avisos: $e');
    setState(() {
      carregando = false;  // Alterar o carregamento para false mesmo em caso de erro
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
              ? const Center(child: Text('Nenhum aviso disponível'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: avisos.first.keys.map((key) => DataColumn(label: Text(key))).toList(),
                    rows: avisos.map((aviso) {
                      return DataRow(
                        cells: aviso.entries.map((entry) {
                          if (entry.key == 'Importancia') {
                            return DataCell(
                              Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  color: entry.value == 'Urgente'
                                      ? Colors.red
                                      : entry.value == 'Importante'
                                          ? Colors.green
                                          : Colors.black,
                                ),
                              ),
                            );
                          } else {
                            return DataCell(Text(entry.value.toString()));
                          }
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}

// Tela de Pedidos de Oração
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
      List<Map<String, dynamic>> result = await carregarPedidosDaAPI();
      print("Dados recuperados da API: $result");

      setState(() {
        pedidos = result;
        carregando = false;
      });
    } catch (e) {
      print('Erro ao carregar pedidos de oração: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> carregarPedidosDaAPI() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5001/api/pedidos_oracao'));

      if (response.statusCode == 200) {
        // Converte a resposta para uma lista de mapas
        List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(json.decode(response.body));
        return result;
      } else {
        throw Exception('Falha ao carregar pedidos de oração');
      }
    } catch (e) {
      print('Erro ao carregar pedidos de oração: $e');
      throw e;
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
                    columns: pedidos.first.keys.map((key) => DataColumn(label: Text(key))).toList(),
                    rows: pedidos.map((pedido) {
                      return DataRow(
                        cells: pedido.entries.map((entry) {
                          return DataCell(Text(entry.value.toString()));
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back),
      ),
    );
  }
}
