import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/image_uploader.dart';

class AvatarUploader extends StatefulWidget {
  const AvatarUploader({super.key, required this.userId, this.initialUrl, this.onChanged});

  final String userId;
  final String? initialUrl;
  final ValueChanged<String>? onChanged;

  @override
  State<AvatarUploader> createState() => _AvatarUploaderState();
}

class _AvatarUploaderState extends State<AvatarUploader> {
  String? _avatarUrl;
  bool _loading = false;
  final _uploader = ImageUploader();

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.initialUrl;
  }

  Future<void> _chooseSource() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto agora'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndUpload(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      setState(() => _loading = true);
      final XFile? file = source == ImageSource.camera
          ? await _uploader.captureFromCamera()
          : await _uploader.pickFromGallery();
      if (file == null) return;

      final url = await _uploader.uploadForUser(file: file, userId: widget.userId);
      await _uploader.saveAvatarUrl(userId: widget.userId, avatarUrl: url);

      setState(() => _avatarUrl = url);
      if (mounted && widget.onChanged != null) widget.onChanged!(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar imagem: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarUrl;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 48,
          backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar == null || avatar.isEmpty
              ? const Icon(Icons.person, size: 48)
              : null,
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _loading ? null : _chooseSource,
          icon: const Icon(Icons.upload),
          label: Text(_loading ? 'Enviando...' : 'Alterar foto'),
        ),
      ],
    );
  }
}
