import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admg_app/screens/avisos/avisos_page.dart';
import 'package:admg_app/screens/oracao/oracao_page.dart';
import 'package:admg_app/screens/louvor/louvor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admg_app/screens/login/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  bool _temAvisoUrgente = false;
  bool _temLouvores = false;
  bool _temPedidosOracao = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verificarNotificacoes();
    // Inicia o timer para consultar a cada 10 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _verificarNotificacoes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancela o timer ao sair da página
    super.dispose();
  }

  Future<void> _verificarNotificacoes() async {
    try {
      // Verifica se há avisos urgentes
      final avisosResponse = await supabase
          .from('aviso')
          .select()
          .eq('status', 'URGENTE')
          .limit(1);

      // Verifica se há louvores (apenas na primeira consulta)
      if (!_temLouvores) {
        final louvoresResponse = await supabase
            .from('louvor')
            .select()
            .limit(1);
        _temLouvores = louvoresResponse.isNotEmpty;
      }

      // Verifica se há pedidos de oração (apenas na primeira consulta)
      if (!_temPedidosOracao) {
        final pedidosResponse = await supabase
            .from('pedidodeoracao')
            .select()
            .limit(1);
        _temPedidosOracao = pedidosResponse.isNotEmpty;
      }

      setState(() {
        _temAvisoUrgente = avisosResponse.isNotEmpty;
      });

      // Exibe notificações com prioridade para aviso urgente
      if (_temAvisoUrgente) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove notificações anteriores
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Há um aviso URGENTE! Clique em "Avisos" para visualizar.',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AvisosPage()),
                );
              },
            ),
          ),
        );
      } else if (!_temAvisoUrgente) {
        // Se não houver aviso urgente, verifica louvores e pedidos de oração
        if (_temLouvores) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Há novos louvores disponíveis!',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              backgroundColor: const Color(0xFF42A5F5),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LouvorPage()),
                  );
                },
              ),
            ),
          );
        }
        if (_temPedidosOracao) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Há novos pedidos de oração!',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              backgroundColor: const Color(0xFF42A5F5),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PedidoOracaoPage()),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao verificar notificações: $e');
    }
  }

  Future<void> _sair(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_nome');
    await prefs.remove('usuario_senha');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Método para abrir o diálogo e enviar mensagem aos mesários
  void _abrirDialogoFalarComMesarios() {
    final TextEditingController mensagemController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Falar com Mesários',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: mensagemController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Digite sua mensagem',
            border: OutlineInputBorder(),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final mensagem = mensagemController.text.trim();
              if (mensagem.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor, digite uma mensagem')),
                );
                return;
              }

              try {
                // Insere a mensagem na tabela falarcommesario
                await supabase.from('falarcommesario').insert({
                  'descricao': mensagem,
                });

                Navigator.pop(context); // Fecha o diálogo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mensagem enviada com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao enviar mensagem: $e')),
                );
              }
            },
            child: const Text(
              'Enviar',
              style: TextStyle(fontSize: 18),
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
        title: const Text('ADMG - Início'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () => _sair(context),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(24.0),
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  children: [
                    const Icon(
                      Icons.church,
                      size: 80,
                      color: Color(0xFF42A5F5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bem-vindo à ADMG',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Escolha uma opção abaixo',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              // Botões
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildMenuButton(
                      text: 'Avisos',
                      icon: Icons.announcement,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AvisosPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Pedido de Oração',
                      icon: Icons.handshake,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PedidoOracaoPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Louvor',
                      icon: Icons.music_note,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LouvorPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Falar com Mesários',
                      icon: Icons.message,
                      backgroundColor: Colors.green,
                      onPressed: _abrirDialogoFalarComMesarios,
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Sair',
                      icon: Icons.exit_to_app,
                      backgroundColor: Colors.red,
                      onPressed: () => _sair(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String text,
    required IconData icon,
    Color? backgroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 30),
        label: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF42A5F5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}