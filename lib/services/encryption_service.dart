import 'dart:convert';

/// Simple and lightweight encryption service for basic text obfuscation.
/// Uses XOR cipher with a fixed constant key - no initialization required.
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // Fixed constant key for obfuscation (not strong security)
  static const String _key = 'MySecretKey2024';

  /// Encrypts text using simple XOR cipher with the fixed key.
  String encryptText(String plainText) {
    if (plainText.isEmpty) return plainText;
    
    final keyBytes = utf8.encode(_key);
    final textBytes = utf8.encode(plainText);
    final result = <int>[];
    
    for (int i = 0; i < textBytes.length; i++) {
      result.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    // Convert to base64 for safe string storage
    return base64Encode(result);
  }

  /// Decrypts text using simple XOR cipher with the fixed key.
  String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    
    try {
      final encryptedBytes = base64Decode(encryptedText);
      final keyBytes = utf8.encode(_key);
      final result = <int>[];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        result.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(result);
    } catch (e) {
      // If base64 decode fails or utf8 decode fails, try old format
      try {
        // Try interpreting as legacy base64 encoded string (using codeUnits/fromCharCodes)
        final encryptedBytes = base64Decode(encryptedText);
        final keyBytes = _key.codeUnits;
        final result = <int>[];
        for (int i = 0; i < encryptedBytes.length; i++) {
          result.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
        }
        return String.fromCharCodes(result);
      } catch (_) {
         // Final fallback: direct XOR without base64 (as seen in original code's catch block)
        final keyBytes = _key.codeUnits;
        final textBytes = encryptedText.codeUnits;
        final result = <int>[];
        
        for (int i = 0; i < textBytes.length; i++) {
          result.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
        }
        
        return String.fromCharCodes(result);
      }
    }
  }

  /// Always initialized (no setup needed).
  bool get isInitialized => true;
}
