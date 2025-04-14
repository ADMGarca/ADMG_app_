import 'dart:async';
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
  bool _temAvisoNormal = false;
  bool _temLouvores = false;
  bool _temPedidosOracao = false;
  bool _notificacaoLouvorExibida = false;
  bool _notificacaoOracaoExibida = false;
  bool _notificacaoAvisoNormalExibida = false;
  int _ultimoIdAvisoNormal = 0;
  int _ultimoIdLouvor = 0;
  int _ultimoIdPedidoOracao = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarUltimosIds();
    _verificarNotificacoes();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _verificarNotificacoes();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarUltimosIds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ultimoIdAvisoNormal = prefs.getInt('ultimo_id_aviso_normal') ?? 0;
      _ultimoIdLouvor = prefs.getInt('ultimo_id_louvor') ?? 0;
      _ultimoIdPedidoOracao = prefs.getInt('ultimo_id_pedido_oracao') ?? 0;
    });
  }

  Future<void> _salvarUltimoId(String key, int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, id);
  }

  Future<void> _verificarNotificacoes() async {
    try {
      // Verifica avisos urgentes (qualquer aviso com status URGENTE)
      final avisosUrgentesResponse = await supabase
          .from('aviso')
          .select('id')
          .eq('status', 'URGENTE')
          .limit(1);

      // Verifica avisos normais (apenas novos)
      final avisosNormaisResponse = await supabase
          .from('aviso')
          .select('id')
          .eq('status', 'NORMAL')
          .order('id', ascending: false)
          .limit(1);

      // Verifica louvores (apenas novos)
      final louvoresResponse = await supabase
          .from('louvor')
          .select('id')
          .order('id', ascending: false)
          .limit(1);

      // Verifica pedidos de oração (apenas novos)
      final pedidosResponse = await supabase
          .from('pedidodeoracao')
          .select('id')
          .order('id', ascending: false)
          .limit(1);

      // Atualiza os estados
      setState(() {
        // Para avisos urgentes, verificamos apenas se existe algum registro
        _temAvisoUrgente = avisosUrgentesResponse.isNotEmpty;

        // Para avisos normais, verificamos se há novos registros
        if (avisosNormaisResponse.isNotEmpty) {
          final novoId = avisosNormaisResponse.first['id'] as int;
          _temAvisoNormal = novoId > _ultimoIdAvisoNormal;
          if (_temAvisoNormal) _ultimoIdAvisoNormal = novoId;
        } else {
          _temAvisoNormal = false;
        }

        // Para louvores, verificamos se há novos registros
        if (louvoresResponse.isNotEmpty) {
          final novoId = louvoresResponse.first['id'] as int;
          _temLouvores = novoId > _ultimoIdLouvor;
          if (_temLouvores) _ultimoIdLouvor = novoId;
        } else {
          _temLouvores = false;
        }

        // Para pedidos de oração, verificamos se há novos registros
        if (pedidosResponse.isNotEmpty) {
          final novoId = pedidosResponse.first['id'] as int;
          _temPedidosOracao = novoId > _ultimoIdPedidoOracao;
          if (_temPedidosOracao) _ultimoIdPedidoOracao = novoId;
        } else {
          _temPedidosOracao = false;
        }
      });

      // Salva os últimos IDs verificados (apenas para avisos normais, louvores e pedidos de oração)
      if (_temAvisoNormal) await _salvarUltimoId('ultimo_id_aviso_normal', _ultimoIdAvisoNormal);
      if (_temLouvores) await _salvarUltimoId('ultimo_id_louvor', _ultimoIdLouvor);
      if (_temPedidosOracao) await _salvarUltimoId('ultimo_id_pedido_oracao', _ultimoIdPedidoOracao);

      // Exibe notificações com prioridade para aviso urgente
      if (_temAvisoUrgente) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Há um aviso URGENTE! Clique em "Avisos" para visualizar.',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AvisosPage()),
                ).then((_) => _verificarNotificacoes());
              },
            ),
          ),
        );
      } else if (_temAvisoNormal && !_notificacaoAvisoNormalExibida) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Há um novo aviso! Clique em "Avisos" para visualizar.',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AvisosPage()),
                ).then((_) => _verificarNotificacoes());
              },
            ),
          ),
        );
        _notificacaoAvisoNormalExibida = true;
      } else if (_temLouvores && !_notificacaoLouvorExibida) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Há novos louvores disponíveis!',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF42A5F5),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LouvorPage()),
                ).then((_) => _verificarNotificacoes());
              },
            ),
          ),
        );
        _notificacaoLouvorExibida = true;
      } else if (_temPedidosOracao && !_notificacaoOracaoExibida) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Há novos pedidos de oração!',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF42A5F5),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Ver',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PedidoOracaoPage()),
                ).then((_) => _verificarNotificacoes());
              },
            ),
          ),
        );
        _notificacaoOracaoExibida = true;
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
                await supabase.from('falarcommesario').insert({
                  'descricao': mensagem,
                });

                Navigator.pop(context);
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

  void _mostrarNotificacoes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Notificações',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_temAvisoUrgente)
                ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: const Text(
                    'Aviso Urgente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Há um aviso urgente para visualizar.'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _temAvisoUrgente = false; // Remove a notificação atual da interface
                      });
                      Navigator.pop(context);
                      _verificarNotificacoes(); // Re-verifica imediatamente para atualizar o estado
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AvisosPage()),
                    ).then((_) => _verificarNotificacoes());
                  },
                ),
              if (_temAvisoNormal)
                ListTile(
                  leading: const Icon(Icons.announcement, color: Colors.orange),
                  title: const Text(
                    'Aviso Normal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Há um novo aviso para visualizar.'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _temAvisoNormal = false;
                        _notificacaoAvisoNormalExibida = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AvisosPage()),
                    ).then((_) => _verificarNotificacoes());
                  },
                ),
              if (_temLouvores)
                ListTile(
                  leading: const Icon(Icons.music_note, color: Color(0xFF42A5F5)),
                  title: const Text(
                    'Novos Louvores',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Há novos louvores disponíveis.'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _temLouvores = false;
                        _notificacaoLouvorExibida = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LouvorPage()),
                    ).then((_) => _verificarNotificacoes());
                  },
                ),
              if (_temPedidosOracao)
                ListTile(
                  leading: const Icon(Icons.handshake, color: Color(0xFF42A5F5)),
                  title: const Text(
                    'Pedidos de Oração',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Há novos pedidos de oração.'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _temPedidosOracao = false;
                        _notificacaoOracaoExibida = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PedidoOracaoPage()),
                    ).then((_) => _verificarNotificacoes());
                  },
                ),
              if (!_temAvisoUrgente && !_temAvisoNormal && !_temLouvores && !_temPedidosOracao)
                const Text(
                  'Nenhuma notificação no momento.',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
            ],
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
        title: const Text('ADMG - Início'),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, size: 28),
                onPressed: _mostrarNotificacoes,
                tooltip: 'Notificações',
              ),
              if (_temAvisoUrgente || _temAvisoNormal || _temLouvores || _temPedidosOracao)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _temAvisoUrgente ? Colors.red : (_temAvisoNormal ? Colors.orange : const Color(0xFF42A5F5)),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      ((_temAvisoUrgente ? 1 : 0) +
                              (_temAvisoNormal ? 1 : 0) +
                              (_temLouvores ? 1 : 0) +
                              (_temPedidosOracao ? 1 : 0))
                          .toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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