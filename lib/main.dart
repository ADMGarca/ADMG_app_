import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

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

  String formatarData(String data) {
    try {
      final dateTime = DateTime.parse(data);
      final format = DateFormat('dd/MM/yyyy HH:mm');
      return format.format(dateTime);
    } catch (e) {
      return data;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADMG - Início')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AvisosPage()),
                  );
                },
                child: const Text('Avisos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PedidoOracaoPage()),
                  );
                },
                child: const Text('Pedido de Oração'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 144, 119, 240),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  exit(0);
                },
                child: const Text('Sair'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AvisosPage extends StatefulWidget {
  const AvisosPage({super.key});

  @override
  _AvisosPageState createState() => _AvisosPageState();
}

class _AvisosPageState extends State<AvisosPage> {
  List<Map<String, dynamic>> avisos = [];
  List<Map<String, dynamic>> avisosFiltrados = [];
  bool carregando = true;
  String busca = '';

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
          avisosFiltrados = result;
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

  void filtrarAvisos(String textoBusca) {
    setState(() {
      busca = textoBusca;
      avisosFiltrados = avisos
          .where((aviso) => aviso['descricao'].toLowerCase().contains(textoBusca.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar Avisos',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: filtrarAvisos,
                  ),
                ),
                Expanded(
                  child: avisosFiltrados.isEmpty
                      ? const Center(child: Text('Nenhum aviso encontrado'))
                      : SingleChildScrollView(
                          child: PaginaDeAvisos(avisos: avisosFiltrados),
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
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class PaginaDeAvisos extends StatelessWidget {
  const PaginaDeAvisos({super.key, required this.avisos});

  final List<Map<String, dynamic>> avisos;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 20, // Adicionado para expandir as colunas
        columns: const [
          DataColumn(
            label: Text(
              'Data',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey,fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              'Importância',
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              'Descrição',
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
            ),
          ),
        ],
        rows: avisos.map((aviso) {
          final importancia = aviso['status'] ?? 'Normal';
          final data = aviso['data'] ?? '';
          final descricao = aviso['descricao'] ?? '';

          return DataRow(
            cells: [
              DataCell(
                Text(
                  HomePage().formatarData(data),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
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
                SizedBox(
                  width: 600, // Adicionado largura maior para "Descrição"
                  child: SelectableText(
                    descricao,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class PedidoOracaoPage extends StatefulWidget {
  const PedidoOracaoPage({super.key});

  @override
  _PedidoOracaoPageState createState() => _PedidoOracaoPageState();
}

class _PedidoOracaoPageState extends State<PedidoOracaoPage> {
  List<Map<String, dynamic>> pedidos = [];
  List<Map<String, dynamic>> pedidosFiltrados = [];
  bool carregando = true;
  String busca = '';

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
          pedidosFiltrados = result;
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

  void filtrarPedidos(String textoBusca) {
    setState(() {
      busca = textoBusca;
      pedidosFiltrados = pedidos
          .where((pedido) => pedido['descricao'].toLowerCase().contains(textoBusca.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedido de Oração')),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Buscar Pedidos',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: filtrarPedidos,
                  ),
                ),
                Expanded(
                  child: pedidosFiltrados.isEmpty
                      ? const Center(child: Text('Nenhum pedido encontrado'))
                      : SingleChildScrollView(
                          child: PaginaDePedidos(pedidos: pedidosFiltrados),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            carregando = true;
          });
          carregarPedidos();
        },
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class PaginaDePedidos extends StatelessWidget {
  const PaginaDePedidos({super.key, required this.pedidos});

  final List<Map<String, dynamic>> pedidos;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 20, // Adicionado para expandir as colunas
        columns: const [
          DataColumn(
            label: Text(
              'Data',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey,fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              'Descrição',
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
            ),
          ),
        ],
        rows: pedidos.map((pedido) {
          final data = pedido['data'] ?? '';
          final descricao = pedido['descricao'] ?? '';

          return DataRow(
            cells: [
              DataCell(
                Text(
                  HomePage().formatarData(data),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
              DataCell(
                SizedBox(
                  width: 600, // Adicionado largura maior para "Descrição"
                  child: SelectableText(
                    descricao,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
