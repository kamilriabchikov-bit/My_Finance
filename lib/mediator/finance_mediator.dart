import 'package:flutter/foundation.dart';
import '../entity/category_classifier.dart';
import '../database/app_database.dart';
import '../entity/budget_calculator.dart';
import '../models/budget_data.dart';

class FinanceMediator extends ChangeNotifier {
  // Singleton
  static final FinanceMediator _instance = FinanceMediator._internal();
  factory FinanceMediator() => _instance;
  FinanceMediator._internal();

  final AppDatabase _db = AppDatabase();

  DateTime _selectedMonth = DateTime.now();
  BudgetData _budgetData = BudgetData.empty();
  bool _loading = false;

  DateTime get selectedMonth => _selectedMonth;
  BudgetData get budgetData => _budgetData;
  bool get loading => _loading;

  /// Загрузить (пересчитать) данные за конкретный месяц
  Future<void> loadMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _loading = true;
    notifyListeners();

    try {
      // Доходы за месяц
      final incomes = await _db.getIncomes();
      final monthlyIncomes = incomes.where((i) {
        final d = DateTime.fromMillisecondsSinceEpoch(i.date);
        return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
      });
      final totalIncome =
      monthlyIncomes.fold<double>(0.0, (sum, i) => sum + i.amount);

      // Лимиты 50/30/20
      final limits = BudgetCalculator.calculateLimits(totalIncome);

      // Расходы за месяц
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
    } catch (e) {
      debugPrint('Ошибка загрузки данных: $e');
      _budgetData = BudgetData.empty();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Добавить доход
  Future<void> addIncome(double amount, String source) async {
    final income = Income(
      amount: amount,
      source: source,
      date: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.insertIncome(income);
    await loadMonth(_selectedMonth);
  }

  /// Добавить расход
  Future<void> addExpense(double amount, String description) async {
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

  /// Удалить доход
  Future<void> deleteIncome(int id) async {
    await _db.deleteIncome(id);
    await loadMonth(_selectedMonth);
  }

  /// Удалить расход
  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    await loadMonth(_selectedMonth);
  }
}