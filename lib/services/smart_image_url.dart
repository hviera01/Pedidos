import 'package:firebase_storage/firebase_storage.dart';

class SmartImageUrl {
  static final Map<String, Future<String>> _cache = {};

  static Future<String> resolve(String input) {
    final key = input.trim();
    if (key.isEmpty) return Future.value('');
    return _cache.putIfAbsent(key, () => _resolveInternal(key));
  }

  static Future<String> _resolveInternal(String input) async {
    var raw = input.trim();

    if (raw.isEmpty) return '';

    raw = raw.replaceAll('&amp;', '&');

    if (raw.startsWith('blob:')) return '';

    while (raw.startsWith('../')) {
      raw = raw.replaceFirst('../', '');
    }

    while (raw.startsWith('./')) {
      raw = raw.replaceFirst('./', '');
    }

    if (raw.startsWith('/')) {
      raw = raw.substring(1);
    }

    if (raw.startsWith('data:image/')) {
      return raw;
    }

    if (raw.startsWith('gs://')) {
      return await FirebaseStorage.instance.refFromURL(raw).getDownloadURL();
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      final uri = Uri.tryParse(raw);

      if (uri != null && uri.host.contains('drive.google.com')) {
        final id = _googleDriveId(uri);
        if (id.isNotEmpty) {
          return 'https://drive.google.com/uc?export=view&id=$id';
        }
      }

      if (raw.contains('firebasestorage.googleapis.com') && !raw.contains('alt=media')) {
        return '$raw${raw.contains('?') ? '&' : '?'}alt=media';
      }

      return raw;
    }

    if (raw.startsWith('img/') || raw.startsWith('assets/')) {
      return raw;
    }

    if (raw.contains('/')) {
      return await FirebaseStorage.instance.ref(raw).getDownloadURL();
    }

    return '';
  }

  static String _googleDriveId(Uri uri) {
    final parts = uri.pathSegments;
    final dIndex = parts.indexOf('d');

    if (dIndex >= 0 && dIndex + 1 < parts.length) {
      return parts[dIndex + 1];
    }

    return uri.queryParameters['id'] ?? '';
  }
}