import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';

class KeyManager {
  static const _keyStorageKey = 'encryption_key';
  final _secureStorage = const FlutterSecureStorage();

  /// Retrieves existing key or generates and stores a new one
  Future<Key> getOrCreateKey() async {
    String? storedKey = await _secureStorage.read(key: _keyStorageKey);

    if (storedKey != null) {
      // Decode from base64 and return
      return Key(base64Url.decode(storedKey));
    }

    // Generate secure 32-byte key
    final randomKey = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final base64Key = base64UrlEncode(randomKey);

    // Store securely
    await _secureStorage.write(key: _keyStorageKey, value: base64Key);

    return Key(base64Url.decode(base64Key));
  }

  /// Optional: clear stored key (e.g., for testing or logout)
  Future<void> clearKey() async {
    await _secureStorage.delete(key: _keyStorageKey);
  }
}
