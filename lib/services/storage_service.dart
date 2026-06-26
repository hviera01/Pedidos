import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  Future<void> ensureAuth() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  Future<String> uploadXFile(XFile file, String folder) async {
    await ensureAuth();

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    final contentType = contentTypeFromExt(ext);
    final safeFolder = folder.replaceAll('\\', '/').replaceAll('//', '/');
    final safeName = file.name.replaceAll(' ', '_').replaceAll('/', '_').replaceAll('\\', '_');
    final name = '${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = FirebaseStorage.instance.ref().child('$safeFolder/$name');

    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: contentType),
    );

    return await ref.getDownloadURL();
  }

  String contentTypeFromExt(String ext) {
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    if (ext == 'gif') return 'image/gif';
    return 'image/jpeg';
  }
}