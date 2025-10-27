import 'package:flutter/material.dart';
import 'package:admg_app/screens/login/login_page.dart';
import 'package:admg_app/screens/secretario/gerenciar_usuarios_page.dart';
import 'package:admg_app/screens/secretario/gerenciar_membros_page.dart';
import 'package:admg_app/screens/secretario/reports/secretario_reports_page.dart';

class SecretarioPage extends StatelessWidget {
  const SecretarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secretaria - Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () => _sair(context),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFBBDEFB),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24.0),
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        size: 80,
                        color: Color(0xFF42A5F5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Secretaria ADMG',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Central de Administração do Sistema',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                // Menu de Ferramentas
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildMenuButton(
                        context: context,
                        text: 'Gerenciar Usuários',
                        icon: Icons.people,
                        description:
                            'Cadastrar, editar e gerenciar usuários do sistema',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GerenciarUsuariosPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        context: context,
                        text: 'Gerenciar Membros',
                        icon: Icons.person_add,
                        description: 'Cadastrar e gerenciar membros da igreja',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GerenciarMembrosPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        context: context,
                        text: 'Relatórios',
                        icon: Icons.assessment,
                        description: 'Gerar relatórios e estatísticas',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecretarioReportsPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMenuButton(
                        context: context,
                        text: 'Configurações',
                        icon: Icons.settings,
                        description: 'Configurar sistema e preferências',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Funcionalidade em desenvolvimento'),
                            ),
                          );
                        },
                      ),
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

  Widget _buildMenuButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required String description,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: const Color(0xFF42A5F5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.black26,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sair(BuildContext context) async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
