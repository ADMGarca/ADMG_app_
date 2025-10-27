import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart' as mime;
// no printing/pdf imports needed here
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:admg_app/utils/pdf_branding.dart';

class SecretarioConfigPage extends StatefulWidget {
  const SecretarioConfigPage({super.key});

  @override
  State<SecretarioConfigPage> createState() => _SecretarioConfigPageState();
}

class _SecretarioConfigPageState extends State<SecretarioConfigPage> {
  final supabase = Supabase.instance.client;

  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _addr1 = TextEditingController();
  final _addr2 = TextEditingController();
  final _cnpj = TextEditingController();
  // Assinaturas da carta de mudança
  final _signSec = TextEditingController();
  final _signPastor = TextEditingController();

  String? _logoUrl; // atual
  XFile? _pickedFile;
  Uint8List? _pickedBytes;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final b = await loadBrandingOrDefault();
    _line1.text = b.line1Title;
    _line2.text = b.line2Title;
    _addr1.text = b.addressLine1;
    _addr2.text = b.addressLine2;
    _cnpj.text = b.cnpj;
    _logoUrl = b.logoUrl;
    // carregar assinaturas
    try {
      final resp = await supabase.from('app_settings').select('value').eq('key', 'letter_signers').maybeSingle();
      if (resp != null && resp['value'] is Map<String, dynamic>) {
        final v = Map<String, dynamic>.from(resp['value'] as Map);
        _signSec.text = (v['secretario'] ?? '').toString();
        _signPastor.text = (v['pastor_presidente'] ?? '').toString();
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _pickedFile = img;
        _pickedBytes = bytes;
      });
    }
  }

  Future<String?> _uploadLogo(Uint8List data, String? fileName) async {
    try {
      final mimeType = mime.lookupMimeType(fileName ?? '') ?? 'image/png';
      String ext = 'png';
      if (mimeType.contains('jpeg')) ext = 'jpg';
      else if (mimeType.contains('png')) ext = 'png';
      else if (mimeType.contains('webp')) ext = 'webp';
      final path = 'logo/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await supabase.storage.from('branding').uploadBinary(
        path,
        data,
        fileOptions: FileOptions(contentType: mimeType, upsert: true),
      );
      final url = supabase.storage.from('branding').getPublicUrl(path);
      return url;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao enviar logo: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    String? logoUrl = _logoUrl;
    if (_pickedBytes != null) {
      final url = await _uploadLogo(_pickedBytes!, _pickedFile?.name);
      if (url != null) logoUrl = url;
    }

    final payload = BrandingInfo(
      line1Title: _line1.text.trim(),
      line2Title: _line2.text.trim(),
      addressLine1: _addr1.text.trim(),
      addressLine2: _addr2.text.trim(),
      cnpj: _cnpj.text.trim(),
      logoUrl: logoUrl,
    ).toJson();

    try {
      final nowIso = DateTime.now().toIso8601String();
      await supabase.from('app_settings').upsert([
        {
          'key': 'pdf_header',
          'value': payload,
          'updated_at': nowIso,
        },
        {
          'key': 'letter_signers',
          'value': {
            'secretario': _signSec.text.trim(),
            'pastor_presidente': _signPastor.text.trim(),
          },
          'updated_at': nowIso,
        }
      ]);
      if (mounted) {
        setState(() {
          _logoUrl = logoUrl;
          _pickedBytes = null;
          _pickedFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configurações salvas com sucesso.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar configurações: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações da Igreja'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Logo (cabeçalho do PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: _pickedBytes != null
                                    ? Image.memory(_pickedBytes!, fit: BoxFit.contain)
                                    : (_logoUrl != null && _logoUrl!.isNotEmpty)
                                        ? Image.network(_logoUrl!, fit: BoxFit.contain)
                                        : const Center(child: Icon(Icons.image, size: 48, color: Colors.black26)),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickLogo,
                                    icon: const Icon(Icons.upload),
                                    label: const Text('Escolher logo'),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_logoUrl != null && _logoUrl!.isNotEmpty)
                                    Text(_logoUrl!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Textos do cabeçalho', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _line1,
                            decoration: const InputDecoration(labelText: 'Linha 1 (título superior)', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _line2,
                            decoration: const InputDecoration(labelText: 'Linha 2 (título inferior)', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _addr1,
                            decoration: const InputDecoration(labelText: 'Endereço - linha 1', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _addr2,
                            decoration: const InputDecoration(labelText: 'Endereço - linha 2', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _cnpj,
                            decoration: const InputDecoration(labelText: 'CNPJ', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Assinaturas (Carta de Mudança)', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _signSec,
                            decoration: const InputDecoration(labelText: 'Nome do Secretário', border: OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _signPastor,
                            decoration: const InputDecoration(labelText: 'Nome do Pastor Presidente', border: OutlineInputBorder()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
