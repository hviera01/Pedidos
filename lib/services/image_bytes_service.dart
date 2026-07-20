import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'smart_image_url.dart';

class ImageBytesService {
  static final Map<String, Future<Uint8List?>> _cache = {};

  static Future<Uint8List?> fetch(String rawUrl) {
    final key = rawUrl.trim();
    if (key.isEmpty) return Future.value(null);

    return _cache.putIfAbsent(key, () async {
      final result = await _fetchInternal(key);
      if (result == null) _cache.remove(key);
      return result;
    });
  }

  static Future<Uint8List?> _fetchInternal(String rawUrl) async {
    try {
      final resolved = await SmartImageUrl.resolve(rawUrl);
      if (resolved.trim().isEmpty) return null;

      if (resolved.startsWith('data:image/')) {
        return UriData.parse(resolved).contentAsBytes();
      }

      if (resolved.startsWith('assets/') || resolved.startsWith('img/')) {
        final data = await rootBundle.load(resolved);
        return data.buffer.asUint8List();
      }

      final response = await http.get(Uri.parse(resolved));

      if (response.statusCode != 200) {
        developer.log(
          'ImageBytesService: HTTP ${response.statusCode} al descargar $resolved',
          name: 'ImageBytesService',
        );
        return null;
      }

      return response.bodyBytes;
    } catch (e) {
      developer.log(
        'ImageBytesService: no se pudo descargar $rawUrl: $e',
        name: 'ImageBytesService',
      );
      return null;
    }
  }
}
