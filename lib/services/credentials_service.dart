import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const String _credentialsKey = 'gastos_app_credentials';

  // Método que funciona tanto en web como en móviles
  static Future<void> saveCredentials(String email, String password) async {
    try {
      if (kIsWeb) {
        // Para web, usar SharedPreferences
        await _saveCredentialsWeb(email, password);
      } else {
        // Para móviles, usar archivos
        await _saveCredentialsFile(email, password);
      }
    } catch (e) {
      print('Error al guardar credenciales: $e');
      rethrow;
    }
  }

  static Future<Map<String, String>?> getSavedCredentials() async {
    try {
      Map<String, String>? credentials;

      if (kIsWeb) {
        // Para web, usar SharedPreferences
        credentials = await _getCredentialsWeb();
      } else {
        // Para móviles, usar archivos
        credentials = await _getCredentialsFile();
      }

      return credentials;
    } catch (e) {
      print('Error al obtener credenciales: $e');
      return null;
    }
  }

  static Future<void> clearCredentials() async {
    try {
      if (kIsWeb) {
        // Para web, usar SharedPreferences
        await _clearCredentialsWeb();
      } else {
        // Para móviles, usar archivos
        await _clearCredentialsFile();
      }
    } catch (e) {
      print('Error al limpiar credenciales: $e');
      rethrow;
    }
  }

  // Implementación para Web usando SharedPreferences
  static Future<void> _saveCredentialsWeb(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsMap = {'email': email, 'password': password};
    final credentialsJson = jsonEncode(credentialsMap);
    await prefs.setString(_credentialsKey, credentialsJson);
  }

  static Future<Map<String, String>?> _getCredentialsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsJson = prefs.getString(_credentialsKey);

    if (credentialsJson != null) {
      final credentialsMap =
          jsonDecode(credentialsJson) as Map<String, dynamic>;
      return {
        'email': credentialsMap['email'] as String,
        'password': credentialsMap['password'] as String,
      };
    }

    return null;
  }

  static Future<void> _clearCredentialsWeb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_credentialsKey);
  }

  // Implementación para móviles usando archivos
  static Future<void> _saveCredentialsFile(
    String email,
    String password,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/credentials.json');

    final credentials = {'email': email, 'password': password};

    await file.writeAsString(jsonEncode(credentials));
  }

  static Future<Map<String, String>?> _getCredentialsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/credentials.json');

    if (await file.exists()) {
      final contents = await file.readAsString();
      final credentials = jsonDecode(contents) as Map<String, dynamic>;

      return {
        'email': credentials['email'] as String,
        'password': credentials['password'] as String,
      };
    }

    return null;
  }

  static Future<void> _clearCredentialsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/credentials.json');

    if (await file.exists()) {
      await file.delete();
    }
  }
}
