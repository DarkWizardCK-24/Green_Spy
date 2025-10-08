import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final bool isIncome;
  final String? notes;
  final String userId;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.isIncome,
    this.notes,
    required this.userId,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'isIncome': isIncome,
      'notes': notes,
      'userId': userId,
    };
  }

  // Create from Firestore document
  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Other',
      date: (data['date'] as Timestamp).toDate(),
      isIncome: data['isIncome'] ?? false,
      notes: data['notes'],
      userId: data['userId'] ?? '',
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    bool? isIncome,
    String? notes,
    String? userId,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
    );
  }
}

class ExpenseCategory {
  static const String food = 'Food & Dining';
  static const String shopping = 'Shopping';
  static const String transport = 'Transport';
  static const String bills = 'Bills';
  static const String entertainment = 'Entertainment';
  static const String health = 'Health';
  static const String salary = 'Salary';
  static const String investment = 'Investment';
  static const String other = 'Other';

  static List<String> get all => [
    food,
    shopping,
    transport,
    bills,
    entertainment,
    health,
    salary,
    investment,
    other,
  ];

  static Map<String, dynamic> getCategoryData(String category) {
    switch (category) {
      case food:
        return {'icon': '🍕', 'color': 0xFFFFA502};
      case shopping:
        return {'icon': '🛍️', 'color': 0xFFFF4757};
      case transport:
        return {'icon': '🚗', 'color': 0xFF3742FA};
      case bills:
        return {'icon': '💡', 'color': 0xFF5352ED};
      case entertainment:
        return {'icon': '🎮', 'color': 0xFFFF6348};
      case health:
        return {'icon': '💊', 'color': 0xFF2ED573};
      case salary:
        return {'icon': '💰', 'color': 0xFF00FF88};
      case investment:
        return {'icon': '📈', 'color': 0xFF00D2FF};
      default:
        return {'icon': '📦', 'color': 0xFF747D8C};
    }
  }
}
