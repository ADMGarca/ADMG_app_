import 'dart:io';
import 'package:flutter/material.dart';
import 'package:admg_app/screens/avisos/avisos_page.dart';
import 'package:admg_app/screens/oracao/oracao_page.dart';
import 'package:admg_app/screens/louvor/louvor_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:admg_app/screens/login/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _sair(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_nome');
    await prefs.remove('usuario_senha');
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMG - Início'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 28),
            onPressed: () => _sair(context),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.all(24.0),
                width: double.infinity,
                color: Colors.white,
                child: Column(
                  children: [
                    const Icon(
                      Icons.church,
                      size: 80,
                      color: Color(0xFF42A5F5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Bem-vindo à ADMG',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Escolha uma opção abaixo',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              // Botões
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildMenuButton(
                      text: 'Avisos',
                      icon: Icons.announcement,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AvisosPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Pedido de Oração',
                      icon: Icons.handshake,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PedidoOracaoPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Louvor',
                      icon: Icons.music_note,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LouvorPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      text: 'Sair',
                      icon: Icons.exit_to_app,
                      backgroundColor: Colors.red,
                      onPressed: () => _sair(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required String text,
    required IconData icon,
    Color? backgroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 70, // Botão maior
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 30),
        label: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFF42A5F5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}