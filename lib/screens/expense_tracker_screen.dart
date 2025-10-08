import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_spy/constants/app_colors.dart';
import 'package:green_spy/models/expense_model.dart';
import 'package:green_spy/services/expense_service.dart';
import 'package:green_spy/widgets/chart_widgets.dart';
import 'package:green_spy/widgets/expense_dialog.dart';
import 'package:green_spy/widgets/expense_widgets.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() =>
      _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState
    extends State<ExpenseTrackerScreen> {
  final ExpenseService _expenseService = ExpenseService();
  String _selectedPeriod = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.primaryGreen,
        ),
        title: Text(
          'Expense Tracker',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          PeriodSelector(
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (period) {
              setState(() => _selectedPeriod = period);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<ExpenseModel>>(
          stream: _getFilteredExpenses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: GoogleFonts.inter(color: AppColors.errorRed),
                ),
              );
            }

            final expenses = snapshot.data ?? [];
            return _buildContent(expenses);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExpenseDialog(),
        backgroundColor: AppColors.primaryGreen,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Expense',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Stream<List<ExpenseModel>> _getFilteredExpenses() {
    final dates = ExpenseService.getPeriodDates(_selectedPeriod);
    return _expenseService.getExpensesByDateRange(
      dates['start']!,
      dates['end']!,
    );
  }

  Widget _buildContent(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return _buildEmptyState();
    }

    final financialData = _calculateFinancialData(expenses);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          BalanceCard(
            balance: financialData['balance']!,
            percentageChange: 12.5,
          ),
          const SizedBox(height: 20),

          // Quick Stats
          QuickStatsRow(
            income: financialData['income']!,
            expenses: financialData['expense']!,
          ),
          const SizedBox(height: 20),

          // AI Analysis
          FutureBuilder<String>(
            future: _generateAIAnalysis(expenses),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    AIAnalysisCard(
                      analysis: snapshot.data!,
                      period: _selectedPeriod,
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Charts
          ExpensePieChart(
            categoryData: _getCategoryBreakdown(expenses),
          ),
          const SizedBox(height: 20),

          ExpenseBarChart(
            dailyExpenses: _getDailyExpenses(expenses),
          ),
          const SizedBox(height: 20),

          // Recent Transactions
          SectionHeader(
            title: 'Recent Transactions',
            actionText: 'See All',
            onActionPressed: () {},
          ),
          const SizedBox(height: 15),

          ...expenses.take(10).map((expense) => Column(
                children: [
                  TransactionItem(
                    icon: _getCategoryIcon(expense.category),
                    title: expense.title,
                    date: _formatDate(expense.date),
                    amount: expense.isIncome ? expense.amount : -expense.amount,
                    color: _getCategoryColor(expense.category),
                    category: expense.category,
                    onTap: () => _showExpenseDialog(expense: expense),
                    onDelete: () => _deleteExpense(expense.id),
                  ),
                  const SizedBox(height: 12),
                ],
              )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 80,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 20),
          Text(
            'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first transaction to get started',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateFinancialData(List<ExpenseModel> expenses) {
    double income = 0;
    double expense = 0;

    for (var item in expenses) {
      if (item.isIncome) {
        income += item.amount;
      } else {
        expense += item.amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Map<String, double> _getCategoryBreakdown(List<ExpenseModel> expenses) {
    Map<String, double> breakdown = {};

    for (var expense in expenses) {
      if (!expense.isIncome) {
        breakdown[expense.category] =
            (breakdown[expense.category] ?? 0) + expense.amount;
      }
    }

    return breakdown;
  }

  Map<DateTime, double> _getDailyExpenses(List<ExpenseModel> expenses) {
    Map<DateTime, double> dailyTotals = {};

    for (var expense in expenses) {
      if (!expense.isIncome) {
        final date = DateTime(
          expense.date.year,
          expense.date.month,
          expense.date.day,
        );
        dailyTotals[date] = (dailyTotals[date] ?? 0) + expense.amount;
      }
    }

    return Map.fromEntries(
      dailyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  Future<String> _generateAIAnalysis(List<ExpenseModel> expenses) async {
    final financialData = _calculateFinancialData(expenses);
    final categoryBreakdown = _getCategoryBreakdown(expenses);

    return _expenseService.generateSarcasticAnalysis(
      financialData['expense']!,
      financialData['income']!,
      categoryBreakdown,
      _selectedPeriod,
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_rounded;
      case ExpenseCategory.transport:
        return Icons.directions_car_rounded;
      case ExpenseCategory.bills:
        return Icons.receipt_long_rounded;
      case ExpenseCategory.entertainment:
        return Icons.movie_rounded;
      case ExpenseCategory.health:
        return Icons.local_hospital_rounded;
      case ExpenseCategory.salary:
        return Icons.trending_up_rounded;
      case ExpenseCategory.investment:
        return Icons.show_chart_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    final categoryData = ExpenseCategory.getCategoryData(category);
    return Color(categoryData['color']);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    final diff = today.difference(dateOnly).inDays;
    if (diff < 7) return '$diff days ago';

    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _showExpenseDialog({ExpenseModel? expense}) async {
    final result = await showDialog<ExpenseModel>(
      context: context,
      builder: (context) => ExpenseDialog(expense: expense),
    );

    if (result != null) {
      try {
        if (expense == null) {
          await _expenseService.addExpense(result);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Transaction added successfully',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
        } else {
          await _expenseService.updateExpense(
            result.copyWith(id: expense.id),
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Transaction updated successfully',
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: ${e.toString()}',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      await _expenseService.deleteExpense(expenseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transaction deleted',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error deleting transaction',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }
}