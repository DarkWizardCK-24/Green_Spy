// lib/screens/all_transactions_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:green_spy/constants/app_colors.dart';
import 'package:green_spy/models/expense_model.dart';
import 'package:green_spy/services/expense_service.dart';
import 'package:green_spy/widgets/transaction_widgets.dart';
import 'package:green_spy/widgets/expense_dialog.dart';
import 'package:table_calendar/table_calendar.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final ScrollController _scrollController = ScrollController();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showCalendar = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
          _selectedDay != null
              ? 'Transactions - ${_formatSelectedDate(_selectedDay!)}'
              : 'All Transactions',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          // Calendar Toggle Button
          IconButton(
            onPressed: () {
              setState(() {
                _showCalendar = !_showCalendar;
              });
            },
            icon: Icon(
              _showCalendar
                  ? Icons.calendar_today
                  : Icons.calendar_month_rounded,
            ),
            color: AppColors.primaryGreen,
          ),
          // Clear Date Filter
          if (_selectedDay != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedDay = null;
                });
              },
              icon: const Icon(Icons.clear_rounded),
              color: AppColors.errorRed,
            ),
          IconButton(
            onPressed: () => _showFilterDialog(),
            icon: const Icon(Icons.filter_list_rounded),
            color: AppColors.primaryGreen,
          ),
          IconButton(
            onPressed: () => _showSearchDialog(),
            icon: const Icon(Icons.search_rounded),
            color: AppColors.primaryGreen,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar Widget
          if (_showCalendar)
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  // Today
                  todayDecoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  // Selected Day
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  // Default days
                  defaultTextStyle: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                  ),
                  weekendTextStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                  ),
                  outsideTextStyle: GoogleFonts.inter(
                    color: AppColors.textMuted,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: GoogleFonts.inter(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  titleTextStyle: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left,
                    color: AppColors.primaryGreen,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryGreen,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Transactions List
          Expanded(
            child: StreamBuilder<List<ExpenseModel>>(
              stream: _selectedDay != null
                  ? _expenseService.getExpensesByDate(_selectedDay!)
                  : _expenseService.getAllExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryGreen,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final expenses = snapshot.data ?? [];

                if (expenses.isEmpty) {
                  return _buildEmptyState();
                }

                // Group transactions by date/month
                final groupedTransactions = _groupTransactionsByDate(expenses);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: groupedTransactions.length,
                  itemBuilder: (context, index) {
                    final group = groupedTransactions[index];
                    return TransactionDateGroup(
                      dateLabel: group['label'] as String,
                      totalAmount: group['total'] as double,
                      transactions: group['transactions'] as List<ExpenseModel>,
                      onTransactionTap: (expense) =>
                          _showExpenseDialog(expense),
                      onTransactionDelete: (expenseId) =>
                          _deleteExpense(expenseId),
                      getCategoryIcon: _getCategoryIcon,
                      getCategoryColor: _getCategoryColor,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _groupTransactionsByDate(
    List<ExpenseModel> expenses,
  ) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    Map<String, List<ExpenseModel>> grouped = {};
    Map<String, double> totals = {};

    for (var expense in expenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );

      String key;
      String label;

      // If filtering by selected day, show only that day
      if (_selectedDay != null) {
        key = '${expense.date.year}-${expense.date.month}-${expense.date.day}';
        label = _formatSelectedDate(_selectedDay!);
      }
      // If expense is in current month, group by date
      else if (expense.date.year == now.year &&
          expense.date.month == now.month) {
        key = '${expense.date.year}-${expense.date.month}-${expense.date.day}';
        label = _formatCurrentMonthDate(expense.date, now);
      } else {
        // For past months, group by month
        key = '${expense.date.year}-${expense.date.month}';
        label = _formatPastMonthDate(expense.date);
      }

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
        totals[key] = 0;
      }

      grouped[key]!.add(expense);
      totals[key] =
          totals[key]! + (expense.isIncome ? expense.amount : -expense.amount);
    }

    // Convert to list and sort
    final result = grouped.entries.map((entry) {
      return {
        'key': entry.key,
        'label':
            entry.value.first.date.year == now.year &&
                entry.value.first.date.month == now.month &&
                _selectedDay == null
            ? _formatCurrentMonthDate(entry.value.first.date, now)
            : _selectedDay != null
            ? _formatSelectedDate(_selectedDay!)
            : _formatPastMonthDate(entry.value.first.date),
        'total': totals[entry.key]!,
        'transactions': entry.value,
      };
    }).toList();

    // Sort by date (newest first)
    result.sort((a, b) {
      final dateA = (a['transactions'] as List<ExpenseModel>).first.date;
      final dateB = (b['transactions'] as List<ExpenseModel>).first.date;
      return dateB.compareTo(dateA);
    });

    return result;
  }

  String _formatSelectedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatCurrentMonthDate(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    final diff = today.difference(dateOnly).inDays;
    if (diff < 7) {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[date.weekday - 1];
    }

    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _formatPastMonthDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
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
            _selectedDay != null
                ? 'No transactions on this date'
                : 'No transactions yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDay != null
                ? 'Try selecting a different date'
                : 'Your transaction history will appear here',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: AppColors.errorRed,
          ),
          const SizedBox(height: 20),
          Text(
            'Something went wrong',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  void _showFilterDialog() {
    // TODO: Implement filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filter feature coming soon!',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _showSearchDialog() {
    // TODO: Implement search dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Search feature coming soon!',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _showExpenseDialog(ExpenseModel expense) async {
    final result = await showDialog<ExpenseModel>(
      context: context,
      builder: (context) => ExpenseDialog(expense: expense),
    );

    if (result != null) {
      try {
        await _expenseService.updateExpense(result.copyWith(id: expense.id));
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
            content: Text('Transaction deleted', style: GoogleFonts.inter()),
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
