import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BibliaCompartilhadaPage extends StatefulWidget {
  const BibliaCompartilhadaPage({super.key});

  @override
  State<BibliaCompartilhadaPage> createState() => _BibliaCompartilhadaPageState();
}


class _BibliaCompartilhadaPageState extends State<BibliaCompartilhadaPage> {
  bool fullscreen = true;
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
      appBar: null,
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : ultimasLeituras.isEmpty
              ? const Center(child: Text('Nenhum versículo compartilhado no momento.'))
              : Stack(
                  children: [
                    GestureDetector(
                      onTap: () {}, // desabilita sair do fullscreen ao clicar no card
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: Colors.yellow.withOpacity(0.4),
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${ultimasLeituras[0]['livro']} ${ultimasLeituras[0]['capitulo']}:${ultimasLeituras[0]['versiculo']}',
                                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  ultimasLeituras[0]['texto'] ?? '',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).maybePop();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.close, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
