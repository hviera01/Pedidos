import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static Future<void>? _authFuture;

  Future<void> ensureAuth() async {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser != null) return;

    _authFuture ??= auth.signInAnonymously();

    try {
      await _authFuture;
    } finally {
      _authFuture = null;
    }
  }

  Future<String> uploadXFile(XFile file, String folder) async {
    await ensureAuth();

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final contentType = contentTypeFromExt(ext);
    final safeFolder = folder.replaceAll('\\', '/').replaceAll('//', '/');
    final safeName = file.name.replaceAll(' ', '_').replaceAll('/', '_').replaceAll('\\', '_');
    final name = '${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final ref = FirebaseStorage.instance.ref().child('$safeFolder/$name');

    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(
        contentType: contentType,
        cacheControl: 'public,max-age=31536000',
      ),
    );

    return ref.getDownloadURL();
  }

  String contentTypeFromExt(String ext) {
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    if (ext == 'gif') return 'image/gif';
    return 'image/jpeg';
  }
}