import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BibliaCompartilhadaPage extends StatefulWidget {
  const BibliaCompartilhadaPage({super.key});

  @override
  State<BibliaCompartilhadaPage> createState() => _BibliaCompartilhadaPageState();
}


class _BibliaCompartilhadaPageState extends State<BibliaCompartilhadaPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> ultimasLeituras = [];
  bool carregando = true;
  late final ticker;
  DateTime? ultimoRegistro;
  // proteção de tela removida

  @override
  void initState() {
    super.initState();
    _buscarUltimasLeituras();
    ticker = _startTicker();
  }

  @override
  void dispose() {
    ticker.cancel();
    super.dispose();
  }

  Future<void> _buscarUltimasLeituras() async {
    final response = await supabase
        .from('leitura_atual')
        .select()
        .order('atualizado_em', ascending: false)
        .limit(3);
    if (mounted) {
      DateTime? novoUltimoRegistro;
      if (response.isNotEmpty) {
        final atualizadoEm = response.first['atualizado_em'];
        if (atualizadoEm != null) {
          novoUltimoRegistro = DateTime.tryParse(atualizadoEm.toString());
        }
      }
      setState(() {
        ultimasLeituras = List<Map<String, dynamic>>.from(response);
        carregando = false;
        if (novoUltimoRegistro != null) {
          ultimoRegistro = novoUltimoRegistro;
        }
      });
    }
  }

  _startTicker() {
    return Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      await _buscarUltimasLeituras();
      return mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bíblia Compartilhada'),
        centerTitle: true,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : ultimasLeituras.isEmpty
              ? const Center(child: Text('Nenhum versículo compartilhado no momento.'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(ultimasLeituras.length, (index) {
                      final leitura = ultimasLeituras[index];
                      final isDestaque = index == 0;
                      return Opacity(
                        opacity: isDestaque ? 1.0 : 0.4,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Card(
                            elevation: isDestaque ? 8 : 2,
                            color: isDestaque ? Colors.yellow.withOpacity(0.4) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${leitura['livro']} ${leitura['capitulo']}:${leitura['versiculo']}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: isDestaque ? Colors.black : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    leitura['texto'] ?? '',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: isDestaque ? Colors.black : Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Atualizado em: ${leitura['atualizado_em'] ?? ''}',
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
    );
  }
}
