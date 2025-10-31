import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SecureStorageService {
  static const String _fileName = 'user_credentials.json';

  // Obtener el archivo de credenciales
  static Future<File> _getCredentialsFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  // Guardar credenciales
  static Future<void> saveCredentials(String email, String password) async {
    try {
      final file = await _getCredentialsFile();
      final credentials = {
        'email': email,
        'password': password,
        'rememberMe': true,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await file.writeAsString(jsonEncode(credentials));
    } catch (e) {
      print('Error al guardar credenciales: $e');
    }
  }

  // Obtener email guardado
  static Future<String?> getSavedEmail() async {
    try {
      final credentials = await getSavedCredentials();
      return credentials['email'];
    } catch (e) {
      print('Error al obtener email: $e');
      return null;
    }
  }

  // Obtener contraseña guardada
  static Future<String?> getSavedPassword() async {
    try {
      final credentials = await getSavedCredentials();
      return credentials['password'];
    } catch (e) {
      print('Error al obtener contraseña: $e');
      return null;
    }
  }

  // Verificar si está habilitado "recordar me"
  static Future<bool> isRememberMeEnabled() async {
    try {
      final credentials = await getSavedCredentials();
      return credentials['rememberMe'] == 'true';
    } catch (e) {
      print('Error al verificar remember me: $e');
      return false;
    }
  }

  // Obtener credenciales completas
  static Future<Map<String, String?>> getSavedCredentials() async {
    try {
      final file = await _getCredentialsFile();

      if (!await file.exists()) {
        return {'email': null, 'password': null, 'rememberMe': 'false'};
      }

      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      return {
        'email': data['email'],
        'password': data['password'],
        'rememberMe': data['rememberMe'].toString(),
      };
    } catch (e) {
      print('Error al obtener credenciales: $e');
      return {'email': null, 'password': null, 'rememberMe': 'false'};
    }
  }

  // Eliminar credenciales guardadas
  static Future<void> clearCredentials() async {
    try {
      final file = await _getCredentialsFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error al limpiar credenciales: $e');
    }
  }

  // Actualizar estado de "recordar me"
  static Future<void> setRememberMe(bool remember) async {
    try {
      if (!remember) {
        await clearCredentials();
      } else {
        // Si ya existen credenciales, mantenerlas pero marcar remember como true
        final credentials = await getSavedCredentials();
        if (credentials['email'] != null && credentials['password'] != null) {
          await saveCredentials(
            credentials['email']!,
            credentials['password']!,
          );
        }
      }
    } catch (e) {
      print('Error al actualizar remember me: $e');
    }
  }

  // Verificar si las credenciales guardadas no son muy antiguas (para seguridad)
  static Future<bool> areCredentialsValid() async {
    try {
      final file = await _getCredentialsFile();

      if (!await file.exists()) {
        return false;
      }

      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      if (data['timestamp'] == null) {
        return false;
      }

      final savedTime = DateTime.parse(data['timestamp']);
      final now = DateTime.now();
      final difference = now.difference(savedTime).inDays;

      // Las credenciales son válidas por 30 días
      return difference <= 30;
    } catch (e) {
      print('Error al verificar validez de credenciales: $e');
      return false;
    }
  }
}
