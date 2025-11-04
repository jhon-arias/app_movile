import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gastos_app/auth/auth_service.dart';
import 'package:gastos_app/screens/add_transaction_screen.dart';
import 'package:gastos_app/app/theme.dart';
import 'package:gastos_app/widgets/app_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isPasswordVisible =
      false; // Variable para controlar visibilidad de contraseña

  @override
  void initState() {
    super.initState();
    // Precargar imágenes para evitar delays en las transiciones
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _precacheImages();
      _checkActiveSession();
    });
  }

  void _precacheImages() {
    if (mounted) {
      precacheImage(const AssetImage('assets/images/logo.png'), context);
      precacheImage(const AssetImage('assets/images/icon.png'), context);
    }
  }

  Future<void> _checkActiveSession() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final hasActiveSession = await authService.checkActiveSession();

    if (hasActiveSession && mounted) {
      _navigateToMainScreen();
    }
  }

  void _navigateToMainScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
  }

  // Método de debug para probar credenciales
  void _clearError() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.errorMessage != null) {
      authService.clearError();
    }
  }

  Future<void> _submitForm(AuthService authService) async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final success = _isLogin
        ? await authService.loginWithEmail(
            _emailController.text,
            _passwordController.text,
          )
        : await authService.registerWithEmail(
            _emailController.text,
            _passwordController.text,
          );

    if (success && mounted) {
      _navigateToMainScreen();
    }
  }

  void _toggleAuthMode() {
    _clearError();
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAppHeader(),
              const SizedBox(height: 40),
              Consumer<AuthService>(
                builder: (context, authService, child) {
                  return _buildLoginForm(authService);
                },
              ),
              const SizedBox(height: 20),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Column(
      children: [
        AppLogoWithShadow(
          size: 80,
          shadowColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
        const SizedBox(height: 20),
        const Text(
          'Gestión de Finanzas\nPersonales',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Controla tus gastos e ingresos fácilmente',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildLoginForm(AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 24),
            _buildEmailField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 12),
            const SizedBox(height: 20),
            if (authService.errorMessage != null)
              _buildErrorMessage(authService.errorMessage!),
            _buildLoginButton(authService),
            const SizedBox(height: 16),
            _buildToggleAuthText(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email, color: AppTheme.primaryColor),
        hintText: 'Email',
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.normal,
        ),
      ),
      style: const TextStyle(
        fontWeight: FontWeight.normal,
      ), // El texto ingresado no será en negrita
      onChanged: (_) => _clearError(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock, color: AppTheme.primaryColor),
        hintText: 'Contraseña',
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.normal,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          tooltip: _isPasswordVisible
              ? 'Ocultar contraseña'
              : 'Mostrar contraseña',
        ),
      ),
      style: const TextStyle(
        fontWeight: FontWeight.normal,
      ), // El texto ingresado no será en negrita
      onChanged: (_) => _clearError(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingrese su contraseña';
        }
        return null;
      },
    );
  }

  // Widget para el checkbox de recordar contraseña

  Widget _buildErrorMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLogin ? 'Error al iniciar sesión' : 'Error al registrarse',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: Colors.red.shade600),
            onPressed: _clearError,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AuthService authService) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: authService.isLoading
            ? null
            : () => _submitForm(authService),
        child: authService.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleAuthText() {
    return TextButton(
      onPressed: _toggleAuthMode,
      child: Text(
        _isLogin
            ? '¿No tienes cuenta? Regístrate'
            : '¿Ya tienes cuenta? Inicia Sesión',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.copyright, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Datealo ${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
