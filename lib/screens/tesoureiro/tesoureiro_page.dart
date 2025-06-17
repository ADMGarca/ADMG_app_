import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:admg_app/screens/login/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class TesoureiroPage extends StatefulWidget {
  final bool isMaster;
  final String? setor;
  final String usuarioId;
  final String usuarioNome;
  final String usuarioSetor;
  final String usuarioCargo;

  const TesoureiroPage(
      {super.key,
      this.isMaster = false,
      this.setor,
      required this.usuarioId,
      required this.usuarioNome,
      required this.usuarioSetor,
      required this.usuarioCargo});

  @override
  _TesoureiroPageState createState() => _TesoureiroPageState();
}

class _TesoureiroPageState extends State<TesoureiroPage> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = MoneyMaskedTextController(
    decimalSeparator: ',',
    thousandSeparator: '.',
    leftSymbol: 'R\$ ',
    precision: 2,
  );
  DateTime _dataSelecionada = DateTime.now();
  String _tipoTransacao = 'entrada';
  List<Map<String, dynamic>> _transacoes = [];
  List<Map<String, dynamic>> _transacoesFiltradas = [];
  double _totalEntradas = 0;
  double _totalSaidas = 0;
  double _saldoAtual = 0;
  DateTime _mesFiltro = DateTime.now();
  bool _editando = false;
  String _idTransacaoEditando = '';
  String _setorUsuario = '';
  String _idUsuario = '';
  String _nomeUsuario = '';
  bool _isMaster = false;
  List<String> _setoresDisponiveis = [];
  String _setorSelecionado = '';

  @override
  void initState() {
    super.initState();
    _idUsuario = widget.usuarioId;
    _nomeUsuario = widget.usuarioNome;
    _setorUsuario = widget.usuarioSetor;
    _isMaster = widget.isMaster;
    _setorSelecionado = widget.usuarioSetor;
    _initTesoureiro();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _initTesoureiro() async {
    // Os dados do usuário agora são passados diretamente para o construtor da TesoureiroPage
    // e inicializados em initState, então _carregarUsuarioLogado() não é mais necessário aqui.
    // Remove await _carregarUsuarioLogado();

    // Em seguida, sobrepõe com os valores passados via widget, se existirem.
    // Estes foram movidos para initState para garantir a inicialização antes de _initTesoureiro.

    // Se for um mestre, carrega os setores disponíveis.
    if (_isMaster) {
      await _carregarSetoresDisponiveis();
      // Se o setor selecionado ainda estiver vazio e houver setores disponíveis,
      // define o primeiro setor disponível como padrão para o mestre.
      if (_setorSelecionado.isEmpty && _setoresDisponiveis.isNotEmpty) {
        setState(() {
          _setorSelecionado = _setoresDisponiveis.first;
        });
      }
    }

    // Garante que _setorSelecionado tenha um valor, caindo para _setorUsuario se necessário.
    // Este agora é tratado pela inicialização em initState e pelo carregamento de setores.

    // Finalmente, carrega as transações com base no setor selecionado.
    await _carregarTransacoes();
  }

  Future<void> _carregarTransacoes() async {
    try {
      final response = await supabase
          .from('transacoes')
          .select('*, usuario (nome)')
          .eq('setor', _setorSelecionado)
          .order('data', ascending: false);

      if (response != null) {
        setState(() {
          _transacoes = List<Map<String, dynamic>>.from(response);
          _filtrarTransacoesPorMes();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar transações: $e')),
      );
    }
  }

  void _filtrarTransacoesPorMes() {
    final primeiroDiaMes = DateTime(_mesFiltro.year, _mesFiltro.month, 1);
    final ultimoDiaMes = DateTime(_mesFiltro.year, _mesFiltro.month + 1, 0);

    _transacoesFiltradas = _transacoes.where((transacao) {
      final data = DateTime.parse(transacao['data']);
      return data.isAfter(primeiroDiaMes.subtract(const Duration(days: 1))) &&
          data.isBefore(ultimoDiaMes.add(const Duration(days: 1)));
    }).toList();

    _calcularTotais();
  }

  void _calcularTotais() {
    _totalEntradas = 0;
    _totalSaidas = 0;

    for (var transacao in _transacoesFiltradas) {
      final valor = double.parse(transacao['valor'].toString());
      if (transacao['tipo'] == 'entrada') {
        _totalEntradas += valor;
      } else {
        _totalSaidas += valor;
      }
    }

    _saldoAtual = _totalEntradas - _totalSaidas;
  }

  void _trocarMesFiltro(int meses) {
    setState(() {
      final novoMes = _mesFiltro.month + meses;
      final novoAno = _mesFiltro.year + (novoMes ~/ 12);
      final mesAjustado = novoMes % 12;
      _mesFiltro = DateTime(novoAno, mesAjustado == 0 ? 12 : mesAjustado);
    });
    _filtrarTransacoesPorMes();
  }

  Future<void> _adicionarTransacao() async {
    if (!_formKey.currentState!.validate()) return;

    // A verificação de ID do usuário é mantida para feedback imediato.
    if (_idUsuario.isEmpty || int.tryParse(_idUsuario) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Erro: ID do usuário não encontrado. Por favor, deslogue e logue novamente para atualizar as credenciais.')),
      );
      return; // Impede a continuação da função
    }

    try {
      final String valorText = _valorController.text
          .trim()
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final double valor = double.parse(valorText);

      final setor = _setorSelecionado;
      final idUsuario = int.parse(_idUsuario);

      final dataFormatada = DateFormat('yyyy-MM-dd').format(_dataSelecionada);

      if (_editando) {
        await supabase.from('transacoes').update({
          'data': dataFormatada,
          'tipo': _tipoTransacao,
          'descricao': _descricaoController.text,
          'valor': valor,
          'setor': setor,
          'usuario_id': idUsuario,
        }).eq('id', _idTransacaoEditando);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação atualizada com sucesso!')),
        );
      } else {
        await supabase.from('transacoes').insert({
          'data': dataFormatada,
          'tipo': _tipoTransacao,
          'descricao': _descricaoController.text,
          'valor': valor,
          'setor': setor,
          'usuario_id': idUsuario,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transação adicionada com sucesso!')),
        );
      }

      _limparFormulario();
      _carregarTransacoes();
    } catch (e) {
      print('Erro ao adicionar transação: $e');
      if (e is FormatException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro de formato nos dados inseridos')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar transação: $e')),
        );
      }
    }
  }

  void _limparFormulario() {
    _descricaoController.clear();
    _valorController.clear();
    _dataSelecionada = DateTime.now();
    _tipoTransacao = 'entrada';
    _editando = false;
    _idTransacaoEditando = '';
  }

  Future<void> _editarTransacao(Map<String, dynamic> transacao) async {
    setState(() {
      _editando = true;
      _idTransacaoEditando = transacao['id'].toString();
      _descricaoController.text = transacao['descricao'];
      _valorController.updateValue(transacao['valor'].toDouble());
      _dataSelecionada = DateTime.parse(transacao['data']);
      _tipoTransacao = transacao['tipo'];
    });
  }

  Future<void> _excluirTransacao(String id) async {
    try {
      await supabase.from('transacoes').delete().eq('id', id);

      _carregarTransacoes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transação excluída com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir transação: $e')),
      );
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  Future<void> _selecionarMes(BuildContext context) async {
    int mesSelecionado = _mesFiltro.month;
    int anoSelecionado = _mesFiltro.year;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecionar mês e ano'),
          content: Row(
            children: [
              // Dropdown para mês
              Expanded(
                child: DropdownButton<int>(
                  value: mesSelecionado,
                  items: List.generate(12, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(DateFormat.MMMM('pt_BR')
                          .format(DateTime(0, index + 1))),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      mesSelecionado = value;
                      // Atualiza o estado do dialog
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Dropdown para ano
              Expanded(
                child: DropdownButton<int>(
                  value: anoSelecionado,
                  items: List.generate(30, (index) {
                    int ano = DateTime.now().year - 15 + index;
                    return DropdownMenuItem(
                      value: ano,
                      child: Text(ano.toString()),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null) {
                      anoSelecionado = value;
                      (context as Element).markNeedsBuild();
                    }
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _mesFiltro = DateTime(anoSelecionado, mesSelecionado);
                  _filtrarTransacoesPorMes();
                });
                Navigator.pop(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sair(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_nome');
    await prefs.remove('usuario_senha');
    await prefs.remove('usuario_id');
    await prefs.remove('usuario_setor');
    await prefs.remove('usuario_cargo');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _exportarExtratoPDF(BuildContext context) async {
    int testemunhas = 2;
    List<String> nomesTestemunhas = ['', ''];
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Testemunhas para o Extrato'),
          content: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Quantidade:'),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: testemunhas,
                          items: [2, 3, 4]
                              .map((qtd) => DropdownMenuItem(
                                    value: qtd,
                                    child: Text(qtd.toString()),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                testemunhas = value;
                                if (nomesTestemunhas.length < testemunhas) {
                                  nomesTestemunhas.addAll(List.filled(
                                      testemunhas - nomesTestemunhas.length,
                                      ''));
                                } else if (nomesTestemunhas.length >
                                    testemunhas) {
                                  nomesTestemunhas =
                                      nomesTestemunhas.sublist(0, testemunhas);
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    ...List.generate(
                        testemunhas,
                        (i) => Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextFormField(
                                initialValue: nomesTestemunhas[i],
                                decoration: InputDecoration(
                                    labelText: 'Nome da Testemunha ${i + 1}'),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Informe o nome'
                                    : null,
                                onChanged: (v) => nomesTestemunhas[i] = v,
                              ),
                            )),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, nomesTestemunhas);
                }
              },
              child: const Text('Gerar PDF'),
            ),
          ],
        );
      },
    ).then((result) async {
      if (result != null && result is List<String>) {
        await _gerarPDFExtrato(context, result);
      }
    });
  }

  Future<void> _gerarPDFExtrato(
      BuildContext context, List<String> testemunhas) async {
    final pdf = pw.Document();
    final font =
        pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final mesAno = DateFormat('MM/yyyy', 'pt_BR').format(_mesFiltro);
    final dataHoje = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final List<pw.Widget> linhas = [];

    linhas.add(
      pw.Text('Extrato Financeiro - $mesAno',
          style: pw.TextStyle(
              fontSize: 20, fontWeight: pw.FontWeight.bold, font: font)),
    );
    linhas.add(pw.SizedBox(height: 8));
    linhas.add(
        pw.Text('Data de emissão: $dataHoje', style: pw.TextStyle(font: font)));
    linhas.add(pw.SizedBox(height: 16));

    // Ordenar: entradas primeiro, depois saídas
    final transacoesOrdenadas = [
      ..._transacoesFiltradas.where((t) => t['tipo'] == 'entrada'),
      ..._transacoesFiltradas.where((t) => t['tipo'] == 'saida'),
    ];

    linhas.add(
      pw.Table(
        border: null,
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(2),
          3: const pw.FlexColumnWidth(1),
          4: const pw.FlexColumnWidth(2),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Text('Data',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
              pw.Text('Tipo',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
              pw.Text('Descrição',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
              pw.Text('Valor',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
              pw.Text('Lançado por',
                  style:
                      pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
            ],
          ),
          ...transacoesOrdenadas.map((t) {
            final isEntrada = t['tipo'] == 'entrada';
            final nomeUsuarioLancou = t['usuario']?['nome'] ?? '';
            return pw.TableRow(
              children: [
                pw.Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(t['data'])),
                    style: pw.TextStyle(font: font)),
                pw.Text(
                  isEntrada ? 'Entrada' : 'Saída',
                  style: pw.TextStyle(
                    color: isEntrada
                        ? PdfColor.fromInt(0xFF388E3C)
                        : PdfColor.fromInt(0xFFD32F2F),
                    font: font,
                  ),
                ),
                pw.Text(t['descricao'], style: pw.TextStyle(font: font)),
                pw.Text(
                    'R\$ ${double.parse(t['valor'].toString()).toStringAsFixed(2)}',
                    style: pw.TextStyle(font: font)),
                pw.Text(nomeUsuarioLancou, style: pw.TextStyle(font: font)),
              ],
            );
          }),
        ],
      ),
    );
    linhas.add(pw.SizedBox(height: 16));
    linhas.add(
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Total Entradas: R\$ ${_totalEntradas.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  color: PdfColor.fromInt(0xFF388E3C), font: font)),
          pw.Text('Total Saídas: R\$ ${_totalSaidas.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  color: PdfColor.fromInt(0xFFD32F2F), font: font)),
          pw.Text('Saldo: R\$ ${_saldoAtual.toStringAsFixed(2)}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font)),
        ],
      ),
    );
    linhas.add(pw.SizedBox(height: 32));

    // Assinaturas: linha para assinatura e nome centralizado embaixo
    for (final nome in testemunhas) {
      linhas.add(
        pw.Column(
          children: [
            pw.Container(
                height: 1, width: 200, color: PdfColor.fromInt(0xFF000000)),
            pw.SizedBox(height: 4),
            pw.Text(nome,
                style: pw.TextStyle(font: font),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 16),
          ],
        ),
      );
    }
    linhas.add(pw.SizedBox(height: 16));
    linhas.add(pw.Text('Local/Data: ___________________________',
        style: pw.TextStyle(fontSize: 14, font: font)));

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: linhas,
        ),
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'extrato_financeiro_${DateFormat('MM_yyyy').format(_mesFiltro)}.pdf');
  }

  Future<void> _carregarSetoresDisponiveis() async {
    final setores = await supabase
        .from('usuario')
        .select('setor')
        .neq('setor', '')
        .neq('setor', 'tesoureiro')
        .neq('setor', 'mesário')
        .neq('setor', 'dirigente');
    final setoresUnicos = setores
        .map<String>((e) => (e['setor'] ?? '').toString())
        .where((s) => s.isNotEmpty && s != 'null')
        .toSet()
        .toList();
    setState(() {
      _setoresDisponiveis = setoresUnicos;
      // Não define _setorSelecionado aqui, é tratado em _initTesoureiro
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMG - Tesoureiro'),
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
              Container(
                padding: const EdgeInsets.all(24.0),
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Color(0xFF42A5F5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Painel do Tesoureiro',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gerencie as finanças',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _editando
                                    ? 'Editar Transação'
                                    : 'Nova Transação',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_editando)
                                TextButton.icon(
                                  onPressed: _limparFormulario,
                                  icon: const Icon(Icons.close),
                                  label: const Text('Cancelar'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _tipoTransacao,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipo',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'entrada',
                                      child: Text('Entrada'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'saida',
                                      child: Text('Saída'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _tipoTransacao = value!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Data',
                                    border: const OutlineInputBorder(),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () => _selecionarData(context),
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: DateFormat('dd/MM/yyyy')
                                        .format(_dataSelecionada),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descricaoController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Digite uma descrição';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _valorController,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Digite um valor';
                              }
                              final cleanValue = value
                                  .replaceAll('R\$', '')
                                  .replaceAll('.', '')
                                  .replaceAll(',', '.')
                                  .trim();
                              if (double.tryParse(cleanValue) == null) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _adicionarTransacao,
                              child: Text(_editando
                                  ? 'Atualizar Transação'
                                  : 'Adicionar Transação'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_isMaster && _setoresDisponiveis.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Text('Setor:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _setorSelecionado,
                        items: _setoresDisponiveis
                            .map((setor) => DropdownMenuItem(
                                  value: setor,
                                  child: Text(setor),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _setorSelecionado = value!;
                          });
                          _carregarTransacoes();
                        },
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Entradas:',
                                style: TextStyle(fontSize: 18)),
                            Text(
                              'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(_totalEntradas)}',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.green),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Saídas:',
                                style: TextStyle(fontSize: 18)),
                            Text(
                              'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(_totalSaidas)}',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.red),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Saldo Atual:',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(
                              'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(_saldoAtual)}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_left),
                              onPressed: () => _trocarMesFiltro(-1),
                            ),
                            Text(
                              DateFormat('MMMM yyyy', 'pt_BR')
                                  .format(_mesFiltro),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_right),
                              onPressed: () => _trocarMesFiltro(1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _exportarExtratoPDF(context),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar Extrato (PDF)'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Histórico de Transações',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transacoesFiltradas.length,
                          itemBuilder: (context, index) {
                            final transacao = _transacoesFiltradas[index];
                            final valor =
                                double.parse(transacao['valor'].toString());
                            final data = DateTime.parse(transacao['data']);
                            final nomeUsuarioLancou =
                                transacao['usuario']?['nome'] ?? '';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  transacao['tipo'] == 'entrada'
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: transacao['tipo'] == 'entrada'
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                title: Text(transacao['descricao']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat('dd/MM/yyyy').format(data)),
                                    if (nomeUsuarioLancou.isNotEmpty)
                                      Text('Lançado por: $nomeUsuarioLancou',
                                          style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(valor)}',
                                      style: TextStyle(
                                        color: transacao['tipo'] == 'entrada'
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () =>
                                          _editarTransacao(transacao),
                                      tooltip: 'Editar',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                                'Confirmar exclusão'),
                                            content: const Text(
                                                'Tem certeza que deseja excluir esta transação?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _excluirTransacao(
                                                      transacao['id']);
                                                },
                                                child: const Text(
                                                  'Excluir',
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      tooltip: 'Excluir',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
