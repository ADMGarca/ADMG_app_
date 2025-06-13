import 'package:flutter/material.dart';
import 'package:admg_app/screens/login/login_page.dart'; // Importe a página de login

class InstitutionalPage extends StatelessWidget {
  const InstitutionalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMG'),
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0), // Aumentar padding
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centraliza verticalmente
              crossAxisAlignment: CrossAxisAlignment
                  .stretch, // Estica os filhos horizontalmente
              children: <Widget>[
                // Logo
                Image.asset(
                  'assets/assets/img/Logo.png', // Caminho da sua logo
                  height: 500, // Ajuste o tamanho conforme necessário
                ),
                const SizedBox(height: 48),

                // Botão Tesoraria
                Container(
                  // Adicionado Container para sombra
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset:
                            const Offset(0, 4), // Altera a posição da sombra
                      ),
                    ],
                    borderRadius:
                        BorderRadius.circular(16), // Borda mais arredondada
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LoginPage(userType: 'tesoraria'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 24), // Aumentar o preenchimento
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16)), // Borda arredondada
                      ),
                      child: const Text('Tesoraria',
                          style: TextStyle(
                              fontSize: 20)), // Aumentar o tamanho da fonte
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botão Mesário/Dirigente
                Container(
                  // Adicionado Container para sombra
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset:
                            const Offset(0, 4), // Altera a posição da sombra
                      ),
                    ],
                    borderRadius:
                        BorderRadius.circular(16), // Borda mais arredondada
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LoginPage(userType: 'mesario_dirigente'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 24), // Aumentar o preenchimento
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16)), // Borda arredondada
                      ),
                      child: const Text('Mesário/Dirigente',
                          style: TextStyle(
                              fontSize: 20)), // Aumentar o tamanho da fonte
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Horários dos Cultos (Exemplo)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  elevation: 10, // Aumentar a elevação
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16)), // Borda mais arredondada
                  shadowColor:
                      Colors.blue.withOpacity(0.5), // Cor da sombra do card
                  child: Padding(
                    padding: const EdgeInsets.all(
                        24.0), // Aumentar o padding interno do card
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Horários dos Cultos',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight:
                                      FontWeight.bold), // Destacar título
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Terça-feira: Oração 19:30',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quinta-feira: Culto 19:30',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sábado: Culto Banco da Terra 19:00',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Domingo: Culto 19:00',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.black87),
                        ),
                        // Adicione mais horários conforme necessário
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
