import 'package:flutter/material.dart';

class HarpaHymnPage extends StatelessWidget {
  final Map<String, dynamic> hymn;

  const HarpaHymnPage({super.key, required this.hymn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hino: ${hymn['hino']}'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0F7FA), // Light Cyan
              Color(0xFFBBDEFB), // Light Blue
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hymn['hino'],
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (hymn['coro'] != null && hymn['coro'].isNotEmpty) ...[
                    Text(
                      'Coro:',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hymn['coro'].replaceAll(
                          '<br>', '\n'), // Substitui <br> por nova linha
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Versos:',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (hymn['verses'] != null) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (hymn['verses'] as Map<String, dynamic>)
                          .entries
                          .map<Widget>((entry) {
                        final verseNum = entry.key;
                        final verseText = entry.value.replaceAll(
                            '<br>', '\n'); // Substitui <br> por nova linha
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            '$verseNum. $verseText',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
