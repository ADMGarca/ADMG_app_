import 'dart:async';
import 'package:flutter/material.dart';
import 'package:admg_app/screens/mesario/gerenciar_avisos_page.dart';
import 'package:admg_app/screens/mesario/gerenciar_oracao_page.dart';
import 'package:admg_app/screens/mesario/gerenciar_louvor_page.dart';
import 'package:admg_app/screens/mesario/gerenciar_mensagens_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admg_app/screens/login/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MesarioPage extends StatefulWidget {
  const MesarioPage({super.key});

  @override
  _MesarioPageState createState() => _MesarioPageState();
}

class _MesarioPageState extends State<MesarioPage> {
  final supabase = Supabase.instance.client;
  bool _temMensagemNova = false;
  Timer? _timer;
  int _ultimoIdVisto = 0;

  @override
  void initState() {
    super.initState();
    _carregarUltimoIdVisto();
    _verificarMensagensNovas();
    // Verifica mensagens novas a cada 10 segundos
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _verificarMensagensNovas();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarUltimoIdVisto() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ultimoIdVisto = prefs.getInt('ultimo_id_mensagem_visto') ?? 0;
    });
  }

  Future<void> _verificarMensagensNovas() async {
    try {
      // Busca a mensagem mais recente (maior id)
      final response = await supabase
          .from('falarcommesario')
          .select('id')
          .order('id', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final maiorId = response.first['id'] as int;
        setState(() {
          _temMensagemNova = maiorId > _ultimoIdVisto;
        });

        if (_temMensagemNova) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Nova Mensagem do Dirigente!',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 8), // Dura 8 segundos para não sobrepor
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GerenciarMensagensPage()),
                  ).then((_) {
                    // Após voltar da página de mensagens, atualiza o status
                    _carregarUltimoIdVisto();
                    _verificarMensagensNovas();
                  });
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao verificar mensagens novas: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMG - Mesário'),
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
                      'Painel do Mesário',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gerencie as informações',
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
                      backgroundColor: Colors.orange,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GerenciarAvisosPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Pedido de Oração',
                      icon: Icons.handshake,
                      backgroundColor: Colors.purple,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GerenciarOracaoPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Louvor',
                      icon: Icons.music_note,
                      backgroundColor: Colors.amber,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GerenciarLouvorPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Mensagem do Dirigente',
                      icon: Icons.message,
                      backgroundColor: Colors.green,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GerenciarMensagensPage()),
                      ),
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