import 'package:flutter/foundation.dart';
import 'package:gastos_app/services/appwrite_service.dart';

class AuthService with ChangeNotifier {
  final AppWriteService _appWriteService = AppWriteService();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _appWriteService.createEmailPasswordSession(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _appWriteService.createEmailPasswordAccount(email, password);
      // Iniciar sesión automáticamente después del registro
      await _appWriteService.createEmailPasswordSession(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  // ELIMINADO: loginWithGoogle - Ya no se necesita

  Future<void> logout() async {
    try {
      await _appWriteService.logout();
    } catch (e) {
      // Ignorar errores en logout
    }
  }

  Future<dynamic> getCurrentUser() async {
    try {
      return await _appWriteService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  Future<bool> checkActiveSession() async {
    try {
      return await _appWriteService.checkSession();
    } catch (e) {
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('user_already_exists')) {
      return 'El usuario ya existe';
    } else if (error.toString().contains('invalid_credentials')) {
      return 'Email o contraseña incorrectos';
    } else if (error.toString().contains('weak_password')) {
      return 'La contraseña es muy débil';
    } else if (error.toString().contains('invalid_email')) {
      return 'Email inválido';
    } else {
      return 'Error de autenticación: ${error.toString()}';
    }
  }
}
