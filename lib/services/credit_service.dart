import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_spy/models/credit_model.dart';
import 'package:green_spy/services/auth_service.dart';

class CreditScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get current user's custom ID
  Future<String> get userId async {
    final customId = await _authService.getCustomUserId();
    return customId ?? 'demo_user';
  }

  // Collection reference
  Future<CollectionReference> get _creditScoresCollection async {
    final uid = _authService.currentUser?.uid ?? 'demo';
    return _firestore.collection('users').doc(uid).collection('creditScores');
  }

  // CREATE - Add new credit score entry
  Future<String> addCreditScore(CreditScoreModel creditScore) async {
    try {
      final collection = await _creditScoresCollection;
      final customUserId = await userId;
      final scoreWithUserId = creditScore.copyWith(userId: customUserId);
      final docRef = await collection.add(scoreWithUserId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add credit score: $e');
    }
  }

  // READ - Get latest credit score
  Stream<CreditScoreModel?> getLatestCreditScore() async* {
    final collection = await _creditScoresCollection;
    yield* collection
        .orderBy('date', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return CreditScoreModel.fromFirestore(snapshot.docs.first);
        });
  }

  // UPDATE - Update credit score
  Future<void> updateCreditScore(CreditScoreModel creditScore) async {
    try {
      final collection = await _creditScoresCollection;
      await collection.doc(creditScore.id).update(creditScore.toMap());
    } catch (e) {
      throw Exception('Failed to update credit score: $e');
    }
  }

  // DELETE - Delete credit score entry
  Future<void> deleteCreditScore(String creditScoreId) async {
    try {
      final collection = await _creditScoresCollection;
      await collection.doc(creditScoreId).delete();
    } catch (e) {
      throw Exception('Failed to delete credit score: $e');
    }
  }

  // ANALYTICS - Calculate score change
  Future<int> getScoreChange() async {
    try {
      final collection = await _creditScoresCollection;
      final snapshot = await collection
          .orderBy('date', descending: true)
          .limit(2)
          .get();

      if (snapshot.docs.length < 2) return 0;

      final latest = CreditScoreModel.fromFirestore(snapshot.docs[0]);
      final previous = CreditScoreModel.fromFirestore(snapshot.docs[1]);

      return latest.score - previous.score;
    } catch (e) {
      return 0;
    }
  }

  // CREATE - Generate default credit score (for new users)
  Future<CreditScoreModel> generateDefaultCreditScore() async {
    final customUserId = await userId;
    return CreditScoreModel(
      id: '',
      score: 650,
      date: DateTime.now(),
      userId: customUserId,
      factors: {
        CreditFactorType.paymentHistory: CreditFactor(
          name: CreditFactorType.paymentHistory,
          percentage: 70,
          status: 'Good',
          description: 'Maintain consistent payment history',
        ),
        CreditFactorType.creditUtilization: CreditFactor(
          name: CreditFactorType.creditUtilization,
          percentage: 45,
          status: 'Fair',
          description: 'Keep utilization below 30%',
        ),
        CreditFactorType.creditAge: CreditFactor(
          name: CreditFactorType.creditAge,
          percentage: 60,
          status: 'Good',
          description: 'Good average account age',
        ),
        CreditFactorType.creditMix: CreditFactor(
          name: CreditFactorType.creditMix,
          percentage: 50,
          status: 'Fair',
          description: 'Consider diversifying credit types',
        ),
        CreditFactorType.newCredit: CreditFactor(
          name: CreditFactorType.newCredit,
          percentage: 80,
          status: 'Excellent',
          description: 'Good management of new accounts',
        ),
      },
    );
  }

  // UTILITY - Get improvement suggestions
  List<String> getImprovementSuggestions(CreditScoreModel creditScore) {
    List<String> suggestions = [];

    creditScore.factors.forEach((key, factor) {
      if (factor.percentage < 70) {
        switch (key) {
          case CreditFactorType.paymentHistory:
            suggestions.add(
              '💳 Set up automatic payments to avoid missing due dates',
            );
            break;
          case CreditFactorType.creditUtilization:
            suggestions.add(
              '📊 Reduce credit card balances to below 30% of limits',
            );
            break;
          case CreditFactorType.creditAge:
            suggestions.add(
              '⏰ Keep older accounts open to improve average age',
            );
            break;
          case CreditFactorType.creditMix:
            suggestions.add(
              '🎯 Consider adding different types of credit accounts',
            );
            break;
          case CreditFactorType.newCredit:
            suggestions.add(
              '⚠️ Limit new credit applications to reduce inquiries',
            );
            break;
        }
      }
    });

    if (suggestions.isEmpty) {
      suggestions.add('🌟 Excellent credit management! Keep up the good work');
    }

    return suggestions;
  }
}
