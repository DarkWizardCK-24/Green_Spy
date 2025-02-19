import 'package:flutter/material.dart';
import 'package:green_spy/expense_model.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Expense> _expenses = [];
  double _budget = 5000;

  void _addExpense(String title, double amount, String category) {
    final expense = Expense(
        title: title, amount: amount, date: DateTime.now(), category: category);
    setState(() {
      _expenses.add(expense);
    });
  }

  void _deleteExpense(String id) {
    setState(() {
      _expenses.removeWhere((expense) => expense.id == id);
    });
  }

  double get _totalBalance {
    return _budget - _totalExpenses;
  }

  double get _totalExpenses {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  void _showBudgetDialog() {
    final budgetController = TextEditingController(text: _budget.toString());

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Update Budget"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: budgetController,
                  decoration: InputDecoration(
                    labelText: "Budget Amount",
                    prefixText: "\$",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(),
                ),
                SizedBox(
                  height: 8,
                ),
                Text(
                  "Current Budget: \$${_budget.toStringAsFixed(2)}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (budgetController.text.isNotEmpty) {
                    setState(() {
                      _budget = double.parse(budgetController.text);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Budget updated successfully"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text("Update"),
              ),
            ],
          );
        });
  }

  void _showAddExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    String selectedCategory = "Shopping";

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Add New Expense"),
                SizedBox(
                  height: 16,
                ),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: "Amount",
                    prefixText: "\$",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(),
                ),
                SizedBox(
                  height: 16,
                ),
                DropdownButton(
                    value: selectedCategory,
                    items: [
                      "Shopping",
                      "Food & Drinks",
                      "Transportation",
                      "Bills",
                      "Other"
                    ]
                        .map((category) => DropdownMenuItem(
                            value: category, child: Text(category)))
                        .toList(),
                    onChanged: (value) {
                      selectedCategory = value!;
                    }),
                SizedBox(
                  height: 16,
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        amountController.text.isNotEmpty) {
                      _addExpense(
                          titleController.text,
                          double.parse(amountController.text),
                          selectedCategory);
                      Navigator.pop(context);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text("Add Expense"),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    double spentPercentage = (_totalExpenses / _budget).clamp(0.0, 1.0);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(15),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(255, 29, 24, 105),
                    const Color.fromARGB(255, 14, 83, 153),
                    const Color.fromARGB(255, 29, 24, 105),
                    const Color.fromARGB(255, 14, 83, 153),
                    const Color.fromARGB(255, 29, 24, 105),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Balance",
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      IconButton(
                          onPressed: _showBudgetDialog,
                          icon: Icon(
                            Icons.edit,
                            color: Colors.white70,
                          )),
                    ],
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Text(
                    "\$${_totalBalance.toStringAsFixed(2)}",
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Budget: \$${_budget.toStringAsFixed(2)}",
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            "${(spentPercentage * 100).toStringAsFixed(1)}% Spent",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: spentPercentage,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            spentPercentage > 0.9
                                ? Colors.redAccent
                                : spentPercentage > 0.7
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.green,
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          Text(
                            "Budget:",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            "\$${_totalBalance.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.red,
                          ),
                          SizedBox(
                            width: 2,
                          ),
                          Text(
                            "Expense:",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            "\$${_totalExpenses.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Row(
                children: [
                  Text(
                    "Recent Transactions",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                          ),
                          SizedBox(
                            height: 12,
                          ),
                          Text(
                            "No Expenses Yet",
                            style: TextStyle(fontSize: 18),
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[_expenses.length - 1 - index];
                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (direction) {
                            _deleteExpense(expense.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Expense deleted successfully"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Card(
                            color: Colors.grey.shade800,
                            elevation: 0.5,
                            margin: EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                    color: const Color.fromARGB(
                                        255, 219, 195, 195),
                                    expense.category == "Shopping"
                                        ? Icons.shopping_bag
                                        : expense.category == "Food & Drinks"
                                            ? Icons.fastfood
                                            : expense.category ==
                                                    "Transportation"
                                                ? Icons.directions_car
                                                : expense.category ==
                                                        "Transportation"
                                                    ? Icons.directions_car
                                                    : expense.category ==
                                                            "Transportation"
                                                        ? Icons.directions_car
                                                        : expense.category ==
                                                                "Bills"
                                                            ? Icons.receipt_long
                                                            : Icons.menu),
                              ),
                              title: Text(
                                expense.title,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormat("MMM dd, yyyy // HH:mm ")
                                    .format(expense.date),
                                style: TextStyle(color: Colors.white),
                              ),
                              trailing: Text(
                                "-\$${expense.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 14, 83, 153),
        foregroundColor: Colors.white,
        onPressed: _showAddExpenseDialog,
        elevation: 4,
        child: Icon(Icons.add),
      ),
    );
  }
}
