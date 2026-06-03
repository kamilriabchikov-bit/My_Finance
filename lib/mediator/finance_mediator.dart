import 'package:flutter/foundation.dart';
import '../enity/badget_calculator.dart';
import '../enity/category_classifier.dart';
import '../database/app_database.dart';
import '../models/budget_data.dart';

class FinanceMediator extends ChangeNotifier {
  late final AppDatabase _db;
  late final Future<void> _dbInitFuture;

  DateTime _selectedMonth = DateTime.now();
  BudgetData _budgetData = BudgetData.empty();
  bool _loading = false;

  DateTime get selectedMonth => _selectedMonth;
  BudgetData get budgetData => _budgetData;
  bool get loading => _loading;

  FinanceMediator() {
    _dbInitFuture = _initDb();
  }

  Future<void> _initDb() async {
    _db = await AppDatabase.instance;
  }

  Future<void> _ensureDb() async {
    await _dbInitFuture;
  }

  Future<void> loadMonth(DateTime month) async {
    await _ensureDb();
    _selectedMonth = DateTime(month.year, month.month, 1);
    _loading = true;
    notifyListeners();

    try {
      final incomes = await _db.getIncomes();
      final monthlyIncomes = incomes.where((i) {
        final d = DateTime.fromMillisecondsSinceEpoch(i.date);
        return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
      });
      final totalIncome = monthlyIncomes.fold(0.0, (sum, i) => sum + i.amount);

      final limits = BudgetCalculator.calculateLimits(totalIncome);

      final expenses = await _db.getExpenses();
      final monthlyExpenses = expenses.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.date);
        return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
      });

      final spent = <String, double>{
        'Обязательные': 0.0,
        'Развлечения': 0.0,
        'Накопления': 0.0,
      };
      for (final e in monthlyExpenses) {
        spent[e.category] = (spent[e.category] ?? 0.0) + e.amount;
      }

      _budgetData = BudgetData(spent: spent, limits: limits);
    } catch (_) {
      _budgetData = BudgetData.empty();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addIncome(double amount, String source) async {
    await _ensureDb();
    final income = Income(
      amount: amount,
      source: source,
      date: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.insertIncome(income);
    await loadMonth(_selectedMonth);
  }

  Future<void> addExpense(double amount, String description) async {
    await _ensureDb();
    final category = getCategoryFromDescription(description);
    final expense = Expense(
      amount: amount,
      description: description,
      category: category,
      date: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.insertExpense(expense);
    await loadMonth(_selectedMonth);
  }

  Future<void> deleteIncome(int id) async {
    await _ensureDb();
    await _db.deleteIncome(id);
    await loadMonth(_selectedMonth);
  }

  Future<void> deleteExpense(int id) async {
    await _ensureDb();
    await _db.deleteExpense(id);
    await loadMonth(_selectedMonth);
  }
}