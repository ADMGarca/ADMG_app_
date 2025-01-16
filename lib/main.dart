import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi; // Configuração necessária no Windows
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
                exit(0); // Encerra o aplicativo
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

// Função para abrir o banco de dados com validação
Future<Database> _abrirBanco() async {
  try {
    const String caminhoBanco = '\\\\NBWASHINGTON\\Users\\dpnew\\OneDrive\\Área de Trabalho\\Banco\\ADMG.db';

    if (!File(caminhoBanco).existsSync()) {
      throw Exception("Erro: O banco de dados não foi encontrado no caminho especificado.");
    }

    Database db = await databaseFactory.openDatabase(
      caminhoBanco,
      options: OpenDatabaseOptions(
        version: 1,
        onOpen: (db) => print("Banco de dados conectado com sucesso!"),
      ),
    );

    return db;
  } catch (e) {
    print("Erro ao abrir o banco: $e");
    rethrow;
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
      Database db = await _abrirBanco();
      List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT strftime('%d/%m/%Y', Data) as Data,
               Status as Importancia,
               Descricao as Aviso
        FROM Aviso order by Status
      ''');

      print("Dados recuperados da tabela Aviso: $result");

      setState(() {
        avisos = result;
        carregando = false;
      });
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
      Database db = await _abrirBanco();
      List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT strftime('%d/%m/%Y', Data) as Data,
               Descricao as Oração
        FROM PedidoOracao 
      ''');

      print("Dados recuperados da tabela PedidoOracao: $result");

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
