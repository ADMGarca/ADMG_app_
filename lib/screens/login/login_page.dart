import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admg_app/screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  
  String _nome = '';
  String _senha = '';
  bool _lembrarSenha = false;
  bool _carregando = false;
  List<Map<String, dynamic>> _usuarios = [];
  String? _usuarioSelecionado;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
    _carregarCredenciaisSalvas();
  }

  Future<void> _carregarUsuarios() async {
    try {
      final response = await supabase
          .from('usuario')
          .select('id, nome, setor')
          .order('nome');

      if (response != null) {
        setState(() {
          _usuarios = List<Map<String, dynamic>>.from(response);
          if (_usuarios.isNotEmpty) {
            _usuarioSelecionado = _usuarios.first['nome'];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar usuários: $e')),
      );
    }
  }

  Future<void> _carregarCredenciaisSalvas() async {
    final prefs = await SharedPreferences.getInstance();
    final nomeSalvo = prefs.getString('usuario_nome');
    final senhaSalva = prefs.getString('usuario_senha');

    if (nomeSalvo != null && senhaSalva != null) {
      setState(() {
        _nome = nomeSalvo;
        _senha = senhaSalva;
        _lembrarSenha = true;
        _usuarioSelecionado = nomeSalvo;
      });
    }
  }

  Future<void> _salvarCredenciais() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lembrarSenha) {
      await prefs.setString('usuario_nome', _nome);
      await prefs.setString('usuario_senha', _senha);
    } else {
      await prefs.remove('usuario_nome');
      await prefs.remove('usuario_senha');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);

    try {
      final response = await supabase
          .from('usuario')
          .select()
          .eq('nome', _nome)
          .eq('senha', _senha)
          .maybeSingle();

      if (response != null) {
        await _salvarCredenciais();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário ou senha incorretos')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer login: $e')),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho com ícone e título
              Container(
                padding: const EdgeInsets.all(24.0),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.church, // Ícone de igreja
                      size: 80,
                      color: Color(0xFF42A5F5), // Azul claro
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ADMG - Bem-vindo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Entre para continuar',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Formulário
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Usuário',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _usuarioSelecionado,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_outline, size: 28),
                        ),
                        style: const TextStyle(fontSize: 18, color: Colors.black87),
                        items: _usuarios.map<DropdownMenuItem<String>>((usuario) {
                          return DropdownMenuItem<String>(
                            value: usuario['nome']?.toString(),
                            child: Text(
                              '${usuario['nome']} (${usuario['setor']})',
                              style: const TextStyle(fontSize: 18),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? value) {
                          setState(() {
                            _usuarioSelecionado = value;
                            _nome = value ?? '';
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Selecione um usuário' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Senha',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, size: 28),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(fontSize: 18),
                        validator: (value) =>
                            value!.isEmpty ? 'Digite sua senha' : null,
                        onChanged: (value) => _senha = value,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _lembrarSenha,
                            onChanged: (value) {
                              setState(() {
                                _lembrarSenha = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF42A5F5),
                          ),
                          const Text(
                            'Lembrar senha',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 60, // Botão maior
                        child: ElevatedButton(
                          onPressed: _carregando ? null : _login,
                          child: _carregando
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'ENTRAR',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}