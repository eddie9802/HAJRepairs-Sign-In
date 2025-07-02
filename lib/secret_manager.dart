import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'key_manager.dart';

class SecretManager {
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;
  late String _encryptedApiKey;
  final _secureStorage = const FlutterSecureStorage();
  final _azureSecretId = "AZURE_SECRET";


  SecretManager._(this._iv, this._encrypter);


  static Future<SecretManager> create() async {
    final key = await KeyManager().getOrCreateKey();
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return SecretManager._(iv, encrypter);
  }

  Future<String> _getAzureSecret() async {
    String? secret = await _secureStorage.read(key: _azureSecretId);

    if (secret != null) {
      return secret;
    }

    final secretString = dotenv.env['AZURE_SECRET'] ?? '';
    if (secretString.isEmpty) {
      throw Exception('Azure secret missing from environment!');
    }

    // Store securely
    await _secureStorage.write(key: _azureSecretId, value: secretString);

    return secretString;
  }

  Future<void> loadAndEncrypt() async {
    final secret = await _getAzureSecret();
    _encryptedApiKey = _encrypter.encrypt(secret, iv: _iv).base64;
    // apiKey should be discarded now
  }

  String getDecryptedSecret() {
    return _encrypter.decrypt64(_encryptedApiKey, iv: _iv);
  }
}