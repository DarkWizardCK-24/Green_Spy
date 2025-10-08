import 'package:cloud_firestore/cloud_firestore.dart';

class CreditScoreModel {
  final String id;
  final int score;
  final DateTime date;
  final String userId;
  final Map<String, CreditFactor> factors;

  CreditScoreModel({
    required this.id,
    required this.score,
    required this.date,
    required this.userId,
    required this.factors,
  });

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'factors': factors.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  factory CreditScoreModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CreditScoreModel(
      id: doc.id,
      score: data['score'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      factors: (data['factors'] as Map<String, dynamic>? ?? {}).map(
        (key, value) =>
            MapEntry(key, CreditFactor.fromMap(value as Map<String, dynamic>)),
      ),
    );
  }

  String getScoreLabel() {
    if (score >= 750) return 'Excellent';
    if (score >= 700) return 'Good';
    if (score >= 650) return 'Fair';
    return 'Poor';
  }

  CreditScoreModel copyWith({
    String? id,
    int? score,
    DateTime? date,
    String? userId,
    Map<String, CreditFactor>? factors,
  }) {
    return CreditScoreModel(
      id: id ?? this.id,
      score: score ?? this.score,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      factors: factors ?? this.factors,
    );
  }
}

class CreditFactor {
  final String name;
  final int percentage;
  final String status;
  final String description;

  CreditFactor({
    required this.name,
    required this.percentage,
    required this.status,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'percentage': percentage,
      'status': status,
      'description': description,
    };
  }

  factory CreditFactor.fromMap(Map<String, dynamic> map) {
    return CreditFactor(
      name: map['name'] ?? '',
      percentage: map['percentage'] ?? 0,
      status: map['status'] ?? '',
      description: map['description'] ?? '',
    );
  }

  CreditFactor copyWith({
    String? name,
    int? percentage,
    String? status,
    String? description,
  }) {
    return CreditFactor(
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }
}

class CreditFactorType {
  static const String paymentHistory = 'Payment History';
  static const String creditUtilization = 'Credit Utilization';
  static const String creditAge = 'Credit Age';
  static const String creditMix = 'Credit Mix';
  static const String newCredit = 'New Credit';

  static List<String> get all => [
    paymentHistory,
    creditUtilization,
    creditAge,
    creditMix,
    newCredit,
  ];

  static Map<String, dynamic> getFactorData(String factor) {
    switch (factor) {
      case paymentHistory:
        return {
          'icon': 'payment_rounded',
          'weight': 35,
          'description': 'Your history of on-time payments',
        };
      case creditUtilization:
        return {
          'icon': 'credit_card_rounded',
          'weight': 30,
          'description': 'Percentage of credit used',
        };
      case creditAge:
        return {
          'icon': 'history_rounded',
          'weight': 15,
          'description': 'Average age of your accounts',
        };
      case creditMix:
        return {
          'icon': 'account_balance_rounded',
          'weight': 10,
          'description': 'Variety of credit types',
        };
      case newCredit:
        return {
          'icon': 'new_releases_rounded',
          'weight': 10,
          'description': 'Recently opened accounts',
        };
      default:
        return {'icon': 'info_rounded', 'weight': 0, 'description': ''};
    }
  }
}
