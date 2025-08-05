import 'package:flutter/material.dart';
import 'package:admg_app/screens/login/login_page.dart'; // Importe a página de login
import 'package:admg_app/screens/bible/bible_page.dart'; // Importe a página da Bíblia
import 'package:admg_app/screens/harpa/harpa_page.dart'; // Importe a página da Harpa
import 'package:admg_app/screens/bible/biblia_compartilhada_page.dart';

class InstitutionalPage extends StatelessWidget {
  const InstitutionalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMG'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD), // Azul muito claro
              Color(0xFFBBDEFB), // Azul claro
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Logo com efeito de brilho
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/assets/img/logo/Logo.png',
                    height: 400,
                  ),
                ),
                const SizedBox(height: 48),

                // Botões principais (Bíblia, Bíblia Compartilhada e Harpa)
                Row(
                  children: [
                    Expanded(
                      child: _buildFuturisticButton(
                        context,
                        'Bíblia',
                        Icons.book,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BiblePage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFuturisticButton(
                        context,
                        'Bíblia Compartilhada',
                        Icons.share,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BibliaCompartilhadaPage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFuturisticButton(
                        context,
                        'Harpa',
                        Icons.music_note,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HarpaPage()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Menu de acesso restrito
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.9), // Card branco translúcido
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Acesso Restrito',
                      style: TextStyle(
                        color: Colors.blue.shade900, // Texto escuro
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: Icon(Icons.admin_panel_settings,
                        color: Colors.blue.shade900), // Ícone escuro
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildRestrictedButton(
                              context,
                              'Tesoraria',
                              Icons.account_balance,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginPage(userType: 'tesoraria'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildRestrictedButton(
                              context,
                              'Mesário/Dirigente',
                              Icons.people,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(
                                      userType: 'mesario_dirigente'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Horários dos Cultos
                _buildFuturisticCard(
                  context,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Horários dos Cultos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900, // Texto escuro
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildScheduleItem('Terça-feira: Oração 19:30'),
                      _buildScheduleItem('Quinta-feira: Culto 19:30'),
                      _buildScheduleItem('Sábado: Culto Banco da Terra 19:00'),
                      _buildScheduleItem('Domingo: Culto 19:00'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 50, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestrictedButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade800, Colors.grey.shade900],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFuturisticCard(BuildContext context, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Card branco translúcido
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: child,
      ),
    );
  }

  Widget _buildScheduleItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.access_time,
              color: Colors.blue.shade900, size: 20), // Ícone escuro
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.black87, // Texto cinza escuro
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
