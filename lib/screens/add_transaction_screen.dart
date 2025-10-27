import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gastos_app/auth/auth_service.dart';
import 'package:gastos_app/models/transaction_model.dart';
import 'package:gastos_app/services/appwrite_service.dart';
import 'package:gastos_app/screens/statistics_screen.dart';
import 'package:gastos_app/widgets/transaction_form.dart';
import 'package:gastos_app/widgets/recent_transactions.dart';
import 'package:gastos_app/app/theme.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({Key? key}) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final AppWriteService _appWriteService = AppWriteService();
  String? _currentUserId;
  List<Transaction> _recentTransactions = [];
  bool _isLoadingRecent = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = await _appWriteService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUserId = user?.$id);
        if (_currentUserId != null) {
          await _loadRecentTransactions();
        }
      }
    } catch (e) {
      _showError('Error al obtener usuario: $e');
    }
  }

  Future<void> _loadRecentTransactions() async {
    if (_currentUserId == null) return;

    setState(() => _isLoadingRecent = true);

    try {
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      final transactions = await _appWriteService.getTransactionsByDateRange(
        _currentUserId!,
        fiveDaysAgo,
        DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _recentTransactions = transactions;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
    }
  }

  Future<void> _addTransaction(Transaction transaction) async {
    if (_currentUserId == null) {
      _showError('Usuario no identificado');
      return;
    }

    try {
      final transactionWithUser = Transaction(
        userId: _currentUserId!,
        amount: transaction.amount,
        description: transaction.description,
        categoryName: transaction.categoryName,
        date: transaction.date,
        type: transaction.type,
        category: transaction.category,
        isFixed: transaction.isFixed,
      );

      await _appWriteService.addTransaction(transactionWithUser);

      // Recargar las transacciones recientes después de agregar una nueva
      await _loadRecentTransactions();
    } catch (e) {
      _showError('Error al registrar: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _navigateToStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatisticsScreen()),
    );
  }

  Future<void> _logout() async {
    try {
      await Provider.of<AuthService>(context, listen: false).logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      _showError('Error al cerrar sesión: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet, size: 24),
            SizedBox(width: 8),
            Text('Gestión de Finanzas'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 24),
            onPressed: _navigateToStatistics,
            tooltip: 'Estadísticas',
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 24),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulario de transacción
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TransactionForm(onSubmit: _addTransaction),
            ),
          ),

          // Transacciones recientes
          Expanded(
            flex: 1,
            child: RecentTransactionsWidget(
              transactions: _recentTransactions,
              isLoading: _isLoadingRecent,
              onRefresh: _loadRecentTransactions,
            ),
          ),

          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
    );
  }
}
