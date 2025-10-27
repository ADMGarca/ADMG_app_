import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

class BrandingInfo {
  final String line1Title;
  final String line2Title;
  final String addressLine1;
  final String addressLine2;
  final String cnpj;
  final String? logoUrl; // URL pública (ex.: Supabase Storage/bucket branding)

  const BrandingInfo({
    required this.line1Title,
    required this.line2Title,
    required this.addressLine1,
    required this.addressLine2,
    required this.cnpj,
    this.logoUrl,
  });

  static BrandingInfo defaults() => const BrandingInfo(
        line1Title: 'IGREJA EVANGÉLICA ASSEMBLEIA DE',
        line2Title: 'DE DEUS MINISTÉRIO DE GARÇA',
        addressLine1: 'RUA – 10 de novembro, 70  CEP: 17.400.007',
        addressLine2: 'Garça – SP – CEL: Secretário Marcos 14- 99796 - 2484',
        cnpj: '11.048.882/0001-81',
        logoUrl: null,
      );

  factory BrandingInfo.fromJson(Map<String, dynamic> j) {
    return BrandingInfo(
      line1Title: (j['line1Title'] ?? '').toString().trim(),
      line2Title: (j['line2Title'] ?? '').toString().trim(),
      addressLine1: (j['addressLine1'] ?? '').toString().trim(),
      addressLine2: (j['addressLine2'] ?? '').toString().trim(),
      cnpj: (j['cnpj'] ?? '').toString().trim(),
      logoUrl: (j['logoUrl'] ?? '').toString().trim().isEmpty ? null : (j['logoUrl'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'line1Title': line1Title,
        'line2Title': line2Title,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'cnpj': cnpj,
        'logoUrl': logoUrl,
      };
}

/// Carrega o branding do Supabase (tabela app_settings, chave 'pdf_header').
/// Retorna defaults() caso não exista.
Future<BrandingInfo> loadBrandingOrDefault() async {
  try {
    final supabase = Supabase.instance.client;
    final resp = await supabase.from('app_settings').select('value').eq('key', 'pdf_header').maybeSingle();
    if (resp != null && resp['value'] is Map<String, dynamic>) {
      return BrandingInfo.fromJson(Map<String, dynamic>.from(resp['value'] as Map));
    }
  } catch (_) {
    // fallback
  }
  return BrandingInfo.defaults();
}

/// Carrega a fonte padrão do app para garantir acentuação/caráteres especiais.
/// Usa assets/fonts/NotoSans-Regular.ttf (declarada no pubspec.yaml).
Future<pw.Font> loadAppPdfFont() async {
  final data = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
  return pw.Font.ttf(data);
}

/// Cria um Document já com ThemeData usando a fonte do app para base e bold.
Future<pw.Document> newPdfDoc() async {
  final base = await loadAppPdfFont();
  final theme = pw.ThemeData.withFont(base: base, bold: base);
  return pw.Document(theme: theme);
}

/// Constrói o cabeçalho em formato PDF.
/// Passe [logo] quando disponível; se null, renderiza apenas texto.
 pw.Widget buildPdfHeader(BrandingInfo b, {pw.ImageProvider? logo}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 110,
            height: 110,
            alignment: pw.Alignment.centerLeft,
            child: logo != null ? pw.Image(logo, fit: pw.BoxFit.contain) : pw.SizedBox(),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(b.line1Title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text(b.line2Title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Container(height: 1, color: pdf.PdfColors.black),
              ],
            ),
          ),
        ],
      ),
  pw.SizedBox(height: 8),
  pw.Text(b.addressLine1, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
  pw.Text(b.addressLine2, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
      pw.SizedBox(height: 6),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('CNPJ: ', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(b.cnpj, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
      pw.SizedBox(height: 16),
    ],
  );
}
