import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GerenciarMensagensPage extends StatefulWidget {
  const GerenciarMensagensPage({super.key});

  @override
  _GerenciarMensagensPageState createState() => _GerenciarMensagensPageState();
}

class _GerenciarMensagensPageState extends State<GerenciarMensagensPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> mensagens = [];
  bool carregando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    carregarMensagens();
    // Verifica mensagens a cada 5 minutos
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      carregarMensagens();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> carregarMensagens() async {
    try {
      final response = await supabase
          .from('falarcommesario')
          .select()
          .order('id', ascending: false);

      setState(() {
        mensagens = List<Map<String, dynamic>>.from(response);
        carregando = false;
      });

      // Atualiza o último ID visto no SharedPreferences
      if (mensagens.isNotEmpty) {
        final maiorId = mensagens.first['id'] as int;
        final prefs = await SharedPreferences.getInstance();
        final ultimoIdVisto = prefs.getInt('ultimo_id_mensagem_visto') ?? 0;
        if (maiorId > ultimoIdVisto) {
          await prefs.setInt('ultimo_id_mensagem_visto', maiorId);
        }
      }
    } catch (e) {
      print('Erro ao carregar mensagens: $e');
      setState(() {
        carregando = false;
      });
    }
  }

  void _excluirMensagem(int id) async {
    try {
      await supabase.from('falarcommesario').delete().eq('id', id);
      carregarMensagens();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensagem excluída com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir mensagem: $e')),
      );
    }
  }

  void _mostrarDescricaoAmpliada(String descricao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Mensagem',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            descricao,
            style: const TextStyle(fontSize: 22, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(fontSize: 18, color: Color(0xFF42A5F5)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Mensagens'),
        centerTitle: true,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : mensagens.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma mensagem encontrada',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  itemCount: mensagens.length,
                  itemBuilder: (context, index) {
                    final mensagem = mensagens[index];
                    final id = mensagem['id']?.toString() ?? '';
                    final descricao = mensagem['descricao']?.toString() ?? '';

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
                                child: GestureDetector(
                                  onTap: () => _mostrarDescricaoAmpliada(descricao),
                                  child: Text(
                                    descricao,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _excluirMensagem(int.parse(id)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}