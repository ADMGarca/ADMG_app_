import 'package:flutter/material.dart';
import 'package:admg_app/screens/tesoureiro/tesoureiro_page.dart';
import 'package:admg_app/screens/tesoureiro/tesoureiro_master_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetorSelectionPage extends StatefulWidget {
  final String usuarioId;
  final String usuarioNome;
  final String usuarioSetor;
  final String usuarioCargo;
  final bool isMaster;

  const SetorSelectionPage({
    Key? key,
    required this.usuarioId,
    required this.usuarioNome,
    required this.usuarioSetor,
    required this.usuarioCargo,
    required this.isMaster,
  }) : super(key: key);

  @override
  _SetorSelectionPageState createState() => _SetorSelectionPageState();
}

class _SetorSelectionPageState extends State<SetorSelectionPage> {
  final supabase = Supabase.instance.client;
  List<String> _setoresDisponiveis = [];
  String? _setorSelecionado;
  bool _carregandoSetores = true;

  @override
  void initState() {
    super.initState();
    print(
      'DEBUG - SetorSelectionPage initState: isMaster = ${widget.isMaster}, usuarioSetor = ${widget.usuarioSetor}',
    );
    if (widget.isMaster) {
      _setorSelecionado =
          null; // Garante que tesoureiro master não tenha setor pré-selecionado do usuarioSetor
    } else {
      _setorSelecionado = widget.usuarioSetor
          .toLowerCase()
          .trim(); // Pré-seleciona para não-master, normalizado
    }
    _carregarSetoresDisponiveis();
  }

  Future<void> _carregarSetoresDisponiveis() async {
    try {
      final response = await supabase.from('setor').select('nome');
      if (response != null && response.isNotEmpty) {
        // Prepare variables for setState
        List<String> tempSetoresDisponiveis = [];
        String? tempSetorSelecionado;

        if (widget.isMaster) {
          tempSetoresDisponiveis = List<String>.from(
            response.map((s) => s['nome'].toString().trim().toLowerCase()),
          );
          // Para tesoureiro master, _setorSelecionado deve permanecer null inicialmente para permitir seleção.
          // if (tempSetoresDisponiveis.isNotEmpty) {
          //   tempSetorSelecionado = tempSetoresDisponiveis.first;
          // }
        } else {
          // Para usuários não-master, define o setor com base no usuarioSetor vindo do login
          final normalizedUsuarioSetor =
              widget.usuarioSetor.toLowerCase().trim();
          if (response
              .map((s) => s['nome'].toString())
              .contains(normalizedUsuarioSetor)) {
            tempSetoresDisponiveis = [normalizedUsuarioSetor];
            tempSetorSelecionado = normalizedUsuarioSetor;
          } else {
            // Caso o setor do usuário não seja encontrado na lista de setores válidos
            tempSetoresDisponiveis = [];
            tempSetorSelecionado = null;
          }
        }

        setState(() {
          _setoresDisponiveis = tempSetoresDisponiveis;
          _setorSelecionado =
              tempSetorSelecionado; // Isso será null para mestres
          _carregandoSetores = false;
        });
      } else {
        setState(() {
          _carregandoSetores = false;
          _setoresDisponiveis = [];
          _setorSelecionado = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar setores: $e')));
      setState(() {
        _carregandoSetores = false;
      });
    }
  }

  void _navegarParaTesoureiroPage() {
    if (_setorSelecionado != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TesoureiroMasterPage(
              usuarioId: widget.usuarioId,
              usuarioNome: widget.usuarioNome,
              usuarioSetor: widget.usuarioSetor,
              usuarioCargo: widget.usuarioCargo,
              isMaster: widget.isMaster,
              setorInicial: _setorSelecionado!
                  .trim()
                  .toLowerCase(), // Passa o setor selecionado como setorInicial, garantindo minúsculas
            ),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um setor.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // print('DEBUG - SetorSelectionPage Build: _setorSelecionado = $_setorSelecionado'); // Removido
    // print('DEBUG - SetorSelectionPage Build: _setoresDisponiveis = $_setoresDisponiveis'); // Removido

    // Verificação defensiva para garantir que _setorSelecionado seja um valor válido ou null
    // Esta lógica agora está integrada diretamente na propriedade 'value' do DropdownButtonFormField
    // String? effectiveSetorSelecionado = _setorSelecionado;
    // if (effectiveSetorSelecionado != null && !_setoresDisponiveis.contains(effectiveSetorSelecionado)) {
    //   print('DEBUG - SetorSelectionPage Build: _setorSelecionado ($effectiveSetorSelecionado) não encontrado na lista de setores disponíveis. Redefinindo para null.');
    //   effectiveSetorSelecionado = null;
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Setor'),
        backgroundColor: const Color(0xFF42A5F5),
      ),
      body: _carregandoSetores
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Selecione o setor para visualizar as transações:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Debug prints imediatamente antes do DropdownButtonFormField
                  // Text(
                  //   'DEBUG - _setorSelecionado antes do dropdown: $_setorSelecionado',
                  // ),
                  // Text(
                  //   'DEBUG - _setoresDisponiveis antes do dropdown: $_setoresDisponiveis',
                  // ),
                  // Text(
                  //   'DEBUG - isMaster antes do dropdown: ${widget.isMaster}',
                  // ),
                  // Text(
                  //   'DEBUG - usuarioSetor (original) antes do dropdown: ${widget.usuarioSetor}',
                  // ),
                  // Text(
                  //   'DEBUG - Valor passado para o dropdown: ${_setoresDisponiveis.contains(_setorSelecionado) ? _setorSelecionado : null}',
                  // ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _setoresDisponiveis.contains(_setorSelecionado)
                        ? _setorSelecionado
                        : null, // Correção crucial
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.business_center, size: 28),
                      hintText: 'Selecione um setor',
                    ),
                    items: _setoresDisponiveis.map((setor) {
                      return DropdownMenuItem<String>(
                        value: setor,
                        child: Text(setor),
                      );
                    }).toList(),
                    onChanged: widget.isMaster
                        ? (String? newValue) {
                            setState(() {
                              _setorSelecionado = newValue;
                            });
                          }
                        : null, // Desabilitado para usuários não-master
                    validator: (value) =>
                        value == null ? 'Selecione um setor' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _navegarParaTesoureiroPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF42A5F5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
