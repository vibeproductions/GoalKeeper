// lib/services/keychain_service.dart
// Secure storage — equivalent to KeychainService.swift
// Uses flutter_secure_storage on both macOS and Windows

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeychainService {
  static const _storage   = FlutterSecureStorage();
  static const _apiKeyKey = 'anthropic_api_key';
  static const _modelKey  = 'selected_model';
  static const _scaleKey  = 'display_scale';

  // ── API Key ───────────────────────────────────────────────────────────────

  static Future<void> saveApiKey(String key) async {
    await _storage.write(key: _apiKeyKey, value: key);
  }

  static Future<String?> loadApiKey() async {
    return await _storage.read(key: _apiKeyKey);
  }

  static Future<void> deleteApiKey() async {
    await _storage.delete(key: _apiKeyKey);
  }

  static Future<bool> get hasApiKey async {
    final key = await loadApiKey();
    return key != null && key.isNotEmpty;
  }

  // ── Model preference ──────────────────────────────────────────────────────

  static Future<String> get selectedModel async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? 'claude-haiku-4-5';
  }

  static Future<void> setSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }

  // ── Display scale ─────────────────────────────────────────────────────────

  static Future<double> loadDisplayScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_scaleKey) ?? 1.0;
  }

  static Future<void> setDisplayScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_scaleKey, scale);
  }
}
