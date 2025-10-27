import 'package:flutter/material.dart';
import 'member_report_page.dart';
import 'attendance_list_page.dart';

class SecretarioReportsPage extends StatelessWidget {
  const SecretarioReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios da Secretaria'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _tile(
              context,
              icon: Icons.people_outline,
              title: 'Relatório de Membros',
              subtitle: 'Lista com foto, cargo, busca e detalhes',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MemberReportPage()),
              ),
            ),
            const SizedBox(height: 16),
            _tile(
              context,
              icon: Icons.checklist_rtl,
              title: 'Lista de Presença',
              subtitle: 'Gerar por cargo(s) e exportar para PDF',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AttendanceListPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF42A5F5).withOpacity(0.12),
          child: Icon(icon, color: const Color(0xFF42A5F5)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
        onTap: onTap,
      ),
    );
  }
}
