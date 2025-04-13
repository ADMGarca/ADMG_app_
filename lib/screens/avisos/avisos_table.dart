import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';

class AvisosTable extends StatelessWidget {
  const AvisosTable({super.key, required this.avisos});

  final List<Map<String, dynamic>> avisos;

  void _mostrarDescricaoAmpliada(BuildContext context, String descricao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Descrição',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            descricao,
            style: const TextStyle(fontSize: 22, color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Fechar',
              style: TextStyle(fontSize: 18, color: Color(0xFF42A5F5)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: avisos.map((aviso) {
          final importancia = aviso['status']?.toString() ?? 'Normal';
          final data = aviso['data']?.toString() ?? '';
          final descricao = aviso['descricao']?.toString() ?? '';
          final isUrgente = importancia.toLowerCase() == 'urgente';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                // Borda vermelha para avisos urgentes
                side: isUrgente
                    ? const BorderSide(color: Colors.red, width: 2)
                    : BorderSide.none,
              ),
              // Fundo vermelho claro para avisos urgentes
              color: isUrgente ? const Color(0xFFFFE6E6) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatarData(data),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          importancia,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            // Texto vermelho para status "URGENTE"
                            color: isUrgente ? Colors.red : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _mostrarDescricaoAmpliada(context, descricao),
                      child: Text(
                        descricao,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}