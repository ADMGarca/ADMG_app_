import 'package:flutter/material.dart';
import 'package:admg_app/screens/home_page.dart';
import 'package:admg_app/screens/login/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://kvrllypieftdcoztsxno.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2cmxseXBpZWZ0ZGNvenRzeG5vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1NTQ5NDksImV4cCI6MjA2MDEzMDk0OX0.F9rHyAZ4TXRQgQdXxM2BtgRNt03nLvlAcAdkJoxSesg',
  );

  final prefs = await SharedPreferences.getInstance();
  final temCredenciais = prefs.containsKey('usuario_nome');

  runApp(MyApp(telaInicial: temCredenciais ? const HomePage() : const LoginPage()));
}

class MyApp extends StatelessWidget {
  final Widget telaInicial;
  
  const MyApp({super.key, required this.telaInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADMG App',
      theme: ThemeData(
        brightness: Brightness.light, // Tema claro
        primaryColor: const Color(0xFF42A5F5), // Azul claro (cor primária)
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Fundo claro e suave
        cardColor: Colors.white, // Cards brancos com sombra
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF42A5F5),
          secondary: Color(0xFFFFCA28), // Dourado suave para destaques
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.black87,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.black87), // Texto maior para legibilidade
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF42A5F5), // Azul claro
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF42A5F5),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.black26),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF42A5F5), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.black54, fontSize: 18),
          prefixIconColor: Colors.black54,
        ),
      ),
      home: telaInicial,
      debugShowCheckedModeBanner: false,
    );
  }
}