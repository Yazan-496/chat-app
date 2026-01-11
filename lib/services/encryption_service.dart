import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  // For a real-world app, manage keys securely. This is a simplified example.
  // You might derive a key from user's password or use a key exchange protocol.
  static final _key = encrypt.Key.fromBase64('MThlMTk0ZTc3ZGUxMzcwMDI3ZGMwNzI1NjJlNjE0YjI='); // Fixed 256-bit key from base64
  static final _iv = encrypt.IV.fromBase64('MjM0ODcwYmE5NGRjMjNiNg=='); // Fixed 128-bit IV from base64
  static final _encrypter = encrypt.Encrypter(encrypt.AES(_key));

  String encryptText(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decryptText(String encryptedText) {
    final decrypted = _encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedText), iv: _iv);
    return decrypted;
  }
}
