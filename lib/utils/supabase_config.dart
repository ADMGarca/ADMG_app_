import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://kvrllypieftdcoztsxno.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt2cmxseXBpZWZ0ZGNvenRzeG5vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1NTQ5NDksImV4cCI6MjA2MDEzMDk0OX0.F9rHyAZ4TXRQgQdXxM2BtgRNt03nLvlAcAdkJoxSesg';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}