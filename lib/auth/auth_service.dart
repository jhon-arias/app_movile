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

    // Validación básica antes de enviar a AppWrite
    final validationError = _validateCredentials(email, password);
    if (validationError != null) {
      _isLoading = false;
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

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

    // Validación básica antes de enviar a AppWrite
    final validationError = _validateCredentials(email, password);
    if (validationError != null) {
      _isLoading = false;
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

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

  String? _validateCredentials(String email, String password) {
    // Validar formato de email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      return 'Por favor ingrese un email válido\nEjemplo: usuario@correo.com';
    }

    // Validar contraseña
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    if (password.length > 50) {
      return 'La contraseña no puede tener más de 50 caracteres';
    }

    // Validar email no excesivamente largo
    if (email.length > 100) {
      return 'El email es demasiado largo';
    }

    return null;
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString();

    // Errores de formato de email
    if (errorString.contains('invalid email param') ||
        errorString.contains('value must be a valid email address')) {
      return 'El formato del email no es válido.\nPor favor ingrese un email como: usuario@correo.com';
    }

    // Errores de contraseña
    if (errorString.contains('password') && errorString.contains('invalid')) {
      return 'La contraseña no cumple con los requisitos de seguridad';
    }

    // Usuario ya existe
    if (errorString.contains('user_already_exists') ||
        errorString.contains('account_already_exists')) {
      return 'Ya existe una cuenta con este email.\n¿Quizás quieres iniciar sesión?';
    }

    // Credenciales inválidas
    if (errorString.contains('invalid_credentials') ||
        errorString.contains('Unauthorized') ||
        errorString.contains('401')) {
      return 'Email o contraseña incorrectos.\nPor favor verifica tus credenciales.';
    }

    // Contraseña débil
    if (errorString.contains('weak_password') ||
        errorString.contains('password strength')) {
      return 'La contraseña es muy débil.\nUsa al menos 6 caracteres incluyendo letras y números.';
    }

    // Problemas de conexión
    if (errorString.contains('Network is unreachable') ||
        errorString.contains('timeout') ||
        errorString.contains('socket')) {
      return 'Problema de conexión.\nVerifica tu conexión a internet e intenta nuevamente.';
    }

    // Límite de caracteres
    if (errorString.contains('must be at most') ||
        errorString.contains('too long')) {
      return 'El email o contraseña son demasiado largos.\nEmail máximo 100 caracteres, contraseña máximo 50.';
    }

    // Error genérico de AppWrite
    if (errorString.contains('AppwriteException')) {
      return 'Error en el servidor. Por favor intenta nuevamente.';
    }

    // Error desconocido
    return 'Ocurrió un error inesperado. Por favor intenta nuevamente.';
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

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
}
