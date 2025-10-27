import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gastos_app/auth/auth_service.dart';
import 'package:gastos_app/auth/login_screen.dart';
import 'package:gastos_app/screens/add_transaction_screen.dart';
import 'package:gastos_app/app/theme.dart';

class GastosApp extends StatelessWidget {
  const GastosApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Gestión de Finanzas Personales',
        theme: AppTheme.lightTheme,
        home: Consumer<AuthService>(
          builder: (context, authService, child) {
            return FutureBuilder(
              future: authService.getCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }

                final user = snapshot.data;
                if (user != null) {
                  return const AddTransactionScreen();
                } else {
                  return const LoginScreen();
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAppLogo(),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cargando...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.account_balance_wallet,
        size: 50,
        color: Colors.white,
      ),
    );
  }
}
