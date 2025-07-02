import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SecretManager {
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;
  late String _encryptedApiKey;

  SecretManager() {
    final key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows!');
    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(key));
  }

  void loadAndEncrypt() {
    final apiKey = dotenv.env['AZURE_SECRET'] ?? '';
    _encryptedApiKey = _encrypter.encrypt(apiKey, iv: _iv).base64;
    // apiKey should be discarded now
  }

  String getDecryptedApiKey() {
    return _encrypter.decrypt64(_encryptedApiKey, iv: _iv);
  }
}