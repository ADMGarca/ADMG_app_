import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:intl/intl.dart';

class MemberReportPage extends StatefulWidget {
  const MemberReportPage({super.key});

  @override
  State<MemberReportPage> createState() => _MemberReportPageState();
}

class _MemberReportPageState extends State<MemberReportPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _search = TextEditingController();
  List<Map<String, dynamic>> _membros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final resp = await supabase
        .from('membros')
        .select('*')
        .order('nome_completo');
    setState(() {
      _membros = List<Map<String, dynamic>>.from(resp);
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _membros;
    return _membros.where((m) {
      final nome = (m['nome_completo'] ?? '').toString().toLowerCase();
      final cargo = (m['cargo_funcao'] ?? '').toString().toLowerCase();
      return nome.contains(q) || cargo.contains(q);
    }).toList();
  }

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    final rows = _filtered;

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Relatório de Membros')),
          pw.Table.fromTextArray(
            headers: ['Nome', 'Cargo'],
            data: rows
                .map((m) => [
                      (m['nome_completo'] ?? '').toString(),
                      (m['cargo_funcao'] ?? '').toString(),
                    ])
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Future<void> _exportMemberPdf(Map<String, dynamic> m) async {
    final doc = pw.Document();

    String? _s(dynamic v) {
      final s = (v ?? '').toString().trim();
      return s.isEmpty ? null : s;
    }

    final widgets = <pw.Widget>[];

    widgets.add(
      pw.Header(level: 0, child: pw.Text('Ficha do Membro')),
    );

    widgets.add(
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(_s(m['nome_completo']) ?? '-',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (_s(m['cargo_funcao']) != null)
              pw.Text('Cargo: ${m['cargo_funcao']}'),
            if (_s(m['situacao_atual']) != null)
              pw.Text('Situação: ${m['situacao_atual']}'),
          ],
        ),
      ),
    );

    void addSection(String title) {
      widgets.addAll([
        pw.SizedBox(height: 8),
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
      ]);
    }

    void addKV(String label, String? value) {
      if (value == null || value.trim().isEmpty) return;
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 4),
          child: pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: value),
            ]),
          ),
        ),
      );
    }

    addSection('Dados Pessoais');
    addKV('Código', _s(m['codigo_membro']));
    addKV('Sexo', _s(m['sexo']));
    addKV('Estado civil', _s(m['estado_civil']));
    addKV('Escolaridade', _s(m['escolaridade']));
    addKV('Data de nascimento', _fmtDate(m['data_nascimento'], m['data_nascimento_raw']));
    addKV('CPF', _s(m['cpf']));
    addKV('RG', _s(m['rg']));
    addKV('Telefone', _s(m['telefone']));
    addKV('E-mail', _s(m['email']));

    addSection('Endereço');
    addKV('Rua', _s(m['endereco_rua']));
    addKV('Número', _s(m['endereco_numero']));
    addKV('Bairro', _s(m['endereco_bairro']));
    addKV('Cidade', _s(m['endereco_cidade']));
    addKV('Estado', _s(m['endereco_estado']));
    addKV('CEP', _s(m['endereco_cep']));

    addSection('Dados Espirituais');
    addKV('Data de conversão', _fmtDate(m['data_conversao'], m['data_conversao_raw']));
    addKV('Data de batismo', _fmtDate(m['data_batismo'], m['data_batismo_raw']));
    addKV('Igreja de batismo', _s(m['igreja_batismo']));
    addKV('Ministérios', _s(m['ministerios']));

    addSection('Família');
    addKV('Cônjuge', _s(m['nome_conjuge']));
    addKV('Filhos', _s(m['filhos']));
    addKV('Responsável (se menor)', _s(m['nome_responsavel']));

    addSection('Observações');
    addKV('Observações', _s(m['observacoes_pastorais']));

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (ctx) => widgets,
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  String? _fmtDate(dynamic iso, dynamic raw) {
    final rawStr = (raw ?? '').toString().trim();
    if (rawStr.isNotEmpty) return rawStr; // já vem formatado dd/MM/aaaa
    final isoStr = (iso ?? '').toString().trim();
    if (isoStr.isEmpty) return null;
    try {
      final dt = DateTime.parse(isoStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return isoStr;
    }
  }

  Widget _kv(String label, String? value, {IconData? icon}) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 2),
              child: Icon(icon, size: 18, color: Colors.black45),
            ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(Map<String, dynamic> m) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: (m['foto_url'] ?? '').toString().isNotEmpty
                        ? NetworkImage(m['foto_url'])
                        : null,
                    child: ((m['foto_url'] ?? '').toString().isEmpty)
                        ? const Icon(Icons.person, size: 28)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((m['nome_completo'] ?? '').toString(),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        _kv('Cargo', (m['cargo_funcao'] ?? '').toString()),
                        _kv('Situação', (m['situacao_atual'] ?? '').toString()),
                      ],
                    ),
                  )
                ]),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Dados Pessoais', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _kv('Código', (m['codigo_membro'] ?? '').toString(), icon: Icons.badge_outlined),
                _kv('Sexo', (m['sexo'] ?? '').toString(), icon: Icons.wc),
                _kv('Estado civil', (m['estado_civil'] ?? '').toString(), icon: Icons.family_restroom),
                _kv('Escolaridade', (m['escolaridade'] ?? '').toString(), icon: Icons.school_outlined),
                _kv('Data de nascimento', _fmtDate(m['data_nascimento'], m['data_nascimento_raw']), icon: Icons.cake_outlined),
                _kv('CPF', (m['cpf'] ?? '').toString(), icon: Icons.credit_card_outlined),
                _kv('RG', (m['rg'] ?? '').toString(), icon: Icons.perm_identity),
                _kv('Telefone', (m['telefone'] ?? '').toString(), icon: Icons.phone_outlined),
                _kv('E-mail', (m['email'] ?? '').toString(), icon: Icons.email_outlined),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Endereço', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _kv('Rua', (m['endereco_rua'] ?? '').toString(), icon: Icons.home_outlined),
                _kv('Número', (m['endereco_numero'] ?? '').toString()),
                _kv('Bairro', (m['endereco_bairro'] ?? '').toString()),
                _kv('Cidade', (m['endereco_cidade'] ?? '').toString()),
                _kv('Estado', (m['endereco_estado'] ?? '').toString()),
                _kv('CEP', (m['endereco_cep'] ?? '').toString()),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Dados Espirituais', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _kv('Data de conversão', _fmtDate(m['data_conversao'], m['data_conversao_raw']), icon: Icons.favorite_border),
                _kv('Data de batismo', _fmtDate(m['data_batismo'], m['data_batismo_raw']), icon: Icons.water_drop_outlined),
                _kv('Igreja de batismo', (m['igreja_batismo'] ?? '').toString(), icon: Icons.church),
                _kv('Ministérios', (m['ministerios'] ?? '').toString(), icon: Icons.groups_2_outlined),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Família', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _kv('Cônjuge', (m['nome_conjuge'] ?? '').toString(), icon: Icons.favorite_outline),
                _kv('Filhos', (m['filhos'] ?? '').toString(), icon: Icons.child_care_outlined),
                _kv('Responsável (se menor)', (m['nome_responsavel'] ?? '').toString(), icon: Icons.supervisor_account_outlined),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Observações', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _kv('', (m['observacoes_pastorais'] ?? '').toString()),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _exportMemberPdf(m),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Gerar PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Membros'),
        actions: [
          IconButton(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: 'Pesquisar por nome ou cargo',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() => _search.clear());
                              },
                            ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final m = _filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (m['foto_url'] ?? '').toString().isNotEmpty
                              ? NetworkImage(m['foto_url'])
                              : null,
                          child: ((m['foto_url'] ?? '').toString().isEmpty)
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text((m['nome_completo'] ?? '').toString()),
                        subtitle: Text((m['cargo_funcao'] ?? '').toString()),
                        onTap: () => _showDetails(m),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
