import 'package:flutter/material.dart';
import 'package:gastos_app/models/transaction_model.dart';
import 'package:gastos_app/app/theme.dart';
import 'package:intl/intl.dart';

class RecentTransactionsWidget extends StatefulWidget {
  final List<Transaction> transactions;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(String)? onDeleteTransaction; // Nuevo callback para eliminar

  const RecentTransactionsWidget({
    Key? key,
    required this.transactions,
    required this.isLoading,
    required this.onRefresh,
    this.onDeleteTransaction, // Callback opcional
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
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: AppTheme.resumenColor.withOpacity(0.7),
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
                    color: AppTheme.textColor,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ver últimos registros',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      icon: const Icon(Icons.refresh, size: 14),
                      onPressed: widget.onRefresh,
                      style: IconButton.styleFrom(
                        foregroundColor: AppTheme.textColor,
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                      ),
                      tooltip: 'Actualizar',
                    ),
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
                  : (widget.transactions.length * 45.0).clamp(
                      80.0,
                      350.0,
                    ), // Altura optimizada para mostrar hasta 15 transacciones (350px = ~7-8 registros visibles)
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
              'No hay transacciones\nrecientes',
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

    // Tomar solo las 15 transacciones más recientes
    final recentTransactions = sortedTransactions.take(15).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(0),
      shrinkWrap: true, // Ajustar al contenido
      physics:
          const ClampingScrollPhysics(), // Habilitar scroll para ver todos los registros
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Columna con precio y tipo
            Column(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
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
            // Botón de eliminar (solo si hay callback)
            if (widget.onDeleteTransaction != null) ...[
              const SizedBox(width: 4),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  icon: Icon(
                    Icons
                        .delete_forever, // Cambiar a icono de tacho más visible
                    size: 16,
                    color: Colors.red.shade600,
                  ),
                  onPressed: () => _showDeleteConfirmation(transaction),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade600,
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: 'Eliminar transacción',
                ),
              ),
            ],
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

  // Método para mostrar el diálogo de confirmación de eliminación
  void _showDeleteConfirmation(Transaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false, // Evitar que se cierre tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Confirmar eliminación',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que deseas eliminar esta transacción?',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${transaction.amount.toStringAsFixed(0)} - ${transaction.categoryName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (transaction.id != null) {
                  widget.onDeleteTransaction!(transaction.id!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_forever, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    'Eliminar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        );
      },
    );
  }
}
