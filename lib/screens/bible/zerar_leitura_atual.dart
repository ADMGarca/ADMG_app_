import 'package:supabase_flutter/supabase_flutter.dart';

/// Função para zerar a tabela leitura_atual (deletar todos os registros)
Future<void> zerarLeituraAtual() async {
  final supabase = Supabase.instance.client;
  await supabase.from('leitura_atual').delete().neq('id', 0);
}
