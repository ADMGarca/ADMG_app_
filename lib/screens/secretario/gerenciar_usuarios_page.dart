import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GerenciarUsuariosPage extends StatefulWidget {
  const GerenciarUsuariosPage({super.key});

  @override
  State<GerenciarUsuariosPage> createState() => _GerenciarUsuariosPageState();
}

class _GerenciarUsuariosPageState extends State<GerenciarUsuariosPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _usuarios = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    try {
      setState(() => _carregando = true);
      final response = await supabase
          .from('usuario')
          .select('id, nome, setor, cargo, senha')
          .order('nome');

      setState(() {
        _usuarios = List<Map<String, dynamic>>.from(response);
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar usuários: $e')),
      );
    }
  }

  void _abrirDialogoCadastrarUsuario() {
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController senhaController = TextEditingController();
    final TextEditingController setorController = TextEditingController();
    String cargoSelecionado = 'membro';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Cadastrar Usuário',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: setorController,
                  decoration: const InputDecoration(
                    labelText: 'Setor',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: cargoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Cargo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'membro', child: Text('Membro')),
                    DropdownMenuItem(value: 'mesario', child: Text('Mesário')),
                    DropdownMenuItem(
                        value: 'dirigente', child: Text('Dirigente')),
                    DropdownMenuItem(
                        value: 'tesoureiro', child: Text('Tesoureiro')),
                    DropdownMenuItem(
                        value: 'secretario', child: Text('Secretário')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      cargoSelecionado = value!;
                    });
                  },
                ),
              ],
            ),
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
                final nome = nomeController.text.trim();
                final senha = senhaController.text.trim();
                final setor = setorController.text.trim();

                if (nome.isEmpty || senha.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Nome e senha são obrigatórios')),
                  );
                  return;
                }

                try {
                  await supabase.from('usuario').insert({
                    'nome': nome,
                    'senha': senha,
                    'setor': setor.isEmpty ? null : setor,
                    'cargo': cargoSelecionado,
                  });

                  Navigator.pop(context);
                  _carregarUsuarios();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Usuário cadastrado com sucesso!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao cadastrar usuário: $e')),
                  );
                }
              },
              child: const Text(
                'Cadastrar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDialogoEditarUsuario(Map<String, dynamic> usuario) {
    final TextEditingController nomeController =
        TextEditingController(text: usuario['nome'] ?? '');
    final TextEditingController senhaController =
        TextEditingController(text: usuario['senha'] ?? '');
    final TextEditingController setorController =
        TextEditingController(text: usuario['setor'] ?? '');
    String cargoSelecionado = usuario['cargo'] ?? 'membro';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Editar Usuário',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: setorController,
                  decoration: const InputDecoration(
                    labelText: 'Setor',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: cargoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Cargo',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'membro', child: Text('Membro')),
                    DropdownMenuItem(value: 'mesario', child: Text('Mesário')),
                    DropdownMenuItem(
                        value: 'dirigente', child: Text('Dirigente')),
                    DropdownMenuItem(
                        value: 'tesoureiro', child: Text('Tesoureiro')),
                    DropdownMenuItem(
                        value: 'secretario', child: Text('Secretário')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      cargoSelecionado = value!;
                    });
                  },
                ),
              ],
            ),
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
                final nome = nomeController.text.trim();
                final senha = senhaController.text.trim();
                final setor = setorController.text.trim();

                if (nome.isEmpty || senha.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Nome e senha são obrigatórios')),
                  );
                  return;
                }

                try {
                  await supabase.from('usuario').update({
                    'nome': nome,
                    'senha': senha,
                    'setor': setor.isEmpty ? null : setor,
                    'cargo': cargoSelecionado,
                  }).eq('id', usuario['id']);

                  Navigator.pop(context);
                  _carregarUsuarios();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Usuário atualizado com sucesso!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar usuário: $e')),
                  );
                }
              },
              child: const Text(
                'Salvar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _excluirUsuario(Map<String, dynamic> usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Confirmar Exclusão',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Tem certeza que deseja excluir o usuário "${usuario['nome']}"?',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Excluir',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await supabase.from('usuario').delete().eq('id', usuario['id']);
        _carregarUsuarios();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário excluído com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir usuário: $e')),
        );
      }
    }
  }

  Color _getCargoColor(String cargo) {
    switch (cargo?.toLowerCase()) {
      case 'secretario':
        return Colors.purple;
      case 'tesoureiro':
        return Colors.blue;
      case 'mesario':
        return Colors.orange;
      case 'dirigente':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Usuários'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24.0),
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 80,
                        color: Color(0xFF42A5F5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gerenciar Usuários',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cadastre, edite e gerencie os usuários do sistema',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _usuarios.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum usuário cadastrado',
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _usuarios.length,
                          itemBuilder: (context, index) {
                            final usuario = _usuarios[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      _getCargoColor(usuario['cargo']),
                                  child: Text(
                                    usuario['nome']
                                            ?.toString()
                                            .substring(0, 1)
                                            .toUpperCase() ??
                                        'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  usuario['nome'] ?? 'Sem nome',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cargo: ${usuario['cargo'] ?? 'Não definido'}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _getCargoColor(usuario['cargo']),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (usuario['setor'] != null &&
                                        usuario['setor'].toString().isNotEmpty)
                                      Text(
                                        'Setor: ${usuario['setor']}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () =>
                                          _abrirDialogoEditarUsuario(usuario),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => _excluirUsuario(usuario),
                                      tooltip: 'Excluir',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogoCadastrarUsuario,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Usuário'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
      ),
    );
  }
}
