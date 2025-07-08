import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class IVManager {
  static const _ivStorageKey = 'encryption_iv';
  final _secureStorage = const FlutterSecureStorage();

  /// Retrieves existing IV or generates and stores a new one
  Future<IV> getOrCreateIV() async {
    String? storedIV = await _secureStorage.read(key: _ivStorageKey);

    if (storedIV != null) {
      // Decode from base64 and return
      return IV(base64Url.decode(storedIV));
    }

    // Generate secure 16-byte IV
    final randomIV = encrypt.IV.fromLength(16);

    // Store securely
    await _secureStorage.write(key: _ivStorageKey, value: randomIV.base64);

    return IV.fromBase64(randomIV.base64);
  }

  /// Optional: clear stored IV (e.g., for testing or logout)
  Future<void> clearIV() async {
    await _secureStorage.delete(key: _ivStorageKey);
  }
}
