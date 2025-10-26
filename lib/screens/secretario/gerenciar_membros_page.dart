import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:intl/intl.dart';

class GerenciarMembrosPage extends StatefulWidget {
  const GerenciarMembrosPage({super.key});

  @override
  State<GerenciarMembrosPage> createState() => _GerenciarMembrosPageState();
}

class _GerenciarMembrosPageState extends State<GerenciarMembrosPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _membros = [];
  bool _carregando = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _carregarMembros();
  }

  /// Converte uma data no formato `DD/MM/YYYY` para `YYYY-MM-DD` (ISO) ou retorna null
  /// Retorna null também se a string for vazia ou inválida.
  String? _parseDateToIso(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    try {
      final df = DateFormat('dd/MM/yyyy');
      final dt = df.parseStrict(trimmed);
      // validar intervalo razoável (evita datas como 1111-11-11 que rompem constraints)
      final minYear = 1900;
      final maxYear =
          DateTime.now().year + 1; // permitir um ano adiante por segurança
      if (dt.year < minYear || dt.year > maxYear) return null;
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return null;
    }
  }

  Future<void> _carregarMembros() async {
    try {
      setState(() => _carregando = true);
      final response =
          await supabase.from('membros').select('*').order('nome_completo');

      setState(() {
        _membros = List<Map<String, dynamic>>.from(response);
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar membros: $e')),
      );
    }
  }

  void _abrirDialogoEditarMembro(Map<String, dynamic> membro) {
    final formKey = GlobalKey<FormState>();

    // Controllers preenchidos com os valores existentes
    final nomeController =
        TextEditingController(text: membro['nome_completo']?.toString() ?? '');
    final dataNascimentoController = MaskedTextController(mask: '00/00/0000');
    if (membro['data_nascimento_raw'] != null) {
      dataNascimentoController.text = membro['data_nascimento_raw'] as String;
    } else if (membro['data_nascimento'] != null) {
      try {
        final dt = DateTime.parse(membro['data_nascimento']);
        dataNascimentoController.text = DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {}
    }

    final cpfController = MaskedTextController(
        mask: '000.000.000-00', text: membro['cpf']?.toString() ?? '');
    final rgController =
        TextEditingController(text: membro['rg']?.toString() ?? '');
    final telefoneController = MaskedTextController(
        mask: '(00) 00000-0000', text: membro['telefone']?.toString() ?? '');
    final emailController =
        TextEditingController(text: membro['email']?.toString() ?? '');
    final enderecoRuaController =
        TextEditingController(text: membro['endereco_rua']?.toString() ?? '');
    final enderecoNumeroController = TextEditingController(
        text: membro['endereco_numero']?.toString() ?? '');
    final enderecoBairroController = TextEditingController(
        text: membro['endereco_bairro']?.toString() ?? '');
    final enderecoCidadeController = TextEditingController(
        text: membro['endereco_cidade']?.toString() ?? '');
    final enderecoCepController = MaskedTextController(
        mask: '00000-000', text: membro['endereco_cep']?.toString() ?? '');

    final dataConversaoController = MaskedTextController(mask: '00/00/0000');
    if (membro['data_conversao_raw'] != null) {
      dataConversaoController.text = membro['data_conversao_raw'] as String;
    } else if (membro['data_conversao'] != null) {
      try {
        final dt = DateTime.parse(membro['data_conversao']);
        dataConversaoController.text = DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {}
    }

    final dataBatismoController = MaskedTextController(mask: '00/00/0000');
    if (membro['data_batismo_raw'] != null) {
      dataBatismoController.text = membro['data_batismo_raw'] as String;
    } else if (membro['data_batismo'] != null) {
      try {
        final dt = DateTime.parse(membro['data_batismo']);
        dataBatismoController.text = DateFormat('dd/MM/yyyy').format(dt);
      } catch (_) {}
    }

    final igrejaBatismoController =
        TextEditingController(text: membro['igreja_batismo']?.toString() ?? '');
    final ministeriosController =
        TextEditingController(text: membro['ministerios']?.toString() ?? '');
    final nomeConjugeController =
        TextEditingController(text: membro['nome_conjuge']?.toString() ?? '');
    final filhosController =
        TextEditingController(text: membro['filhos']?.toString() ?? '');
    final nomeResponsavelController = TextEditingController(
        text: membro['nome_responsavel']?.toString() ?? '');
    final observacoesController = TextEditingController(
        text: membro['observacoes_pastorais']?.toString() ?? '');

    String sexoSelecionado = membro['sexo']?.toString() ?? 'Masculino';
    String estadoCivilSelecionado =
        membro['estado_civil']?.toString() ?? 'Solteiro';
    String cargoSelecionado = membro['cargo_funcao']?.toString() ?? 'Membro';
    String situacaoSelecionada =
        membro['situacao_atual']?.toString() ?? 'Ativo';
    String tipoMembroSelecionado =
        membro['tipo_membro']?.toString() ?? 'Membro antigo';
    String enderecoEstadoSelecionado =
        membro['endereco_estado']?.toString() ?? 'GO';
    String escolaridadeSelecionada =
        membro['escolaridade']?.toString() ?? 'Ensino Fundamental';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Editar Membro',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reutiliza a mesma estrutur    do  cadastro com campos pré-preenchidos
                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                        labelText: 'Nome Completo *',
                        border: OutlineInputBorder()),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Nome é obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dataNascimentoController,
                          decoration: const InputDecoration(
                              labelText: 'Data de Nascimento',
                              border: OutlineInputBorder(),
                              hintText: 'DD/MM/AAAA'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: sexoSelecionado,
                          decoration: const InputDecoration(
                              labelText: 'Sexo', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(
                                value: 'Masculino', child: Text('Masculino')),
                            DropdownMenuItem(
                                value: 'Feminino', child: Text('Feminino')),
                          ],
                          onChanged: (value) =>
                              setDialogState(() => sexoSelecionado = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: estadoCivilSelecionado,
                    decoration: const InputDecoration(
                        labelText: 'Estado Civil',
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'Solteiro', child: Text('Solteiro')),
                      DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                      DropdownMenuItem(
                          value: 'Divorciado', child: Text('Divorciado')),
                      DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => estadoCivilSelecionado = value!),
                  ),
                  const SizedBox(height: 12),

                  // CPF / RG
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cpfController,
                          decoration: const InputDecoration(
                              labelText: 'CPF',
                              border: OutlineInputBorder(),
                              hintText: '000.000.000-00'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: rgController,
                          decoration: const InputDecoration(
                              labelText: 'RG', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: telefoneController,
                          decoration: const InputDecoration(
                              labelText: 'Telefone/WhatsApp',
                              border: OutlineInputBorder(),
                              hintText: '(00) 00000-0000'),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                              labelText: 'E-mail',
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Endereço
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: TextField(
                              controller: enderecoRuaController,
                              decoration: const InputDecoration(
                                  labelText: 'Rua',
                                  border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(
                          flex: 1,
                          child: TextField(
                              controller: enderecoNumeroController,
                              decoration: const InputDecoration(
                                  labelText: 'Nº',
                                  border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: enderecoBairroController,
                              decoration: const InputDecoration(
                                  labelText: 'Bairro',
                                  border: OutlineInputBorder()))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: enderecoCidadeController,
                              decoration: const InputDecoration(
                                  labelText: 'Cidade',
                                  border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: enderecoEstadoSelecionado,
                          decoration: const InputDecoration(
                              labelText: 'Estado',
                              border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(
                                value: 'AC', child: Text('AC - Acre')),
                            DropdownMenuItem(
                                value: 'AL', child: Text('AL - Alagoas')),
                            DropdownMenuItem(
                                value: 'AP', child: Text('AP - Amapá')),
                            DropdownMenuItem(
                                value: 'AM', child: Text('AM - Amazonas')),
                            DropdownMenuItem(
                                value: 'BA', child: Text('BA - Bahia')),
                            DropdownMenuItem(
                                value: 'CE', child: Text('CE - Ceará')),
                            DropdownMenuItem(
                                value: 'DF',
                                child: Text('DF - Distrito Federal')),
                            DropdownMenuItem(
                                value: 'ES',
                                child: Text('ES - Espírito Santo')),
                            DropdownMenuItem(
                                value: 'GO', child: Text('GO - Goiás')),
                            DropdownMenuItem(
                                value: 'MA', child: Text('MA - Maranhão')),
                            DropdownMenuItem(
                                value: 'MT', child: Text('MT - Mato Grosso')),
                            DropdownMenuItem(
                                value: 'MS',
                                child: Text('MS - Mato Grosso do Sul')),
                            DropdownMenuItem(
                                value: 'MG', child: Text('MG - Minas Gerais')),
                            DropdownMenuItem(
                                value: 'PA', child: Text('PA - Pará')),
                            DropdownMenuItem(
                                value: 'PB', child: Text('PB - Paraíba')),
                            DropdownMenuItem(
                                value: 'PR', child: Text('PR - Paraná')),
                            DropdownMenuItem(
                                value: 'PE', child: Text('PE - Pernambuco')),
                            DropdownMenuItem(
                                value: 'PI', child: Text('PI - Piauí')),
                            DropdownMenuItem(
                                value: 'RJ',
                                child: Text('RJ - Rio de Janeiro')),
                            DropdownMenuItem(
                                value: 'RN',
                                child: Text('RN - Rio Grande do Norte')),
                            DropdownMenuItem(
                                value: 'RS',
                                child: Text('RS - Rio Grande do Sul')),
                            DropdownMenuItem(
                                value: 'RO', child: Text('RO - Rondônia')),
                            DropdownMenuItem(
                                value: 'RR', child: Text('RR - Roraima')),
                            DropdownMenuItem(
                                value: 'SC',
                                child: Text('SC - Santa Catarina')),
                            DropdownMenuItem(
                                value: 'SP', child: Text('SP - São Paulo')),
                            DropdownMenuItem(
                                value: 'SE', child: Text('SE - Sergipe')),
                            DropdownMenuItem(
                                value: 'TO', child: Text('TO - Tocantins')),
                          ],
                          onChanged: (value) => setDialogState(
                              () => enderecoEstadoSelecionado = value!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: enderecoCepController,
                              decoration: const InputDecoration(
                                  labelText: 'CEP',
                                  border: OutlineInputBorder(),
                                  hintText: '00000-000'))),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Dados espirituais
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: dataConversaoController,
                              decoration: const InputDecoration(
                                  labelText: 'Data de Conversão',
                                  border: OutlineInputBorder(),
                                  hintText: 'DD/MM/AAAA'),
                              keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextField(
                              controller: dataBatismoController,
                              decoration: const InputDecoration(
                                  labelText: 'Data de Batismo',
                                  border: OutlineInputBorder(),
                                  hintText: 'DD/MM/AAAA'),
                              keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: igrejaBatismoController,
                      decoration: const InputDecoration(
                          labelText: 'Igreja onde foi batizado',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                          child: DropdownButtonFormField<String>(
                        value: cargoSelecionado,
                        decoration: const InputDecoration(
                            labelText: 'Cargo/Função',
                            border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: 'Membro', child: Text('Membro')),
                          DropdownMenuItem(
                              value: 'Diácono', child: Text('Diácono')),
                          DropdownMenuItem(
                              value: 'Presbítero', child: Text('Presbítero')),
                          DropdownMenuItem(
                              value: 'Pastor', child: Text('Pastor')),
                          DropdownMenuItem(
                              value: 'Missionário(a)',
                              child: Text('Missionário(a)')),
                          DropdownMenuItem(
                              value: 'Evangelista', child: Text('Evangelista')),
                          DropdownMenuItem(
                              value: 'Outros', child: Text('Outros')),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => cargoSelecionado = value!),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: DropdownButtonFormField<String>(
                        value: situacaoSelecionada,
                        decoration: const InputDecoration(
                            labelText: 'Situação',
                            border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: 'Ativo', child: Text('Ativo')),
                          DropdownMenuItem(
                              value: 'Afastado', child: Text('Afastado')),
                          DropdownMenuItem(
                              value: 'Transferido', child: Text('Transferido')),
                          DropdownMenuItem(
                              value: 'Falecido', child: Text('Falecido')),
                          DropdownMenuItem(
                              value: 'Outros', child: Text('Outros')),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => situacaoSelecionada = value!),
                      )),
                    ],
                  ),

                  const SizedBox(height: 12),
                  TextField(
                      controller: ministeriosController,
                      decoration: const InputDecoration(
                          labelText: 'Ministério(s) que participa',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),

                  // Familiares
                  TextField(
                      controller: nomeConjugeController,
                      decoration: const InputDecoration(
                          labelText: 'Nome do Cônjuge',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: filhosController,
                      decoration: const InputDecoration(
                          labelText: 'Filhos (nomes e idades)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: nomeResponsavelController,
                      decoration: const InputDecoration(
                          labelText: 'Nome do Responsável (se menor)',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: tipoMembroSelecionado,
                    decoration: const InputDecoration(
                        labelText: 'Tipo de Membro',
                        border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'Novo convertido',
                          child: Text('Novo convertido')),
                      DropdownMenuItem(
                          value: 'Transferido', child: Text('Transferido')),
                      DropdownMenuItem(
                          value: 'Visitante', child: Text('Visitante')),
                      DropdownMenuItem(
                          value: 'Membro antigo', child: Text('Membro antigo')),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => tipoMembroSelecionado = value!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: observacoesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Observações Pastorais',
                          border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.red))),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final updates = {
                      'nome_completo': nomeController.text.trim(),
                      'sexo': sexoSelecionado,
                      'estado_civil': estadoCivilSelecionado,
                      'escolaridade': escolaridadeSelecionada,
                      'cargo_funcao': cargoSelecionado,
                      'situacao_atual': situacaoSelecionada,
                      'tipo_membro': tipoMembroSelecionado,
                      'endereco_estado': enderecoEstadoSelecionado,
                      'data_nascimento':
                          _parseDateToIso(dataNascimentoController.text),
                      'data_nascimento_raw':
                          dataNascimentoController.text.trim().isNotEmpty
                              ? dataNascimentoController.text.trim()
                              : null,
                      'cpf': cpfController.text.trim().isNotEmpty
                          ? cpfController.text.trim()
                          : null,
                      'rg': rgController.text.trim().isNotEmpty
                          ? rgController.text.trim()
                          : null,
                      'telefone': telefoneController.text.trim().isNotEmpty
                          ? telefoneController.text.trim()
                          : null,
                      'email': emailController.text.trim().isNotEmpty
                          ? emailController.text.trim()
                          : null,
                      'endereco_rua':
                          enderecoRuaController.text.trim().isNotEmpty
                              ? enderecoRuaController.text.trim()
                              : null,
                      'endereco_numero':
                          enderecoNumeroController.text.trim().isNotEmpty
                              ? enderecoNumeroController.text.trim()
                              : null,
                      'endereco_bairro':
                          enderecoBairroController.text.trim().isNotEmpty
                              ? enderecoBairroController.text.trim()
                              : null,
                      'endereco_cidade':
                          enderecoCidadeController.text.trim().isNotEmpty
                              ? enderecoCidadeController.text.trim()
                              : null,
                      'endereco_cep':
                          enderecoCepController.text.trim().isNotEmpty
                              ? enderecoCepController.text.trim()
                              : null,
                      'data_conversao':
                          _parseDateToIso(dataConversaoController.text),
                      'data_conversao_raw':
                          dataConversaoController.text.trim().isNotEmpty
                              ? dataConversaoController.text.trim()
                              : null,
                      'data_batismo':
                          _parseDateToIso(dataBatismoController.text),
                      'data_batismo_raw':
                          dataBatismoController.text.trim().isNotEmpty
                              ? dataBatismoController.text.trim()
                              : null,
                      'igreja_batismo':
                          igrejaBatismoController.text.trim().isNotEmpty
                              ? igrejaBatismoController.text.trim()
                              : null,
                      'ministerios':
                          ministeriosController.text.trim().isNotEmpty
                              ? ministeriosController.text.trim()
                              : null,
                      'nome_conjuge':
                          nomeConjugeController.text.trim().isNotEmpty
                              ? nomeConjugeController.text.trim()
                              : null,
                      'filhos': filhosController.text.trim().isNotEmpty
                          ? filhosController.text.trim()
                          : null,
                      'nome_responsavel':
                          nomeResponsavelController.text.trim().isNotEmpty
                              ? nomeResponsavelController.text.trim()
                              : null,
                      'observacoes_pastorais':
                          observacoesController.text.trim().isNotEmpty
                              ? observacoesController.text.trim()
                              : null,
                    };

                    await supabase
                        .from('membros')
                        .update(updates)
                        .eq('id', membro['id']);
                    Navigator.pop(context);
                    _carregarMembros();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Membro atualizado com sucesso')));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Erro ao atualizar membro: $e')));
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(int id, String? nome) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content:
            Text('Deseja realmente excluir o membro "${nome ?? 'Sem nome'}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await supabase.from('membros').delete().eq('id', id);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Membro excluído')));
        _carregarMembros();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
      }
    }
  }

  void _abrirDialogoCadastrarMembro() {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController();
    final dataNascimentoController = MaskedTextController(mask: '00/00/0000');
    final cpfController = MaskedTextController(mask: '000.000.000-00');
    final rgController = TextEditingController();
    final telefoneController = MaskedTextController(mask: '(00) 00000-0000');
    final emailController = TextEditingController();
    final enderecoRuaController = TextEditingController();
    final enderecoNumeroController = TextEditingController();
    final enderecoBairroController = TextEditingController();
    final enderecoCidadeController = TextEditingController();
    final enderecoCepController = MaskedTextController(mask: '00000-000');
    final dataConversaoController = MaskedTextController(mask: '00/00/0000');
    final dataBatismoController = MaskedTextController(mask: '00/00/0000');
    final igrejaBatismoController = TextEditingController();
    final ministeriosController = TextEditingController();
    final nomeConjugeController = TextEditingController();
    final filhosController = TextEditingController();
    final nomeResponsavelController = TextEditingController();
    final observacoesController = TextEditingController();

    String sexoSelecionado = 'Masculino';
    String estadoCivilSelecionado = 'Solteiro';
    String cargoSelecionado = 'Membro';
    String situacaoSelecionada = 'Ativo';
    String tipoMembroSelecionado = 'Membro antigo';
    String enderecoEstadoSelecionado = 'GO';
    String escolaridadeSelecionada = 'Ensino Fundamental';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Cadastrar Membro',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dados Pessoais
                  const Text(
                    'Dados Pessoais',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome Completo *',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16),
                    validator: (value) =>
                        value?.isEmpty == true ? 'Nome é obrigatório' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dataNascimentoController,
                          decoration: const InputDecoration(
                            labelText: 'Data de Nascimento',
                            border: OutlineInputBorder(),
                            hintText: 'DD/MM/AAAA',
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: sexoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Sexo',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Masculino', child: Text('Masculino')),
                            DropdownMenuItem(
                                value: 'Feminino', child: Text('Feminino')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              sexoSelecionado = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: estadoCivilSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Estado Civil',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Solteiro', child: Text('Solteiro')),
                      DropdownMenuItem(value: 'Casado', child: Text('Casado')),
                      DropdownMenuItem(
                          value: 'Divorciado', child: Text('Divorciado')),
                      DropdownMenuItem(value: 'Viúvo', child: Text('Viúvo')),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        estadoCivilSelecionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: escolaridadeSelecionada,
                    decoration: const InputDecoration(
                      labelText: 'Escolaridade',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Analfabeto', child: Text('Analfabeto')),
                      DropdownMenuItem(
                          value: 'Ensino Fundamental Incompleto',
                          child: Text('Ensino Fundamental Incompleto')),
                      DropdownMenuItem(
                          value: 'Ensino Fundamental',
                          child: Text('Ensino Fundamental')),
                      DropdownMenuItem(
                          value: 'Ensino Médio Incompleto',
                          child: Text('Ensino Médio Incompleto')),
                      DropdownMenuItem(
                          value: 'Ensino Médio', child: Text('Ensino Médio')),
                      DropdownMenuItem(
                          value: 'Ensino Superior Incompleto',
                          child: Text('Ensino Superior Incompleto')),
                      DropdownMenuItem(
                          value: 'Ensino Superior',
                          child: Text('Ensino Superior')),
                      DropdownMenuItem(
                          value: 'Pós-graduação', child: Text('Pós-graduação')),
                      DropdownMenuItem(
                          value: 'Mestrado', child: Text('Mestrado')),
                      DropdownMenuItem(
                          value: 'Doutorado', child: Text('Doutorado')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        escolaridadeSelecionada = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cpfController,
                          decoration: const InputDecoration(
                            labelText: 'CPF',
                            border: OutlineInputBorder(),
                            hintText: '000.000.000-00',
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: rgController,
                          decoration: const InputDecoration(
                            labelText: 'RG',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: telefoneController,
                          decoration: const InputDecoration(
                            labelText: 'Telefone/WhatsApp',
                            border: OutlineInputBorder(),
                            hintText: '(00) 00000-0000',
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Endereço
                  const Text(
                    'Endereço',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: enderecoRuaController,
                          decoration: const InputDecoration(
                            labelText: 'Rua',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: enderecoNumeroController,
                          decoration: const InputDecoration(
                            labelText: 'Nº',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: enderecoBairroController,
                          decoration: const InputDecoration(
                            labelText: 'Bairro',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: enderecoCidadeController,
                          decoration: const InputDecoration(
                            labelText: 'Cidade',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: enderecoEstadoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Estado',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'AC', child: Text('AC - Acre')),
                            DropdownMenuItem(
                                value: 'AL', child: Text('AL - Alagoas')),
                            DropdownMenuItem(
                                value: 'AP', child: Text('AP - Amapá')),
                            DropdownMenuItem(
                                value: 'AM', child: Text('AM - Amazonas')),
                            DropdownMenuItem(
                                value: 'BA', child: Text('BA - Bahia')),
                            DropdownMenuItem(
                                value: 'CE', child: Text('CE - Ceará')),
                            DropdownMenuItem(
                                value: 'DF',
                                child: Text('DF - Distrito Federal')),
                            DropdownMenuItem(
                                value: 'ES',
                                child: Text('ES - Espírito Santo')),
                            DropdownMenuItem(
                                value: 'GO', child: Text('GO - Goiás')),
                            DropdownMenuItem(
                                value: 'MA', child: Text('MA - Maranhão')),
                            DropdownMenuItem(
                                value: 'MT', child: Text('MT - Mato Grosso')),
                            DropdownMenuItem(
                                value: 'MS',
                                child: Text('MS - Mato Grosso do Sul')),
                            DropdownMenuItem(
                                value: 'MG', child: Text('MG - Minas Gerais')),
                            DropdownMenuItem(
                                value: 'PA', child: Text('PA - Pará')),
                            DropdownMenuItem(
                                value: 'PB', child: Text('PB - Paraíba')),
                            DropdownMenuItem(
                                value: 'PR', child: Text('PR - Paraná')),
                            DropdownMenuItem(
                                value: 'PE', child: Text('PE - Pernambuco')),
                            DropdownMenuItem(
                                value: 'PI', child: Text('PI - Piauí')),
                            DropdownMenuItem(
                                value: 'RJ',
                                child: Text('RJ - Rio de Janeiro')),
                            DropdownMenuItem(
                                value: 'RN',
                                child: Text('RN - Rio Grande do Norte')),
                            DropdownMenuItem(
                                value: 'RS',
                                child: Text('RS - Rio Grande do Sul')),
                            DropdownMenuItem(
                                value: 'RO', child: Text('RO - Rondônia')),
                            DropdownMenuItem(
                                value: 'RR', child: Text('RR - Roraima')),
                            DropdownMenuItem(
                                value: 'SC',
                                child: Text('SC - Santa Catarina')),
                            DropdownMenuItem(
                                value: 'SP', child: Text('SP - São Paulo')),
                            DropdownMenuItem(
                                value: 'SE', child: Text('SE - Sergipe')),
                            DropdownMenuItem(
                                value: 'TO', child: Text('TO - Tocantins')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              enderecoEstadoSelecionado = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: enderecoCepController,
                          decoration: const InputDecoration(
                            labelText: 'CEP',
                            border: OutlineInputBorder(),
                            hintText: '00000-000',
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dados Espirituais
                  const Text(
                    'Dados Espirituais',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dataConversaoController,
                          decoration: const InputDecoration(
                            labelText: 'Data de Conversão',
                            border: OutlineInputBorder(),
                            hintText: 'DD/MM/AAAA',
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: dataBatismoController,
                          decoration: const InputDecoration(
                            labelText: 'Data de Batismo',
                            border: OutlineInputBorder(),
                            hintText: 'DD/MM/AAAA',
                          ),
                          style: const TextStyle(fontSize: 16),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: igrejaBatismoController,
                    decoration: const InputDecoration(
                      labelText: 'Igreja onde foi batizado',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: cargoSelecionado,
                          decoration: const InputDecoration(
                            labelText: 'Cargo/Função',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Membro', child: Text('Membro')),
                            DropdownMenuItem(
                                value: 'Diácono', child: Text('Diácono')),
                            DropdownMenuItem(
                                value: 'Presbítero', child: Text('Presbítero')),
                            DropdownMenuItem(
                                value: 'Pastor', child: Text('Pastor')),
                            DropdownMenuItem(
                                value: 'Missionário(a)',
                                child: Text('Missionário(a)')),
                            DropdownMenuItem(
                                value: 'Evangelista',
                                child: Text('Evangelista')),
                            DropdownMenuItem(
                                value: 'Outros', child: Text('Outros')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              cargoSelecionado = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: situacaoSelecionada,
                          decoration: const InputDecoration(
                            labelText: 'Situação',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Ativo', child: Text('Ativo')),
                            DropdownMenuItem(
                                value: 'Afastado', child: Text('Afastado')),
                            DropdownMenuItem(
                                value: 'Transferido',
                                child: Text('Transferido')),
                            DropdownMenuItem(
                                value: 'Falecido', child: Text('Falecido')),
                            DropdownMenuItem(
                                value: 'Outros', child: Text('Outros')),
                          ],
                          onChanged: (value) {
                            setDialogState(() {
                              situacaoSelecionada = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: ministeriosController,
                    decoration: const InputDecoration(
                      labelText: 'Ministério(s) que participa',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Dados Familiares
                  const Text(
                    'Dados Familiares',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: nomeConjugeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Cônjuge',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: filhosController,
                    decoration: const InputDecoration(
                      labelText: 'Filhos (nomes e idades)',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nomeResponsavelController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Responsável (se menor)',
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Informações Complementares
                  const Text(
                    'Informações Complementares',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: tipoMembroSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Membro',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'Novo convertido',
                          child: Text('Novo convertido')),
                      DropdownMenuItem(
                          value: 'Transferido', child: Text('Transferido')),
                      DropdownMenuItem(
                          value: 'Visitante', child: Text('Visitante')),
                      DropdownMenuItem(
                          value: 'Membro antigo', child: Text('Membro antigo')),
                      DropdownMenuItem(value: 'Outros', child: Text('Outros')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        tipoMembroSelecionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: observacoesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observações Pastorais',
                      border: OutlineInputBorder(),
                      hintText:
                          'Ex: acompanhamento, discipulado, saúde espiritual',
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Campo de Foto
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Foto do Membro',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Funcionalidade em desenvolvimento',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Upload de foto será implementado em breve'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload),
                          label: const Text('Selecionar Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF42A5F5),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                if (formKey.currentState!.validate()) {
                  try {
                    // Preparar dados para inserção - apenas nome é obrigatório
                    Map<String, dynamic> dadosMembro = {
                      'nome_completo': nomeController.text.trim(),
                      'sexo': sexoSelecionado,
                      'estado_civil': estadoCivilSelecionado,
                      'escolaridade': escolaridadeSelecionada,
                      'cargo_funcao': cargoSelecionado,
                      'situacao_atual': situacaoSelecionada,
                      'tipo_membro': tipoMembroSelecionado,
                      'endereco_estado': enderecoEstadoSelecionado,
                      // enviar data convertida (ISO) e também a string bruta para auditoria
                      'data_nascimento':
                          _parseDateToIso(dataNascimentoController.text),
                      'data_nascimento_raw':
                          dataNascimentoController.text.trim().isNotEmpty
                              ? dataNascimentoController.text.trim()
                              : null,
                      'cpf': cpfController.text.trim().isNotEmpty
                          ? cpfController.text.trim()
                          : null,
                      'rg': rgController.text.trim().isNotEmpty
                          ? rgController.text.trim()
                          : null,
                      'telefone': telefoneController.text.trim().isNotEmpty
                          ? telefoneController.text.trim()
                          : null,
                      'email': emailController.text.trim().isNotEmpty
                          ? emailController.text.trim()
                          : null,
                      'endereco_rua':
                          enderecoRuaController.text.trim().isNotEmpty
                              ? enderecoRuaController.text.trim()
                              : null,
                      'endereco_numero':
                          enderecoNumeroController.text.trim().isNotEmpty
                              ? enderecoNumeroController.text.trim()
                              : null,
                      'endereco_bairro':
                          enderecoBairroController.text.trim().isNotEmpty
                              ? enderecoBairroController.text.trim()
                              : null,
                      'endereco_cidade':
                          enderecoCidadeController.text.trim().isNotEmpty
                              ? enderecoCidadeController.text.trim()
                              : null,
                      'endereco_cep':
                          enderecoCepController.text.trim().isNotEmpty
                              ? enderecoCepController.text.trim()
                              : null,
                      'data_conversao':
                          _parseDateToIso(dataConversaoController.text),
                      'data_conversao_raw':
                          dataConversaoController.text.trim().isNotEmpty
                              ? dataConversaoController.text.trim()
                              : null,
                      'data_batismo':
                          _parseDateToIso(dataBatismoController.text),
                      'data_batismo_raw':
                          dataBatismoController.text.trim().isNotEmpty
                              ? dataBatismoController.text.trim()
                              : null,
                      'igreja_batismo':
                          igrejaBatismoController.text.trim().isNotEmpty
                              ? igrejaBatismoController.text.trim()
                              : null,
                      'ministerios':
                          ministeriosController.text.trim().isNotEmpty
                              ? ministeriosController.text.trim()
                              : null,
                      'nome_conjuge':
                          nomeConjugeController.text.trim().isNotEmpty
                              ? nomeConjugeController.text.trim()
                              : null,
                      'filhos': filhosController.text.trim().isNotEmpty
                          ? filhosController.text.trim()
                          : null,
                      'nome_responsavel':
                          nomeResponsavelController.text.trim().isNotEmpty
                              ? nomeResponsavelController.text.trim()
                              : null,
                      'observacoes_pastorais':
                          observacoesController.text.trim().isNotEmpty
                              ? observacoesController.text.trim()
                              : null,
                    };

                    await supabase.from('membros').insert(dadosMembro);

                    Navigator.pop(context);
                    _carregarMembros();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Membro cadastrado com sucesso!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao cadastrar membro: $e')),
                    );
                  }
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

  Color _getSituacaoColor(String situacao) {
    switch (situacao.toLowerCase()) {
      case 'ativo':
        return Colors.green;
      case 'afastado':
        return Colors.orange;
      case 'transferido':
        return Colors.blue;
      case 'falecido':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Membros'),
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
                        'Gerenciar Membros',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cadastre e gerencie os membros da igreja',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar membro',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchTerm = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (v) => setState(() => _searchTerm = v.trim()),
                  ),
                ),

                // List
                Expanded(
                  child: _membros.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum membro cadastrado',
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                        )
                      : Builder(builder: (context) {
                          final displayed = _searchTerm.isEmpty
                              ? _membros
                              : _membros.where((m) {
                                  final nome = (m['nome_completo'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  final codigo = (m['codigo_membro'] ?? '')
                                      .toString()
                                      .toLowerCase();
                                  final cpf =
                                      (m['cpf'] ?? '').toString().toLowerCase();
                                  final term = _searchTerm.toLowerCase();
                                  return nome.contains(term) ||
                                      codigo.contains(term) ||
                                      cpf.contains(term);
                                }).toList();

                          return ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: displayed.length,
                            itemBuilder: (context, index) {
                              final membro = displayed[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getSituacaoColor(
                                        membro['situacao_atual']),
                                    child: Text(
                                      membro['nome_completo']
                                              ?.toString()
                                              .substring(0, 1)
                                              .toUpperCase() ??
                                          'M',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    membro['nome_completo'] ?? 'Sem nome',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Código: ${membro['codigo_membro'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        'Cargo: ${membro['cargo_funcao'] ?? 'Não definido'}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: _getSituacaoColor(
                                              membro['situacao_atual']),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Situação: ${membro['situacao_atual'] ?? 'Não definida'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _getSituacaoColor(
                                              membro['situacao_atual']),
                                          fontWeight: FontWeight.w500,
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
                                            _abrirDialogoEditarMembro(membro),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _confirmDelete(
                                            membro['id'] as int,
                                            membro['nome_completo']),
                                        tooltip: 'Excluir',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirDialogoCadastrarMembro,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Membro'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
      ),
    );
  }
}
