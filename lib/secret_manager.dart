import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_manager.dart';
import 'iv_manager.dart';

class SecretManager {
  late final encrypt.Encrypter _encrypter;
  encrypt.IV _iv;
  late String _encryptedApiKey;
  final _secureStorage = const FlutterSecureStorage();
  final _azureSecretId = "AZURE_SECRET";


  SecretManager._(this._iv, this._encrypter);


  static Future<SecretManager> create() async {
    final key = await KeyManager().getOrCreateKey();
    final iv = await IVManager().getOrCreateIV();
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return SecretManager._(iv, encrypter);
  }

  // Future<String> _getAzureSecret() async {
  //   String? secret = await _secureStorage.read(key: _azureSecretId);

  //   if (secret != null) {
  //     return secret;
  //   }

  //   final secretString = dotenv.env['AZURE_SECRET'] ?? '';
  //   if (secretString.isEmpty) {
  //     throw Exception('Azure secret missing from environment!');
  //   }

  //   // Store securely
  //   await _secureStorage.write(key: _azureSecretId, value: secretString);

  //   return secretString;
  // }

  // Future<void> loadAndEncrypt() async {
  //   final secret = await _getAzureSecret();
  //   _encryptedApiKey = _encrypter.encrypt(secret, iv: _iv).base64;
  //   // apiKey should be discarded now
  // }


  Future<void> writeNewEncryptedSecret(String newSecret) async {

    // Creates a new IV for the new secret
    // This ensures that the new secret is encrypted with a fresh IV
    await IVManager().clearIV();
    _iv = await IVManager().getOrCreateIV();
    _encryptedApiKey = _encrypter.encrypt(newSecret, iv: _iv).base64;
    await _secureStorage.write(key: _azureSecretId, value: _encryptedApiKey);
  }

  Future<String> getDecryptedSecret() async {
    String encryptedApiKey = await _secureStorage.read(key: _azureSecretId) ?? '';
    return _encrypter.decrypt64(encryptedApiKey, iv: _iv);
  }
}