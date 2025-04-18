import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admg_app/screens/home_page.dart';
import 'package:admg_app/screens/mesario_page.dart';
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

  final TextEditingController _senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
    _carregarCredenciaisSalvas();
  }

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
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

    print('Carregando credenciais salvas: nome=$nomeSalvo, senha=$senhaSalva');

    if (nomeSalvo != null && senhaSalva != null) {
      setState(() {
        _nome = nomeSalvo;
        _senha = senhaSalva;
        _senhaController.text = senhaSalva;
        _lembrarSenha = true;
        _usuarioSelecionado = nomeSalvo;

        // Verifica se o nome salvo existe na lista de usuários
        final usuarioExistente = _usuarios.any((usuario) => usuario['nome'] == nomeSalvo);
        if (!usuarioExistente) {
          _usuarioSelecionado = null; // Reseta se o usuário não existir mais
          _nome = '';
          _senhaController.text = '';
          _lembrarSenha = false;
          prefs.remove('usuario_nome');
          prefs.remove('usuario_senha');
        }
      });
    }
  }

  Future<void> _salvarCredenciais() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lembrarSenha) {
      print('Salvando credenciais: nome=$_nome, senha=$_senha');
      await prefs.setString('usuario_nome', _nome);
      await prefs.setString('usuario_senha', _senha);
    } else {
      print('Removendo credenciais salvas');
      await prefs.remove('usuario_nome');
      await prefs.remove('usuario_senha');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _senha = _senhaController.text;
      _carregando = true;
    });

    try {
      final response = await supabase
          .from('usuario')
          .select()
          .eq('nome', _nome)
          .eq('senha', _senha)
          .maybeSingle();

      if (response != null) {
        await _salvarCredenciais();
        final setor = response['setor']?.toString().toLowerCase() ?? '';
        if (setor == 'mesário') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MesarioPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
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
                      Icons.church,
                      size: 80,
                      color: Color(0xFF42A5F5),
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
                          hintText: 'Selecione um usuário',
                        ),
                        style: const TextStyle(fontSize: 18, color: Colors.black87),
                        items: _usuarios.map<DropdownMenuItem<String>>((usuario) {
                          final nome = usuario['nome']?.toString() ?? '';
                          final setor = usuario['setor']?.toString().toLowerCase() ?? '';
                          Color setorColor = Colors.black54;

                          if (setor == 'dirigente') {
                            setorColor = Colors.blue;
                          } else if (setor == 'mesário') {
                            setorColor = Colors.red;
                          }

                          return DropdownMenuItem<String>(
                            value: nome,
                            child: Row(
                              children: [
                                Text(
                                  nome,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '($setor)',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: setorColor,
                                  ),
                                ),
                              ],
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
                        controller: _senhaController,
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
                        height: 60,
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