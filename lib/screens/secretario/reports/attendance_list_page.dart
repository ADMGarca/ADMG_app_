import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AttendanceListPage extends StatefulWidget {
  const AttendanceListPage({super.key});

  @override
  State<AttendanceListPage> createState() => _AttendanceListPageState();
}

class _AttendanceListPageState extends State<AttendanceListPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _membros = [];
  List<String> _cargos = [];
  final Set<String> _selecionados = {}; // cargos selecionados
  final Set<String> _membrosSelecionados = {}; // membros (ids) selecionados
  final TextEditingController _titulo = TextEditingController(text: 'Lista de Presença - Reunião');
  final TextEditingController _dataTexto = TextEditingController();
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
        .select('id, nome_completo, cargo_funcao')
        .order('cargo_funcao');
    final list = List<Map<String, dynamic>>.from(resp);
    final cargos = list
        .map((e) => (e['cargo_funcao'] ?? 'Membro').toString())
        .toSet()
        .toList()
      ..sort();
    setState(() {
      _membros = list;
      _cargos = cargos;
      _selecionados.addAll(cargos); // por padrão, todos
      _membrosSelecionados
          .addAll(list.map((m) => (m['id'] ?? '').toString()).where((id) => id.isNotEmpty)); // por padrão, todos membros
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filtrados {
    return _membros
        .where((m) => _selecionados.contains((m['cargo_funcao'] ?? 'Membro').toString()))
        .toList()
      ..sort((a, b) => (a['cargo_funcao'] ?? '').toString().compareTo((b['cargo_funcao'] ?? '').toString()));
  }

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    // Somente membros selecionados dentre os filtrados por cargo
    final rows = _filtrados
        .where((m) => _membrosSelecionados.contains((m['id'] ?? '').toString()))
        .toList();

    // Agrupar por cargo
    final Map<String, List<Map<String, dynamic>>> porCargo = {};
    for (final m in rows) {
      final c = (m['cargo_funcao'] ?? 'Membro').toString();
      porCargo.putIfAbsent(c, () => []).add(m);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) {
          final widgets = <pw.Widget>[];
          widgets.add(pw.Text(_titulo.text, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)));
          if (_dataTexto.text.trim().isNotEmpty) {
            widgets.add(pw.Text('Data: ${_dataTexto.text.trim()}'));
          }
          widgets.add(pw.SizedBox(height: 12));

          porCargo.forEach((cargo, lista) {
            widgets.add(pw.Text(cargo, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(4),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: pdf.PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Nome')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cargo')),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Assinatura')),
                    ],
                  ),
                  ...lista.map((m) => pw.TableRow(children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((m['nome_completo'] ?? '').toString())),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text((m['cargo_funcao'] ?? '').toString())),
                        pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Text('')),
                      ])),
                ],
              ),
            );
            widgets.add(pw.SizedBox(height: 16));
          });

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  void _toggleSelectAllFiltered(bool select) {
    final ids = _filtrados.map((m) => (m['id'] ?? '').toString());
    setState(() {
      if (select) {
        _membrosSelecionados.addAll(ids);
      } else {
        _membrosSelecionados.removeAll(ids.toList());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Presença'),
        actions: [
          IconButton(onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titulo,
                        decoration: const InputDecoration(labelText: 'Título do relatório', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _dataTexto,
                        decoration: const InputDecoration(labelText: 'Data (preencher manualmente, opcional)', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      const Text('Filtrar por cargo:'),
                      Wrap(
                        spacing: 8,
                        children: _cargos
                            .map((c) => FilterChip(
                                  label: Text(c),
                                  selected: _selecionados.contains(c),
                                  onSelected: (sel) => setState(() {
                                    if (sel) {
                                      _selecionados.add(c);
                                    } else {
                                      _selecionados.remove(c);
                                    }
                                  }),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Selecionados: ${_filtrados.where((m) => _membrosSelecionados.contains((m['id'] ?? '').toString())).length}/${_filtrados.length}'),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _toggleSelectAllFiltered(true),
                            icon: const Icon(Icons.done_all),
                            label: const Text('Selecionar todos'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _toggleSelectAllFiltered(false),
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Limpar seleção'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtrados.length,
                    itemBuilder: (ctx, i) {
                      final m = _filtrados[i];
                      final id = (m['id'] ?? '').toString();
                      final marcado = _membrosSelecionados.contains(id);
                      return ListTile(
                        onTap: () => setState(() {
                          if (marcado) {
                            _membrosSelecionados.remove(id);
                          } else {
                            _membrosSelecionados.add(id);
                          }
                        }),
                        leading: Checkbox(
                          value: marcado,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _membrosSelecionados.add(id);
                            } else {
                              _membrosSelecionados.remove(id);
                            }
                          }),
                        ),
                        title: Text((m['nome_completo'] ?? '').toString()),
                        subtitle: Text((m['cargo_funcao'] ?? '').toString()),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
