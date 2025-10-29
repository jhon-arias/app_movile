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

  // NUEVA FUNCIÓN PARA DATOS SEPARADOS POR TIPO
  Map<String, List<ChartData>> _getMonthlyTrendByTypeData() {
    final Map<String, double> monthlyExpenses = {};
    final Map<String, double> monthlyIncomes = {};

    for (final transaction in _transactions) {
      final monthKey =
          '${_getMonthName(transaction.date.month)} ${transaction.date.year}';

      if (transaction.type.contains('gasto')) {
        monthlyExpenses[monthKey] =
            (monthlyExpenses[monthKey] ?? 0) + transaction.amount;
      } else if (transaction.type.contains('ingreso')) {
        monthlyIncomes[monthKey] =
            (monthlyIncomes[monthKey] ?? 0) + transaction.amount;
      }
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

    // Obtener todos los meses únicos
    final allMonths =
        <String>{...monthlyExpenses.keys, ...monthlyIncomes.keys}.toList()
          ..sort((a, b) {
            final aParts = a.split(' ');
            final bParts = b.split(' ');
            final aMonth = aParts[0];
            final bMonth = bParts[0];
            final aYear = int.parse(aParts[1]);
            final bYear = int.parse(bParts[1]);

            if (aYear != bYear) return aYear.compareTo(bYear);
            return (monthOrder[aMonth] ?? 0).compareTo(monthOrder[bMonth] ?? 0);
          });

    // Crear datos para gastos
    final expensesData = allMonths
        .map(
          (month) => ChartData(
            month,
            monthlyExpenses[month] ?? 0,
            const Color(0xFFEF5350),
          ), // Rojo suave
        )
        .toList();

    // Crear datos para ingresos
    final incomesData = allMonths
        .map(
          (month) => ChartData(
            month,
            monthlyIncomes[month] ?? 0,
            const Color(0xFF66BB6A),
          ), // Verde suave
        )
        .toList();

    return {'gastos': expensesData, 'ingresos': incomesData};
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
    // Degradado de plomo a azul a celeste claro (tonos suaves)
    final grayToBlueGradient = [
      const Color(0xFF90A4AE), // Plomo suave
      const Color(0xFFA1B5BE), // Plomo azulado claro
      const Color(0xFFB0BEC5), // Gris azul muy suave
      const Color(0xFF9FA8DA), // Lavanda azul
      const Color(0xFF90CAF9), // Azul claro suave
      const Color(0xFF81C7E8), // Azul medio suave
      const Color(0xFF79C2E0), // Azul celeste suave
      const Color(0xFF81D4FA), // Celeste claro
      const Color(0xFF9BE7FF), // Celeste muy claro
      const Color(0xFFB3E5FC), // Celeste pastel
      const Color(0xFFC8F7FF), // Celeste muy pastel
      const Color(0xFFE1F5FE), // Celeste ultra claro
    ];

    // Usar hash para asignar colores consistentemente
    final index = category.hashCode.abs() % grayToBlueGradient.length;
    return grayToBlueGradient[index];
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Gastos Fijos':
        return const Color(0xFFEF5350); // Rojo suave
      case 'Gastos Variables':
        return const Color(0xFFFF8A65); // Naranja suave
      case 'Ingresos Fijos':
        return const Color(0xFF66BB6A); // Verde suave
      case 'Ingresos Variables':
        return const Color(0xFF42A5F5); // Azul suave
      default:
        return const Color(0xFFBDBDBD); // Gris suave
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
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.curve,
                        length: '10%',
                      ),
                    ),
                    dataLabelMapper: (ChartData data, _) =>
                        '${data.x}\n\$${NumberFormat.compact().format(data.y)}',
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
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.curve,
                        length: '10%',
                      ),
                    ),
                    dataLabelMapper: (ChartData data, _) =>
                        '${data.x}\n\$${NumberFormat.compact().format(data.y)}',
                    innerRadius: '40%',
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
    final data = _getMonthlyTrendByTypeData();
    if (data['gastos']!.isEmpty && data['ingresos']!.isEmpty) {
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
                primaryXAxis: CategoryAxis(
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                primaryYAxis: NumericAxis(
                  numberFormat: NumberFormat.compact(),
                  labelStyle: const TextStyle(fontSize: 10),
                ),
                legend: const Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: TextStyle(fontSize: 11),
                ),
                series: <CartesianSeries>[
                  // Barras de gastos
                  ColumnSeries<ChartData, String>(
                    name: 'Gastos',
                    dataSource: data['gastos']!,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    color: const Color(0xFFEF5350), // Rojo suave
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      textStyle: TextStyle(
                        fontSize: 8,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    dataLabelMapper: (ChartData data, _) => data.y > 0
                        ? '\$${NumberFormat.compact().format(data.y)}'
                        : '',
                  ),
                  // Barras de ingresos
                  ColumnSeries<ChartData, String>(
                    name: 'Ingresos',
                    dataSource: data['ingresos']!,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    color: const Color(0xFF66BB6A), // Verde suave
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                      textStyle: TextStyle(
                        fontSize: 8,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    dataLabelMapper: (ChartData data, _) => data.y > 0
                        ? '\$${NumberFormat.compact().format(data.y)}'
                        : '',
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
