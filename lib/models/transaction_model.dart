class Transaction {
  final String? id;
  final String userId;
  final double amount;
  final String description;
  final String categoryName;
  final DateTime date;
  final String type; // 'gasto' o 'ingreso'
  final String category;
  final bool isFixed; // true = fijo, false = variable
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    this.id,
    required this.userId,
    required this.amount,
    required this.description,
    required this.categoryName,
    required this.date,
    required this.type,
    required this.category,
    required this.isFixed,
    this.createdAt,
    this.updatedAt,
  });

  // En lib/models/transaction_model.dart - actualizar el factory fromMap
  factory Transaction.fromMap(Map<String, dynamic> map) {
    // Manejar tipos legacy que no tienen isFixed
    bool isFixed = false;
    if (map['isFixed'] != null) {
      isFixed = map['isFixed'];
    } else {
      // Si no existe el campo, determinar basado en el type
      final type = map['type'];
      isFixed = type == 'ingreso_fijo' || type == 'gasto_fijo';
    }

    return Transaction(
      id: map['\$id'],
      userId: map['userId'],
      amount: map['amount'].toDouble(),
      description: map['description'],
      categoryName: map['categoryname'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      category: map['category'],
      isFixed: isFixed,
      createdAt: map['\$createdAt'] != null
          ? DateTime.parse(map['\$createdAt'])
          : null,
      updatedAt: map['\$updatedAt'] != null
          ? DateTime.parse(map['\$updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'description': description,
      'categoryname': categoryName,
      'date': date.toIso8601String(),
      'type': type,
      'category': category,
      'isFixed': isFixed, // Nuevo campo
    };
  }
}
