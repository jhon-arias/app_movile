import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:gastos_app/models/transaction_model.dart';
import 'package:gastos_app/services/appwrite_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final AppWriteService _appWriteService = AppWriteService();
  List<Transaction> _transactions = [];
  String? _currentUserId;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedChartIndex = 0;

  final List<String> _chartTypes = [
    'Gastos por Categoría',
    'Distribución General',
    'Evolución Mensual',
  ];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final user = await _appWriteService.getCurrentUser();
      if (user != null && mounted) {
        setState(() => _currentUserId = user.$id);
        await _loadTransactions();
      } else {
        _setError('No se pudo obtener el usuario actual');
      }
    } catch (e) {
      _setError('Error al obtener usuario: $e');
    }
  }

  Future<void> _loadTransactions() async {
    if (_currentUserId == null) {
      _setError('Usuario no identificado');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final transactions = await _appWriteService.getTransactionsByDateRange(
        _currentUserId!,
        _startDate,
        _endDate,
      );

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      _setError('Error al cargar transacciones: $e');
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = message;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _startDate) {
      setState(() => _startDate = picked);
      await _loadTransactions();
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _endDate) {
      setState(() => _endDate = picked);
      await _loadTransactions();
    }
  }

  // DATOS PARA GRÁFICOS - EVITAR CÁLCULOS EN build()
  List<ChartData> _getCategoryExpensesData() {
    final Map<String, double> categoryTotals = {};

    for (final transaction in _transactions) {
      if (transaction.type.contains('gasto')) {
        categoryTotals[transaction.categoryName] =
            (categoryTotals[transaction.categoryName] ?? 0) +
            transaction.amount;
      }
    }

    final data = categoryTotals.entries
        .map(
          (entry) =>
              ChartData(entry.key, entry.value, _getCategoryColor(entry.key)),
        )
        .toList();

    return data;
  }

  List<ChartData> _getTypeDistributionData() {
    final Map<String, double> typeTotals = {};

    for (final transaction in _transactions) {
      final typeLabel = _getTypeDisplay(transaction.type);
      typeTotals[typeLabel] = (typeTotals[typeLabel] ?? 0) + transaction.amount;
    }

    return typeTotals.entries
        .map(
          (entry) =>
              ChartData(entry.key, entry.value, _getTypeColor(entry.key)),
        )
        .toList();
  }

  List<ChartData> _getMonthlyTrendData() {
    final Map<String, double> monthlyTotals = {};

    for (final transaction in _transactions) {
      final monthKey =
          '${_getMonthName(transaction.date.month)} ${transaction.date.year}';
      monthlyTotals[monthKey] =
          (monthlyTotals[monthKey] ?? 0) + transaction.amount;
    }

    final monthOrder = {
      'Ene': 1,
      'Feb': 2,
      'Mar': 3,
      'Abr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Ago': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dic': 12,
    };

    final sortedEntries = monthlyTotals.entries.toList()
      ..sort((a, b) {
        final aParts = a.key.split(' ');
        final bParts = b.key.split(' ');
        final aMonth = aParts[0];
        final bMonth = bParts[0];
        final aYear = int.parse(aParts[1]);
        final bYear = int.parse(bParts[1]);

        if (aYear != bYear) return aYear.compareTo(bYear);
        return (monthOrder[aMonth] ?? 0).compareTo(monthOrder[bMonth] ?? 0);
      });

    return sortedEntries
        .map((entry) => ChartData(entry.key, entry.value, Colors.blue))
        .toList();
  }

  String _getMonthName(int month) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return months[month - 1];
  }

  // CÁLCULOS DE RESUMEN
  double get _totalIncome {
    return _transactions
        .where((t) => t.type.contains('ingreso'))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _totalExpenses {
    return _transactions
        .where((t) => t.type.contains('gasto'))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get _balance => _totalIncome - _totalExpenses;

  // COLORES PARA CATEGORÍAS
  Color _getCategoryColor(String category) {
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFF2196F3),
      Color(0xFFFF9800),
      Color(0xFFF44336),
      Color(0xFF9C27B0),
      Color(0xFF607D8B),
      Color(0xFFFFC107),
      Color(0xFF795548),
      Color(0xFF00BCD4),
      Color(0xFFE91E63),
    ];

    // Usar hash para evitar dependencia de datos calculados
    final index = category.hashCode.abs() % colors.length;
    return colors[index];
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Gastos Fijos':
        return Colors.red;
      case 'Gastos Variables':
        return Colors.orange;
      case 'Ingresos Fijos':
        return Colors.green;
      case 'Ingresos Variables':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getTypeDisplay(String type) {
    switch (type) {
      case 'gasto_fijo':
        return 'Gastos Fijos';
      case 'gasto_variable':
        return 'Gastos Variables';
      case 'ingreso_fijo':
        return 'Ingresos Fijos';
      case 'ingreso_variable':
        return 'Ingresos Variables';
      default:
        return 'Otros';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoading();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildError();
    }

    return _buildContent();
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando estadísticas...'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF90EE90),
                foregroundColor: Colors.black,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildDateFilters(),
        const SizedBox(height: 16),
        _buildSummaryCards(),
        const SizedBox(height: 16),
        _buildChartSelector(),
        const SizedBox(height: 16),
        Expanded(child: _buildSelectedChart()),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Filtrar por Fecha',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    'Desde: ${_formatDate(_startDate)}',
                    () => _selectStartDate(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    'Hasta: ${_formatDate(_endDate)}',
                    () => _selectEndDate(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_transactions.length} transacciones encontradas',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildSummaryCard(
            'Ingresos',
            _totalIncome,
            Colors.green,
            Icons.arrow_downward,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Gastos',
            _totalExpenses,
            Colors.red,
            Icons.arrow_upward,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Balance',
            _balance,
            _balance >= 0 ? Colors.green : Colors.red,
            Icons.balance,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return SizedBox(
      width: 120,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '\$${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(_chartTypes.length, (index) {
          return ChoiceChip(
            label: Text(
              _chartTypes[index],
              style: TextStyle(
                color: _selectedChartIndex == index
                    ? Colors.black
                    : Colors.black87,
              ),
            ),
            selected: _selectedChartIndex == index,
            onSelected: (selected) {
              setState(() => _selectedChartIndex = index);
            },
            selectedColor: const Color(0xFF90EE90),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedChart() {
    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildChartByIndex(_selectedChartIndex),
    );
  }

  Widget _buildChartByIndex(int index) {
    switch (index) {
      case 0:
        return _buildCategoryChart();
      case 1:
        return _buildDistributionChart();
      case 2:
        return _buildTrendChart();
      default:
        return _buildCategoryChart();
    }
  }

  Widget _buildCategoryChart() {
    final data = _getCategoryExpensesData();
    if (data.isEmpty) {
      return _buildNoDataMessage('No hay datos de gastos para mostrar');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Gastos por Categoría',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
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

  Widget _buildDistributionChart() {
    final data = _getTypeDistributionData();
    if (data.isEmpty) {
      return _buildNoDataMessage('No hay datos para mostrar');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Distribución General',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SfCircularChart(
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                ),
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    final data = _getMonthlyTrendData();
    if (data.isEmpty) {
      return _buildNoDataMessage('No hay datos de tendencia para mostrar');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Evolución Mensual',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(numberFormat: _currencyFormat),
                series: <CartesianSeries>[
                  LineSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
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
          Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No hay transacciones en el período seleccionado',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ChartData {
  final String x;
  final double y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}
