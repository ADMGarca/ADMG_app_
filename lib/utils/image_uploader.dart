import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploader {
  ImageUploader({this.bucket = 'avatars'});

  final String bucket;
  final _picker = ImagePicker();
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<XFile?> pickFromGallery() async {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
  }

  Future<XFile?> captureFromCamera() async {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
  }

  Future<String> uploadForUser({
    required XFile file,
    required String userId,
  }) async {
    final bytes = await file.readAsBytes();
    final publicUrl = await _uploadBytes(
      bytes: bytes,
      collection: 'users',
      id: userId,
      originalName: file.name,
    );
    return publicUrl;
  }

  Future<String> uploadForMember({
    required XFile file,
    required String memberId,
  }) async {
    final bytes = await file.readAsBytes();
    final publicUrl = await _uploadBytes(
      bytes: bytes,
      collection: 'members',
      id: memberId,
      originalName: file.name,
    );
    return publicUrl;
  }

  Future<String> _uploadBytes({
    required Uint8List bytes,
    required String collection,
    required String id,
    String? originalName,
  }) async {
    final mimeType = lookupMimeType(originalName ?? '', headerBytes: bytes) ?? 'image/jpeg';
    final ext = _extensionFromMime(mimeType);
    final path = '$collection/$id/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _supabase.storage
        .from(bucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    final url = _supabase.storage.from(bucket).getPublicUrl(path);
    return url;
  }

  Future<void> saveAvatarUrl({
    required String userId,
    required String avatarUrl,
    String table = 'usuario',
    String column = 'avatar_url',
  }) async {
    await _supabase.from(table).update({column: avatarUrl}).eq('id', userId);
  }

  String _extensionFromMime(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return 'png';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      case 'image/jpeg':
      default:
        return 'jpg';
    }
  }
}
