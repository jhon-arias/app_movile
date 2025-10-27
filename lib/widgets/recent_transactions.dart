import 'package:flutter/material.dart';
import 'package:gastos_app/models/transaction_model.dart';
import 'package:gastos_app/app/theme.dart';
import 'package:intl/intl.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final bool isLoading;
  final VoidCallback onRefresh;

  const RecentTransactionsWidget({
    Key? key,
    required this.transactions,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.history,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Últimos 5 días',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                if (transactions.isNotEmpty)
                  Text(
                    'Total: \$${_calculateTotal().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: onRefresh,
                  color: AppTheme.primaryColor,
                  tooltip: 'Actualizar',
                ),
              ],
            ),
          ),

          // Lista de transacciones
          Expanded(
            child: isLoading
                ? _buildLoading()
                : transactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cargando...',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          const Text(
            'No hay transacciones\nen los últimos 5 días',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Ordenar por fecha más reciente primero
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: sortedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = sortedTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isExpense = transaction.type.contains('gasto');
    final dateFormat = DateFormat('dd/MM');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isExpense ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isExpense ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: isExpense ? Colors.red : Colors.green,
            size: 20,
          ),
        ),
        title: Text(
          transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              transaction.categoryName,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            Text(
              '${dateFormat.format(transaction.date)} ${timeFormat.format(transaction.date)}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTypeColor(transaction.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getTypeColor(transaction.type).withOpacity(0.3),
                ),
              ),
              child: Text(
                _getTypeLabel(transaction.type),
                style: TextStyle(
                  fontSize: 8,
                  color: _getTypeColor(transaction.type),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'gasto_fijo':
        return Colors.orange;
      case 'gasto_variable':
        return Colors.red;
      case 'ingreso_fijo':
        return Colors.green;
      case 'ingreso_variable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'gasto_fijo':
        return 'Fijo';
      case 'gasto_variable':
        return 'Variable';
      case 'ingreso_fijo':
        return 'Fijo';
      case 'ingreso_variable':
        return 'Variable';
      default:
        return 'Otro';
    }
  }

  double _calculateTotal() {
    return transactions.fold(0.0, (sum, transaction) {
      if (transaction.type.contains('gasto')) {
        return sum - transaction.amount;
      } else {
        return sum + transaction.amount;
      }
    });
  }
}
