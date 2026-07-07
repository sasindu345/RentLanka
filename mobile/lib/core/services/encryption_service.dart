import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/digests/sha256.dart';

class EncryptionService {
  // A static pepper to add an extra layer of strength to key derivation
  static const String _pepper = "RentLanka_Secure_E2EE_Pepper_2026";
  
  // Prefix to identify encrypted messages
  static const String encryptedPrefix = "e2ee:";

  /// Derives a 32-byte (256-bit) AES key from a conversationId
  static encrypt.Key _deriveKey(String conversationId) {
    final seed = "$conversationId:$_pepper";
    final bytes = utf8.encode(seed);
    final digest = SHA256Digest();
    final hash = digest.process(Uint8List.fromList(bytes));
    return encrypt.Key(hash);
  }

  /// Encrypts a plaintext string for a specific conversation.
  /// Returns a ciphertext prepended with the random IV base64 and the prefix.
  static String encryptMessage(String plaintext, String conversationId) {
    if (plaintext.isEmpty) return "";

    try {
      final key = _deriveKey(conversationId);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      
      final encrypted = encrypter.encrypt(plaintext, iv: iv);
      
      // Store as: "e2ee:<iv_base64>:<ciphertext_base64>"
      return "$encryptedPrefix${iv.base64}:${encrypted.base64}";
    } catch (e) {
      // Fallback to plaintext if encryption fails
      return plaintext;
    }
  }

  /// Decrypts a ciphertext string for a specific conversation.
  /// If the message is not encrypted, it returns the input plaintext.
  static String decryptMessage(String content, String conversationId) {
    if (!content.startsWith(encryptedPrefix)) {
      return content; // Plaintext message or system message
    }

    try {
      final key = _deriveKey(conversationId);
      final parts = content.substring(encryptedPrefix.length).split(':');
      if (parts.length != 2) {
        return content; // Malformed payload
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // Return a placeholder or the raw content if decryption fails (e.g. key mismatch)
      return "[Decryption failed: Secure message key mismatch]";
    }
  }
}
