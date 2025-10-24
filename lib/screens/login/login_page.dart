import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admg_app/screens/home_page.dart';
import 'package:admg_app/screens/mesario_page.dart';
import 'package:admg_app/screens/tesoureiro/tesoureiro_page.dart';
import 'package:admg_app/screens/secretario/secretario_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admg_app/screens/setor_selection_page.dart';

class LoginPage extends StatefulWidget {
  final String? userType;
  const LoginPage({super.key, this.userType});

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
  Future<void>? _initialDataLoadingFuture;

  final TextEditingController _senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usuarioSelecionado = null;
    _initialDataLoadingFuture = _loadInitialData();
  }

  @override
  void dispose() {
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    print(
        'DEBUG - _loadInitialData: Iniciando carregamento de dados iniciais...');
    await _carregarUsuarios();
    await _carregarCredenciaisSalvas();
    print(
        'DEBUG - _loadInitialData: Carregamento de dados iniciais concluído.');
  }

  Future<void> _carregarUsuarios() async {
    print('DEBUG - _carregarUsuarios: Iniciando carregamento de usuários...');
    try {
      var query = supabase.from('usuario').select('id, nome, setor, cargo');

      if (widget.userType == 'tesoraria') {
        query = query.eq('cargo', 'tesoureiro');
      } else if (widget.userType == 'mesario_dirigente') {
        query = query.or('cargo.eq.mesario,cargo.eq.dirigente');
      } else if (widget.userType == 'secretaria') {
        query = query.eq('cargo', 'secretario');
      }

      final response = await query.order('nome');

      if (response != null) {
        final uniqueUsers = <String, Map<String, dynamic>>{};
        for (var user in response) {
          final normalizedName = user['nome']?.toString().toLowerCase().trim();
          if (normalizedName != null &&
              normalizedName.isNotEmpty &&
              !uniqueUsers.containsKey(normalizedName)) {
            uniqueUsers[normalizedName] = user;
          }
        }
        setState(() {
          _usuarios = uniqueUsers.values.toList();
          if (_usuarioSelecionado != null) {
            final selectedNormalized =
                _usuarioSelecionado!.toLowerCase().trim();
            if (!uniqueUsers.containsKey(selectedNormalized)) {
              _usuarioSelecionado = null;
              _nome = '';
            }
          }
        });
        print(
            'DEBUG - _carregarUsuarios: Usuários carregados e normalizados. Total: ${_usuarios.length}');
      }
    } catch (e) {
      print('ERRO - _carregarUsuarios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar usuários: $e')),
      );
    }
  }

  Future<void> _carregarCredenciaisSalvas() async {
    print(
        'DEBUG - _carregarCredenciaisSalvas: Iniciando carregamento de credenciais salvas...');
    final prefs = await SharedPreferences.getInstance();
    final nomeSalvo = prefs.getString('usuario_nome');
    final senhaSalva = prefs.getString('usuario_senha');

    if (nomeSalvo != null && senhaSalva != null) {
      final nomeSalvoNormalizado = nomeSalvo.toLowerCase().trim();
      final usuarioExistente = _usuarios.any((usuario) =>
          (usuario['nome']?.toString()?.toLowerCase()?.trim() ?? '') ==
          nomeSalvoNormalizado);
      if (usuarioExistente) {
        setState(() {
          _nome = nomeSalvoNormalizado;
          _senha = senhaSalva;
          _senhaController.text = senhaSalva;
          _lembrarSenha = true;
          _usuarioSelecionado = nomeSalvoNormalizado;
        });
        print(
            'DEBUG - _carregarCredenciaisSalvas: Credenciais válidas encontradas. _usuarioSelecionado: $_usuarioSelecionado');
      } else {
        await prefs.remove('usuario_nome');
        await prefs.remove('usuario_senha');
        await prefs.remove('usuario_id');
        await prefs.remove('usuario_setor');
        await prefs.remove('usuario_cargo');
        setState(() {
          _nome = '';
          _senhaController.text = '';
          _lembrarSenha = false;
          _usuarioSelecionado = null;
        });
        print(
            'DEBUG - _carregarCredenciaisSalvas: Usuário salvo inválido/inexistente. _usuarioSelecionado: $_usuarioSelecionado');
      }
    } else {
      setState(() {
        _nome = '';
        _senhaController.text = '';
        _lembrarSenha = false;
        _usuarioSelecionado = null;
      });
      await prefs.remove('usuario_nome');
      await prefs.remove('usuario_senha');
      await prefs.remove('usuario_id');
      await prefs.remove('usuario_setor');
      await prefs.remove('usuario_cargo');
      print(
          'DEBUG - _carregarCredenciaisSalvas: Nenhuma credencial salva ou incompleta. _usuarioSelecionado: $_usuarioSelecionado');
    }
    print(
        'DEBUG - _carregarCredenciaisSalvas: Carregamento de credenciais salvas concluído.');
  }

  Future<void> _salvarCredenciais({
    required String id,
    required String nome,
    required String setor,
    required String cargo,
    required String senha,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (_lembrarSenha) {
      await prefs.setString('usuario_id', id);
      await prefs.setString('usuario_nome', nome);
      await prefs.setString('usuario_setor', setor);
      await prefs.setString('usuario_cargo', cargo);
      await prefs.setString('usuario_senha', senha);
    } else {
      await prefs.remove('usuario_id');
      await prefs.remove('usuario_nome');
      await prefs.remove('usuario_setor');
      await prefs.remove('usuario_cargo');
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
          .ilike('nome', _nome.trim())
          .eq('senha', _senha)
          .maybeSingle();

      if (response != null) {
        final id = response['id']?.toString() ?? '';
        final nomeUsuario = response['nome']?.toString() ?? '';
        final setor = response['setor']?.toString().toLowerCase() ?? '';
        final cargo = response['cargo']?.toString().toLowerCase() ?? '';

        await _salvarCredenciais(
          id: id,
          nome: nomeUsuario,
          setor: setor,
          cargo: cargo,
          senha: _senha,
        );

        if (cargo == 'tesoureiro') {
          final bool isUserMaster =
              (setor == 'tesoureiro' || setor == 'master' || setor.isEmpty);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (isUserMaster) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SetorSelectionPage(
                    usuarioId: id,
                    usuarioNome: nomeUsuario,
                    usuarioSetor: setor,
                    usuarioCargo: cargo,
                    isMaster: isUserMaster,
                  ),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TesoureiroPage(
                    isMaster: isUserMaster,
                    setor: setor,
                    usuarioId: id,
                    usuarioNome: nomeUsuario,
                    usuarioCargo: cargo,
                    usuarioSetor: setor,
                  ),
                ),
              );
            }
          });
        } else if (cargo == 'mesario') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MesarioPage()),
            );
          });
        } else if (cargo == 'dirigente') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          });
        } else if (cargo == 'secretario') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SecretarioPage()),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cargo não reconhecido!')),
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
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<void>(
                        future: _initialDataLoadingFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Text(
                                'Erro ao carregar usuários: ${snapshot.error}');
                          } else {
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                prefixIcon:
                                    Icon(Icons.person_outline, size: 28),
                                hintText: 'Selecione um usuário',
                              ),
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black87),
                              isExpanded: true,
                              items: _usuarios
                                  .map<DropdownMenuItem<String>>((usuario) {
                                final nome = usuario['nome']
                                        ?.toString()
                                        ?.toLowerCase()
                                        ?.trim() ??
                                    '';
                                final setor = usuario['setor']
                                        ?.toString()
                                        ?.toLowerCase() ??
                                    '';
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
                                  _nome = value?.toLowerCase().trim() ?? '';
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Selecione um usuário' : null,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Senha',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _senhaController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline, size: 28),
                          hintText: 'Digite sua senha',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Digite sua senha'
                            : null,
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
                          ),
                          const Text('Lembrar senha'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _carregando ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _carregando
                              ? const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(fontSize: 20),
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
