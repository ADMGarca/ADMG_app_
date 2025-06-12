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

class TesoureiroMasterPage extends StatefulWidget {
  final String usuarioId;
  final String usuarioNome;
  final String usuarioSetor;
  final String usuarioCargo;
  final bool isMaster;
  final String? setorInicial;

  const TesoureiroMasterPage({
    super.key,
    required this.usuarioId,
    required this.usuarioNome,
    required this.usuarioSetor,
    required this.usuarioCargo,
    required this.isMaster,
    this.setorInicial,
  });

  @override
  _TesoureiroMasterPageState createState() => _TesoureiroMasterPageState();
}

class _TesoureiroMasterPageState extends State<TesoureiroMasterPage> {
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
  String? _setorFiltroSelecionado;

  @override
  void initState() {
    super.initState();
    _idUsuario = widget.usuarioId;
    _nomeUsuario = widget.usuarioNome;
    _setorUsuario = widget.usuarioSetor;
    _isMaster = widget.isMaster;
    _setorFiltroSelecionado = widget.setorInicial;
    _initTesoureiroMaster();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _initTesoureiroMaster() async {
    await _carregarSetoresDisponiveis();
    if (_setorFiltroSelecionado == null ||
        !_setoresDisponiveis.contains(_setorFiltroSelecionado)) {
      setState(() {
        _setorFiltroSelecionado = 'Todos os Setores';
      });
    }
    await _carregarTransacoes();
  }

  Future<void> _carregarSetoresDisponiveis() async {
    try {
      final response = await supabase.from('setor').select('nome');
      if (response != null && response.isNotEmpty) {
        final List<String> fetchedSetores = List<String>.from(
            response.map((s) => s['nome'].toString().trim().toLowerCase()));
        setState(() {
          _setoresDisponiveis = ['Todos os Setores', ...fetchedSetores];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar setores: $e')),
      );
    }
  }

  Future<void> _carregarTransacoes() async {
    try {
      var query = supabase.from('transacoes').select('*, usuario (nome)');
      if (_setorFiltroSelecionado != null &&
          _setorFiltroSelecionado != 'Todos os Setores') {
        final filterValue = _setorFiltroSelecionado!.trim().toLowerCase();
        query = query.ilike('setor', filterValue);
      }
      final response = await query.order('data', ascending: false);
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

  Future<void> _adicionarTransacao() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idUsuario.isEmpty || int.tryParse(_idUsuario) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Erro: ID do usuário não encontrado. Por favor, deslogue e logue novamente para atualizar as credenciais.'),
        ),
      );
      return;
    }

    try {
      final String valorText = _valorController.text
          .trim()
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      final double valor = double.parse(valorText);

      final setor = _setorFiltroSelecionado?.toLowerCase();
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
      lastDate: DateTime(2101),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  void _trocarMesFiltro(int meses) {
    setState(() {
      _mesFiltro = DateTime(_mesFiltro.year, _mesFiltro.month + meses, 1);
    });
    _filtrarTransacoesPorMes();
  }

  Future<void> _exportarExtratoPDF() async {
    int testemunhas = 2;
    List<String> nomesTestemunhas = List.filled(testemunhas, '');
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
    final font = await PdfGoogleFonts.notoSansRegular();

    final pdf = pw.Document();
    final mesAno = DateFormat('MM/yyyy', 'pt_BR').format(_mesFiltro);
    final dataHoje = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final transacoesOrdenadas = [
            ..._transacoesFiltradas.where((t) => t['tipo'] == 'entrada'),
            ..._transacoesFiltradas.where((t) => t['tipo'] == 'saida'),
          ];
          return [
            pw.Center(
              child: pw.Text(
                'Extrato Mensal de Transações - $mesAno',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold, font: font),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Setor: ${_setorFiltroSelecionado ?? 'N/A'}',
              style: pw.TextStyle(fontSize: 18, font: font),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Data', 'Tipo', 'Descrição', 'Valor', 'Adicionado por'],
              data: transacoesOrdenadas.map((transacao) {
                final valorFormatado =
                    'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(transacao['valor'])}';
                final tipoTexto =
                    transacao['tipo'] == 'entrada' ? 'Entrada' : 'Saída';
                final nomeUsuarioAdd = transacao['usuario'] != null &&
                        transacao['usuario']['nome'] != null
                    ? transacao['usuario']['nome']
                    : 'Desconhecido';
                return [
                  DateFormat('dd/MM/yyyy')
                      .format(DateTime.parse(transacao['data'])),
                  pw.Text(
                    tipoTexto,
                    style: pw.TextStyle(
                      color: transacao['tipo'] == 'entrada'
                          ? PdfColors.green
                          : PdfColors.red,
                      font: font,
                    ),
                  ),
                  transacao['descricao'],
                  valorFormatado,
                  nomeUsuarioAdd,
                ];
              }).toList(),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, font: font),
              cellStyle: pw.TextStyle(font: font),
              border: pw.TableBorder.all(),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              rowDecoration: pw.BoxDecoration(
                color: PdfColors.white,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Entradas: R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(_totalEntradas)}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                          font: font),
                    ),
                    pw.Text(
                      'Total Saídas: R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(_totalSaidas)}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                          font: font),
                    ),
                    pw.Text(
                      'Saldo Atual: R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(_saldoAtual)}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, font: font),
                    ),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.center,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 30), // Espaço antes das assinaturas
                  ...testemunhas.map((nome) => pw.Column(
                        children: [
                          pw.SizedBox(
                              height: 10), // Espaço entre as assinaturas
                          pw.Container(
                              width: 200, height: 1, color: PdfColors.black),
                          pw.Text(nome, style: pw.TextStyle(font: font)),
                          pw.SizedBox(height: 20), // Espaço após cada nome
                        ],
                      )),
                  pw.SizedBox(height: 30), // Espaço antes do local/data
                  pw.Text(
                      '\n\n${_setorFiltroSelecionado ?? ''}, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                      style: pw.TextStyle(font: font)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'extrato_tesouraria_${DateFormat('MM_yyyy').format(_mesFiltro)}.pdf');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tesouraria Master'),
        backgroundColor: const Color(0xFF42A5F5),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text('Exportar PDF',
                style: TextStyle(color: Colors.white)),
            onPressed: _exportarExtratoPDF,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
              );
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            // Layout para telas largas (web, tablet horizontal)
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Dropdown para selecionar o setor para filtragem (largura total)
                  DropdownButtonFormField<String>(
                    value: _setorFiltroSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Setor',
                      border: OutlineInputBorder(),
                    ),
                    items: _setoresDisponiveis.map((String setor) {
                      return DropdownMenuItem<String>(
                        value: setor,
                        child: Text(setor),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _setorFiltroSelecionado = newValue;
                        });
                        _carregarTransacoes();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formulário de Adição/Edição de Transação
                      Expanded(
                        child: Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(right: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _editando
                                        ? 'Editar Transação'
                                        : 'Adicionar Nova Transação',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
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
                                        return 'Por favor, insira uma descrição';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _valorController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Valor (R\$)',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira um valor';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.calendar_today),
                                        onPressed: () =>
                                            _selecionarData(context),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('Entrada'),
                                          value: 'entrada',
                                          groupValue: _tipoTransacao,
                                          onChanged: (value) {
                                            setState(() {
                                              _tipoTransacao = value!;
                                            });
                                          },
                                        ),
                                      ),
                                      Expanded(
                                        child: RadioListTile<String>(
                                          title: const Text('Saída'),
                                          value: 'saida',
                                          groupValue: _tipoTransacao,
                                          onChanged: (value) {
                                            setState(() {
                                              _tipoTransacao = value!;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _adicionarTransacao,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueAccent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: Text(_editando
                                        ? 'Salvar Edição'
                                        : 'Adicionar Transação'),
                                  ),
                                  if (_editando)
                                    TextButton(
                                      onPressed: _limparFormulario,
                                      child: const Text('Cancelar Edição'),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Saldos e Filtro por Mês
                      Expanded(
                        child: Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(left: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Saldo Atual:',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    Text(
                                      'R\$ ${NumberFormat.currency(locale: 'pt_BR', symbol: '', decimalDigits: 2).format(_saldoAtual)}',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold),
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Lista de Transações (largura total)
                  _transacoesFiltradas.isEmpty
                      ? Center(
                          child: Text(
                              'Nenhuma transação encontrada para ${DateFormat('MMMM yyyy', 'pt_BR').format(_mesFiltro)} neste setor.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transacoesFiltradas.length,
                          itemBuilder: (context, index) {
                            final transacao = _transacoesFiltradas[index];
                            final isEntrada = transacao['tipo'] == 'entrada';
                            final valorFormatado = NumberFormat.currency(
                                    locale: 'pt_BR',
                                    symbol: 'R\$ ',
                                    decimalDigits: 2)
                                .format(transacao['valor']);
                            final nomeUsuarioAdicionado =
                                transacao['usuario'] != null &&
                                        transacao['usuario']['nome'] != null
                                    ? transacao['usuario']['nome']
                                    : 'Desconhecido';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              child: ListTile(
                                isThreeLine: true,
                                leading: Icon(
                                  isEntrada
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isEntrada ? Colors.green : Colors.red,
                                ),
                                title: Text(transacao['descricao']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(transacao['data']))}',
                                    ),
                                    Text(
                                        'Adicionado por: $nomeUsuarioAdicionado'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      valorFormatado,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isEntrada
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _editarTransacao(transacao),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _excluirTransacao(
                                              transacao['id'].toString()),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            );
          } else {
            // Layout para telas pequenas (celular, tablet vertical)
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Dropdown para selecionar o setor para filtragem
                  DropdownButtonFormField<String>(
                    value: _setorFiltroSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Setor',
                      border: OutlineInputBorder(),
                    ),
                    items: _setoresDisponiveis.map((String setor) {
                      return DropdownMenuItem<String>(
                        value: setor,
                        child: Text(setor),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _setorFiltroSelecionado = newValue;
                        });
                        _carregarTransacoes();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Formulário de Adição/Edição de Transação
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _editando
                                  ? 'Editar Transação'
                                  : 'Adicionar Nova Transação',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
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
                                  return 'Por favor, insira uma descrição';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _valorController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Valor (R\$)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira um valor';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Data: ${DateFormat('dd/MM/yyyy').format(_dataSelecionada)}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  onPressed: () => _selecionarData(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Entrada'),
                                    value: 'entrada',
                                    groupValue: _tipoTransacao,
                                    onChanged: (value) {
                                      setState(() {
                                        _tipoTransacao = value!;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Saída'),
                                    value: 'saida',
                                    groupValue: _tipoTransacao,
                                    onChanged: (value) {
                                      setState(() {
                                        _tipoTransacao = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _adicionarTransacao,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(_editando
                                  ? 'Salvar Edição'
                                  : 'Adicionar Transação'),
                            ),
                            if (_editando)
                              TextButton(
                                onPressed: _limparFormulario,
                                child: const Text('Cancelar Edição'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Saldos e Filtro por Mês
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
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
                  // Lista de Transações
                  _transacoesFiltradas.isEmpty
                      ? Center(
                          child: Text(
                              'Nenhuma transação encontrada para ${DateFormat('MMMM yyyy', 'pt_BR').format(_mesFiltro)} neste setor.'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transacoesFiltradas.length,
                          itemBuilder: (context, index) {
                            final transacao = _transacoesFiltradas[index];
                            final isEntrada = transacao['tipo'] == 'entrada';
                            final valorFormatado = NumberFormat.currency(
                                    locale: 'pt_BR',
                                    symbol: 'R\$ ',
                                    decimalDigits: 2)
                                .format(transacao['valor']);
                            final nomeUsuarioAdicionado =
                                transacao['usuario'] != null &&
                                        transacao['usuario']['nome'] != null
                                    ? transacao['usuario']['nome']
                                    : 'Desconhecido';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 2,
                              child: ListTile(
                                isThreeLine: true,
                                leading: Icon(
                                  isEntrada
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: isEntrada ? Colors.green : Colors.red,
                                ),
                                title: Text(transacao['descricao']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(transacao['data']))}',
                                    ),
                                    Text(
                                        'Adicionado por: $nomeUsuarioAdicionado'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      valorFormatado,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isEntrada
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _editarTransacao(transacao),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () => _excluirTransacao(
                                              transacao['id'].toString()),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
