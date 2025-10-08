import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:green_spy/models/expense_model.dart';
import 'package:green_spy/services/auth_service.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get current user's custom ID
  Future<String> get userId async {
    final customId = await _authService.getCustomUserId();
    return customId ?? 'demo_user';
  }

  // Collection reference
  Future<CollectionReference> get _expensesCollection async {
    final uid = _authService.currentUser?.uid ?? 'demo';
    return _firestore.collection('users').doc(uid).collection('expenses');
  }

  // CREATE - Add new expense
  Future<String> addExpense(ExpenseModel expense) async {
    try {
      final collection = await _expensesCollection;
      final customUserId = await userId;
      final expenseWithUserId = expense.copyWith(userId: customUserId);
      final docRef = await collection.add(expenseWithUserId.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  // READ - Get all expenses
  Stream<List<ExpenseModel>> getExpenses() async* {
    final collection = await _expensesCollection;
    yield* collection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // READ - Get expenses by date range
  Stream<List<ExpenseModel>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async* {
    final collection = await _expensesCollection;
    yield* collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromFirestore(doc))
              .toList(),
        );
  }

  // UPDATE - Update existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      final collection = await _expensesCollection;
      await collection.doc(expense.id).update(expense.toMap());
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  // DELETE - Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      final collection = await _expensesCollection;
      await collection.doc(expenseId).delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // AI ANALYSIS - Generate sarcastic commentary (same as before)
  String generateSarcasticAnalysis(
    double totalExpense,
    double totalIncome,
    Map<String, double> categoryBreakdown,
    String period,
  ) {
    final balance = totalIncome - totalExpense;

    if (categoryBreakdown.isEmpty) {
      return "No expenses to analyze yet. Either you're incredibly frugal or you forgot to log anything! 😴";
    }

    final topCategory = categoryBreakdown.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    List<String> sarcasticComments = [
      // Negative balance
      if (balance < 0)
        "Wow, spending ₹${totalExpense.toStringAsFixed(2)} while only earning ₹${totalIncome.toStringAsFixed(2)}? That's a bold financial strategy! Who needs savings anyway? 💸"
      else if (balance < 100)
        "Congratulations! You've managed to save a whopping ₹${balance.toStringAsFixed(2)} this $period. At this rate, you'll afford that yacht in... never. 🎉",

      // High spending categories
      if (topCategory.key == ExpenseCategory.food && topCategory.value > 500)
        "Spent ₹${topCategory.value.toStringAsFixed(2)} on food? I see you're auditioning for a cooking show. Or maybe just really love your digestive system. 🍔"
      else if (topCategory.key == ExpenseCategory.shopping &&
          topCategory.value > 1000)
        "A mere ₹${topCategory.value.toStringAsFixed(2)} on shopping? Clearly, you're showing incredible restraint... said no one ever. 🛍️"
      else if (topCategory.key == ExpenseCategory.entertainment &&
          topCategory.value > 300)
        "Entertainment expenses of ₹${topCategory.value.toStringAsFixed(2)}? Well, at least you're having fun going broke! 🎮",

      // Good balance
      if (balance > 500)
        "Actually impressive! Saved ₹${balance.toStringAsFixed(2)} this $period. Are you feeling okay? This level of financial responsibility is concerning. 💪"
      else if (balance > 1000)
        "Holy budgeting, Batman! ₹${balance.toStringAsFixed(2)} saved? Someone's been eating ramen and crying into their pillow at night. Worth it? 🌟",

      // Multiple categories
      if (categoryBreakdown.length > 5)
        "Diversifying your spending across ${categoryBreakdown.length} categories? That's not financial planning, that's just being everywhere at once! 🎭"
      else if (categoryBreakdown.length == 1)
        "All expenses in one category? That's either laser-focused budgeting or a complete lack of life variety. I'm betting on the latter. 🎯",

      // Income vs expense ratio
      if (totalExpense > totalIncome * 1.5)
        "Spending 150% of your income? That's not living beyond your means, that's living in a parallel financial universe! 🚀"
      else if (totalExpense < totalIncome * 0.3)
        "Using only 30% of your income? Either you're incredibly disciplined or you forgot to log half your expenses. Probably the latter. 📝",
    ];

    // Pick random comments based on conditions
    final applicableComments = sarcasticComments
        .where((c) => c.isNotEmpty)
        .toList();

    if (applicableComments.isEmpty) {
      return "Your spending this $period was so unremarkable, even I have nothing sarcastic to say. And that's saying something! 😴";
    }

    // Return 1-2 random comments
    applicableComments.shuffle();
    return applicableComments.take(2).join('\n\n');
  }

  // Get period dates
  static Map<String, DateTime> getPeriodDates(String period) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (period.toLowerCase()) {
      case 'daily':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'weekly':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'monthly':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return {'start': startDate, 'end': endDate};
  }
}
