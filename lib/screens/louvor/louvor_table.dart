import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';

class LouvorTable extends StatelessWidget {
  const LouvorTable({super.key, required this.louvores});

  final List<Map<String, dynamic>> louvores;

  void _mostrarLouvorAmpliado(BuildContext context, String louvor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Louvor',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            louvor,
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
        children: louvores.map((louvor) {
          final data = louvor['data'] ?? '';
          final textoLouvor = louvor['louvor_'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _mostrarLouvorAmpliado(context, textoLouvor),
                      child: Text(
                        textoLouvor,
                        style: const TextStyle(
                          fontSize: 20, // Fonte maior
                          fontWeight: FontWeight.bold, // Negrito
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