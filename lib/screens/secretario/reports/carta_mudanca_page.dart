import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:admg_app/utils/pdf_branding.dart';

class CartaMudancaPage extends StatefulWidget {
  const CartaMudancaPage({super.key});

  @override
  State<CartaMudancaPage> createState() => _CartaMudancaPageState();
}

class _CartaMudancaPageState extends State<CartaMudancaPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _membros = [];
  Map<String, dynamic>? _sel;

  final _cidade = TextEditingController(text: 'GARÇA');
  final _dataCarta = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final _pais1 = TextEditingController();
  final _pais2 = TextEditingController();
  final _profissao = TextEditingController();
  final _batismoEspirito = TextEditingController();
  final _consagracao = TextEditingController();
  bool _incluirFoto = true;

  String _fmtDate(dynamic iso, dynamic raw) {
    final rawStr = (raw ?? '').toString().trim();
    if (rawStr.isNotEmpty) return rawStr;
    final isoStr = (iso ?? '').toString().trim();
    if (isoStr.isEmpty) return '';
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(isoStr)); } catch (_) { return isoStr; }
  }

  BrandingInfo? _branding;
  Map<String, String> _signers = { 'secretario': '', 'pastor_presidente': '' };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mem = await supabase.from('membros').select('*').order('nome_completo');
    _membros = List<Map<String, dynamic>>.from(mem);
    _branding = await loadBrandingOrDefault();
    try {
      final s = await supabase.from('app_settings').select('value').eq('key', 'letter_signers').maybeSingle();
      if (s != null && s['value'] is Map<String, dynamic>) {
        final v = Map<String, dynamic>.from(s['value'] as Map);
        _signers = {
          'secretario': (v['secretario'] ?? '').toString(),
          'pastor_presidente': (v['pastor_presidente'] ?? '').toString(),
        };
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _export() async {
    if (_sel == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione um membro.')));
      return;
    }
    final doc = await newPdfDoc();

    // optional logo
    pw.ImageProvider? logo;
    final b = _branding ?? BrandingInfo.defaults();
    if (b.logoUrl != null) { try { logo = await networkImage(b.logoUrl!); } catch (_) {} }

    final nome = (_sel!['nome_completo'] ?? '').toString();
    final estadoCivil = (_sel!['estado_civil'] ?? '').toString();
    final cargo = (_sel!['cargo_funcao'] ?? '').toString();
    final consagracao = _consagracao.text.trim().isNotEmpty ? _consagracao.text.trim() : _fmtDate(_sel!['data_consagracao'], _sel!['data_consagracao_raw']);
    final batismoAguas = _fmtDate(_sel!['data_batismo'], _sel!['data_batismo_raw']);
    final batismoEspirito = _batismoEspirito.text.trim();
    final rg = (_sel!['rg'] ?? '').toString();
    final cpf = (_sel!['cpf'] ?? '').toString();
    final nasc = _fmtDate(_sel!['data_nascimento'], _sel!['data_nascimento_raw']);
    final escolaridade = (_sel!['escolaridade'] ?? '').toString();
    final profissao = _profissao.text.trim();
    final celular = (_sel!['telefone'] ?? '').toString();

    // Foto do membro (opcional)
    pw.ImageProvider? foto;
    if (_incluirFoto) {
      final url = (_sel!['foto_url'] ?? '').toString();
      if (url.isNotEmpty) { try { foto = await networkImage(url); } catch (_) {} }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          final widgets = <pw.Widget>[];
          widgets.add(buildPdfHeader(b, logo: logo));

          // Título
          widgets.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Column(children: [
                  pw.Text('CARTA DE MUDANÇA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${_cidade.text.trim()} ${_dataCarta.text.trim()}'),
                ])
              ],
            ),
          );
          widgets.add(pw.SizedBox(height: 12));

          // Linha divisória
          widgets.add(pw.Container(height: 1, color: pdf.PdfColors.grey700));
          widgets.add(pw.SizedBox(height: 12));

          // Cabeçalho com foto
          widgets.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.RichText(
                    text: pw.TextSpan(children: [
                      pw.TextSpan(text: 'APRESENTAMOS O IRMÃO '),
                      pw.TextSpan(text: _toUpper(nome), style: pw.TextStyle(decoration: pw.TextDecoration.underline, fontWeight: pw.FontWeight.bold)),
                      const pw.TextSpan(text: ', PARA QUE RECEBAIS NO SENHOR COMO FAZEM TODOS OS SANTOS.'),
                    ]),
                  ),
                ),
                if (foto != null) pw.SizedBox(width: 12),
                if (foto != null)
                  pw.Container(width: 80, height: 100, decoration: pw.BoxDecoration(border: pw.Border.all(color: pdf.PdfColors.grey400)), child: pw.Image(foto, fit: pw.BoxFit.cover)),
              ],
            ),
          );

          widgets.add(pw.SizedBox(height: 12));

          // Campos
          widgets.add(_kv('ESTADO CIVIL', estadoCivil));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(
            pw.Row(children: [
              pw.Expanded(child: _kv('CARGO', cargo)),
              pw.SizedBox(width: 16),
              pw.Expanded(child: _kv('CONSAGRADO', consagracao)),
            ]),
          );
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_kv('BATIZADO NAS ÁGUAS', batismoAguas));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_kv('BATIZADO NO ESPÍRITO SANTO', batismoEspirito));
          widgets.add(pw.SizedBox(height: 6));
          final pais = _pais1.text.trim() + (_pais2.text.trim().isEmpty ? '' : '\n' + _pais2.text.trim());
          widgets.add(_kv('NOME DOS PAIS', pais));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(
            pw.Row(children: [
              pw.Expanded(child: _kv('RG', rg)),
              pw.SizedBox(width: 16),
              pw.Expanded(child: _kv('CPF', cpf)),
            ]),
          );
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_kv('DATA NASCIMENTO', nasc));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_kv('GRAU ESCOLARIDADE', escolaridade));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_kv('PROFISSÃO', profissao));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_kv('CELULAR', celular));

          widgets.add(pw.SizedBox(height: 24));
          widgets.add(pw.Container(height: 1, color: pdf.PdfColors.grey700));
          widgets.add(pw.SizedBox(height: 24));

          // Assinaturas
          widgets.add(
            pw.Row(children: [
              pw.Expanded(child: _signatureBlock(_signers['secretario'] ?? '', 'SECRETÁRIO')),
              pw.SizedBox(width: 24),
              pw.Expanded(child: _signatureBlock(_signers['pastor_presidente'] ?? '', 'PASTOR PRESIDENTE')),
            ]),
          );

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  String _toUpper(String s) => s.toUpperCase();

  pw.Widget _kv(String label, String? value) {
    final v = (value ?? '').trim();
    return pw.RichText(text: pw.TextSpan(children: [
      pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TextSpan(text: v),
    ]));
  }

  pw.Widget _signatureBlock(String name, String role) {
    return pw.Column(children: [
      pw.SizedBox(height: 24),
      pw.Container(height: 1, color: pdf.PdfColors.grey700),
      pw.SizedBox(height: 6),
      pw.Text(role, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      if (name.isNotEmpty) pw.Text(name),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carta de Mudança')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seleção do membro
              const Text('Selecionar membro'),
              const SizedBox(height: 8),
              _memberPicker(),
              const SizedBox(height: 12),

              // Campos auxiliares
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _cidade,
                    decoration: const InputDecoration(labelText: 'Cidade', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _dataCarta,
                    decoration: const InputDecoration(labelText: 'Data (dd/MM/aaaa)', border: OutlineInputBorder()),
                  ),
                ),
              ]),

              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _pais1,
                    decoration: const InputDecoration(labelText: 'Nome do Pai', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _pais2,
                    decoration: const InputDecoration(labelText: 'Nome da Mãe', border: OutlineInputBorder()),
                  ),
                ),
              ]),

              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _consagracao,
                    decoration: const InputDecoration(labelText: 'Data de Consagração (se aplicável)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _batismoEspirito,
                    decoration: const InputDecoration(labelText: 'Batizado no Espírito Santo (data)', border: OutlineInputBorder()),
                  ),
                ),
              ]),

              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _profissao,
                    decoration: const InputDecoration(labelText: 'Profissão (opcional)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Row(children: [
                  Checkbox(value: _incluirFoto, onChanged: (v) => setState(() => _incluirFoto = v ?? true)),
                  const Text('Incluir foto do membro (se houver)')
                ])
              ]),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Gerar PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberPicker() {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Pesquisar por nome',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (q) => setState(() {
            // just trigger rebuild for list below
          }),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
          child: ListView(
            children: _membros
                .where((m) => (_filterText()?.isEmpty ?? true)
                    ? true
                    : (m['nome_completo'] ?? '').toString().toLowerCase().contains(_filterText()!))
                .map((m) => RadioListTile<Map<String, dynamic>>(
                      value: m,
                      groupValue: _sel,
                      onChanged: (v) => setState(() => _sel = v),
                      title: Text((m['nome_completo'] ?? '').toString()),
                      subtitle: Text(((m['cargo_funcao'] ?? '').toString())),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  String? _lastFilter;
  String? _filterText() => _lastFilter;
}
