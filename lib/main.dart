import 'dart:async'; 
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black),
                ),
                child: const Text('Avisos'),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 144, 119, 240),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.white),
                ),
                child: const Text('Pedido de Oração'),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Colors.black),
                ),
                child: const Text('Sair'),
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
  Timer? timer;

  @override
  void initState() {
    super.initState();
    carregarAvisos();
    timer = Timer.periodic(Duration(minutes: 2), (Timer t) {
      carregarAvisos();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> carregarAvisos() async {
    try {
      final response = await http.get(Uri.parse('http://172.16.2.113:5001/api/avisos'));
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
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh),
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
  Timer? timer;

  @override
  void initState() {
    super.initState();
    carregarPedidos();
    timer = Timer.periodic(Duration(minutes: 2), (Timer t) {
      carregarPedidos();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> carregarPedidos() async {
    try {
      final response = await http.get(Uri.parse('http://172.16.2.113:5001/api/pedidos'));
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
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh),
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
        columnSpacing: 20,
        columns: const [
          DataColumn(
            label: Text(
              'Data',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              'Importância',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              'Descrição',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                GestureDetector(
                  onTap: () {
                    exibirDescricaoCompleta(context, descricao);
                  },
                  child: SizedBox(
                    width: 600,
                    child: Text(
                      descricao,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis, 
                    ),
                  ),
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
            ],
          );
        }).toList(),
      ),
    );
  }

  void exibirDescricaoCompleta(BuildContext context, String descricao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Descrição Completa'),
          content: SingleChildScrollView(
            child: Text(
              descricao,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
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
        columnSpacing: 20,
        columns: const [
          DataColumn(
            label: Text(
              'Data',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 20),
            ),
          ),
          DataColumn(
            label: Text(
              'Descrição',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                GestureDetector(
                  onTap: () {
                    exibirDescricaoCompleta(context, descricao);
                  },
                  child: SizedBox(
                    width: 600,
                    child: Text(
                      descricao,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  void exibirDescricaoCompleta(BuildContext context, String descricao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Descrição Completa'),
          content: SingleChildScrollView(
            child: Text(
              descricao,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
