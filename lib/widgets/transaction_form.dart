import 'package:flutter/material.dart';
import 'package:gastos_app/models/transaction_model.dart';
import 'package:gastos_app/app/theme.dart';

class TransactionForm extends StatefulWidget {
  final Function(Transaction) onSubmit;

  const TransactionForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'gasto';
  String _selectedCategory = 'otros';
  bool _isFixed = false;
  DateTime _selectedDate = DateTime.now();

  final List<Map<String, String>> _categories = [
    {'value': 'ropa', 'label': 'Ropa'},
    {'value': 'salud', 'label': 'Salud'},
    {'value': 'vivienda', 'label': 'Vivienda'},
    {'value': 'transporte', 'label': 'Transporte'},
    {'value': 'comida', 'label': 'Comida'},
    {'value': 'entretenimiento', 'label': 'Entretenimiento'},
    {'value': 'educacion', 'label': 'Educación'},
    {'value': 'servicios', 'label': 'Servicios'},
    {'value': 'ahorro', 'label': 'Ahorro'},
    {'value': 'otros', 'label': 'Otros'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final transaction = Transaction(
      userId: '',
      amount: double.parse(_amountController.text),
      description: _descriptionController.text,
      categoryName: _getCategoryLabel(),
      date: _selectedDate,
      type: _getFullType(),
      category: _selectedCategory,
      isFixed: _isFixed,
    );

    widget.onSubmit(transaction);
    _clearForm();
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();

    setState(() {
      _selectedType = 'gasto';
      _selectedCategory = 'otros';
      _isFixed = false;
      _selectedDate = DateTime.now();
    });

    _showSuccessMessage();
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Transacción registrada exitosamente'),
        backgroundColor: AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getFullType() {
    if (_selectedType == 'ingreso') {
      return _isFixed ? 'ingreso_fijo' : 'ingreso_variable';
    }
    return _isFixed ? 'gasto_fijo' : 'gasto_variable';
  }

  String _getCategoryLabel() {
    return _categories.firstWhere(
      (cat) => cat['value'] == _selectedCategory,
    )['label']!;
  }

  String _getTypeDisplay() {
    if (_selectedType == 'gasto') {
      return _isFixed ? 'Gasto Fijo' : 'Gasto Variable';
    }
    return _isFixed ? 'Ingreso Fijo' : 'Ingreso Variable';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAmountField(),
            const SizedBox(height: 12),
            _buildDescriptionField(),
            const SizedBox(height: 12),
            _buildTypeButtons(),
            const SizedBox(height: 12),
            _buildFixedToggle(),
            const SizedBox(height: 12),
            _buildCategoryDropdown(),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Monto',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
        prefixText: '\$ ',
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Ingrese el monto';
        final amount = double.tryParse(value!);
        if (amount == null || amount <= 0) return 'Monto inválido';
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Descripción',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLength: 500,
      maxLines: 3,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Ingrese una descripción';
        return null;
      },
    );
  }

  Widget _buildTypeButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton(
                'gasto',
                'Gasto',
                Icons.remove,
                Colors.red,
                _selectedType == 'gasto',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTypeButton(
                'ingreso',
                'Ingreso',
                Icons.add,
                Colors.green,
                _selectedType == 'ingreso',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeButton(
    String value,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade500,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFixedToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedType == 'gasto'
                            ? 'Gasto Fijo'
                            : 'Ingreso Fijo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedType == 'gasto'
                            ? 'Gasto recurrente (alquiler, servicios)'
                            : 'Ingreso recurrente (salario)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _isFixed,
                  onChanged: (value) => setState(() => _isFixed = value),
                  activeColor: AppTheme.secondaryColor,
                  activeTrackColor: AppTheme.secondaryColor.withOpacity(0.3),
                  inactiveThumbColor: Colors.grey.shade400,
                  inactiveTrackColor: Colors.grey.shade200,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isFixed
                    ? AppTheme.secondaryColor.withOpacity(0.1)
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isFixed
                      ? AppTheme.secondaryColor.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isFixed ? Icons.autorenew : Icons.trending_up,
                    size: 16,
                    color: _isFixed
                        ? AppTheme.primaryColor
                        : Colors.blue.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _isFixed
                          ? '${_selectedType == 'gasto' ? 'Gasto' : 'Ingreso'} RECURRENTE'
                          : '${_selectedType == 'gasto' ? 'Gasto' : 'Ingreso'} OCASIONAL',
                      style: TextStyle(
                        fontSize: 11,
                        color: _isFixed
                            ? AppTheme.primaryColor
                            : Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Categoría',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category['value'],
          child: Text(category['label']!),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
        ),
        child: Text(
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildSummaryRow('Tipo', _getTypeDisplay()),
            _buildSummaryRow('Categoría', _getCategoryLabel()),
            _buildSummaryRow(
              'Fecha',
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
            _buildSummaryRow(
              'Monto',
              _amountController.text.isEmpty
                  ? '-'
                  : '\$${_amountController.text}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(value, style: const TextStyle(color: AppTheme.textColor)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: AppTheme.textColor,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save),
            SizedBox(width: 8),
            Text('Registrar Transacción', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
