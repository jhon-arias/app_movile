import 'package:flutter/material.dart';
import 'package:gastos_app/models/transaction_model.dart';
import 'package:gastos_app/app/theme.dart';
import 'package:intl/intl.dart';

class RecentTransactionsWidget extends StatefulWidget {
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
  State<RecentTransactionsWidget> createState() =>
      _RecentTransactionsWidgetState();
}

class _RecentTransactionsWidgetState extends State<RecentTransactionsWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Importante: se ajusta al contenido
        children: [
          // Header con funcionalidad de click para expandir/contraer
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: _isExpanded
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      )
                    : BorderRadius.circular(
                        8,
                      ), // Bordes redondeados completos cuando está contraído
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Últimos registros',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 16),
                    onPressed: widget.onRefresh,
                    style: IconButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      backgroundColor: Colors.transparent,
                      minimumSize: const Size(24, 24),
                      padding: const EdgeInsets.all(4),
                    ),
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
            ),
          ),

          // Lista de transacciones (solo visible cuando está expandido)
          if (_isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: widget.isLoading
                  ? 80
                  : widget.transactions.isEmpty
                  ? 100
                  : (widget.transactions.length * 50.0).clamp(
                      80.0,
                      180.0,
                    ), // Altura más pequeña con elementos compactos
              child: widget.isLoading
                  ? _buildLoading()
                  : widget.transactions.isEmpty
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            const Text(
              'No hay transacciones\nen los últimos 5 días',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Ordenar por fecha y hora más reciente primero (doble verificación)
    final sortedTransactions = List<Transaction>.from(widget.transactions)
      ..sort((a, b) {
        // Primero ordenar por fecha de transacción
        int comparison = b.date.compareTo(a.date);
        if (comparison != 0) return comparison;

        // Si las fechas son iguales, ordenar por fecha de creación si está disponible
        if (a.createdAt != null && b.createdAt != null) {
          return b.createdAt!.compareTo(a.createdAt!);
        }

        return 0;
      });

    // Tomar solo las 5 transacciones más recientes
    final recentTransactions = sortedTransactions.take(5).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(0),
      shrinkWrap: true, // Ajustar al contenido
      physics: const NeverScrollableScrollPhysics(), // Desactivar scroll propio
      itemCount: recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = recentTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isExpense = transaction.type.contains('gasto');
    final dateFormat = DateFormat('dd/MM');
    final timeFormat = DateFormat('HH:mm');

    // Convertir a UTC para mostrar la hora en UTC
    final utcDate = transaction.date.toUtc();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        dense: true,
        minLeadingWidth: 28,
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isExpense ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isExpense ? Colors.red.shade200 : Colors.green.shade200,
              width: 0.5,
            ),
          ),
          child: Icon(
            isExpense ? Icons.arrow_upward : Icons.arrow_downward,
            color: isExpense ? Colors.red : Colors.green,
            size: 14,
          ),
        ),
        title: Text(
          transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.categoryName,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            Text(
              '${dateFormat.format(utcDate)} ${timeFormat.format(utcDate)} UTC',
              style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${transaction.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: _getTypeColor(transaction.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: _getTypeColor(transaction.type).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                _getTypeLabel(transaction.type),
                style: TextStyle(
                  fontSize: 7,
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
}
