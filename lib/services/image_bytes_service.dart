import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'smart_image_url.dart';

class ImageBytesService {
  static final Map<String, Future<Uint8List?>> _cache = {};
  static final Map<String, String> _lastError = {};

  /// Short, human-readable reason the last fetch for [rawUrl] failed, if any.
  static String? lastError(String rawUrl) => _lastError[rawUrl.trim()];

  static Future<Uint8List?> fetch(String rawUrl) {
    final key = rawUrl.trim();
    if (key.isEmpty) return Future.value(null);

    return _cache.putIfAbsent(key, () async {
      final result = await _fetchInternal(key);
      if (result == null) {
        _cache.remove(key);
      } else {
        _lastError.remove(key);
      }
      return result;
    });
  }

  static Future<Uint8List?> _fetchInternal(String rawUrl) async {
    try {
      final resolved = await SmartImageUrl.resolve(rawUrl);

      if (resolved.trim().isEmpty) {
        _fail(rawUrl, 'No hay imagen guardada para esta camisa');
        return null;
      }

      if (resolved.startsWith('data:image/')) {
        return UriData.parse(resolved).contentAsBytes();
      }

      if (resolved.startsWith('assets/') || resolved.startsWith('img/')) {
        final data = await rootBundle.load(resolved);
        return data.buffer.asUint8List();
      }

      final response = await http.get(Uri.parse(resolved));

      if (response.statusCode != 200) {
        _fail(rawUrl, 'HTTP ${response.statusCode} al descargar la imagen');
        return null;
      }

      if (response.bodyBytes.isEmpty) {
        _fail(rawUrl, 'La imagen descargada llegó vacía');
        return null;
      }

      return response.bodyBytes;
    } catch (e) {
      _fail(rawUrl, e.toString());
      return null;
    }
  }

  static void _fail(String rawUrl, String message) {
    _lastError[rawUrl.trim()] = message;
    developer.log('ImageBytesService: $rawUrl -> $message', name: 'ImageBytesService');
  }
}
