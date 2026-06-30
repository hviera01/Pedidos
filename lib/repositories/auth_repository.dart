import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';

class AuthRepository extends ChangeNotifier {
  static const String sessionKey = 'sq_user';
  static const String lastActivityKey = 'sq_last_activity';
  static const Duration inactivityLimit = Duration(hours: 1);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _user;
  bool _loading = false;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isLogged => _user != null;

  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(sessionKey);

    if (raw == null || raw.trim().isEmpty) {
      _user = null;
      notifyListeners();
      return;
    }

       try {
      final lastActivity = prefs.getInt(lastActivityKey);

      if (lastActivity == null) {
        _user = null;
        await prefs.remove(sessionKey);
        notifyListeners();
        return;
      }

      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastActivity);
      final expired = DateTime.now().difference(lastDate) >= inactivityLimit;

      if (expired) {
        _user = null;
        await prefs.remove(sessionKey);
        await prefs.remove(lastActivityKey);
        notifyListeners();
        return;
      }

      final map = jsonDecode(raw) as Map<String, dynamic>;
      _user = AppUser.fromSessionMap(map);
      await updateActivity();
    } catch (_) {
      _user = null;
      await prefs.remove(sessionKey);
      await prefs.remove(lastActivityKey);
    }

    notifyListeners();
  }

  Future<void> login({
    required String codigo,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final cleanCode = codigo.trim();
      final cleanPass = password.trim();

      if (!RegExp(r'^[0-9]{4}$').hasMatch(cleanCode)) {
        throw Exception('Código inválido');
      }

      if (cleanPass.isEmpty) {
        throw Exception('Ingrese la contraseña');
      }

      final ref = _db.collection('usuarios').doc(cleanCode);
      final snap = await ref.get();

      if (!snap.exists) {
        throw Exception('Usuario no existe');
      }

      final data = snap.data() ?? {};

      if (data['activo'] == false) {
        throw Exception('Usuario inhabilitado');
      }

      if ((data['password'] ?? '').toString() != cleanPass) {
        throw Exception('Contraseña incorrecta');
      }

      final appUser = AppUser.fromMap(cleanCode, data);

      try {
        await ref.update({
          'ultimoAcceso': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

            final prefs = await SharedPreferences.getInstance();
      await prefs.setString(sessionKey, jsonEncode(appUser.toSessionMap()));
      await prefs.setInt(lastActivityKey, DateTime.now().millisecondsSinceEpoch);

      _user = appUser;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

    Future<void> updateActivity() async {
    if (_user == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> checkInactivity() async {
    if (_user == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt(lastActivityKey);

    if (lastActivity == null) {
      await logout();
      return;
    }

    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastActivity);
    final expired = DateTime.now().difference(lastDate) >= inactivityLimit;

    if (expired) {
      await logout();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(sessionKey);
    await prefs.remove(lastActivityKey);
    _user = null;
    notifyListeners();
  }
}