import 'package:flutter/foundation.dart';
import '../entity/budget_calculator.dart';
import '../entity/category_classifier.dart';
import '../database/app_database.dart';
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

  // Списки транзакций за выбранный месяц
  List<Income> _incomes = [];
  List<Expense> _expenses = [];

  DateTime get selectedMonth => _selectedMonth;
  BudgetData get budgetData => _budgetData;
  bool get loading => _loading;
  List<Income> get incomes => _incomes;
  List<Expense> get expenses => _expenses;

  /// Загрузить (пересчитать) данные за конкретный месяц
  Future<void> loadMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month, 1);
    _loading = true;
    notifyListeners();

    try {
      // Доходы за месяц
      final allIncomes = await _db.getIncomes();
      _incomes = allIncomes.where((i) {
        final d = DateTime.fromMillisecondsSinceEpoch(i.date);
        return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final totalIncome = _incomes.fold<double>(0.0, (sum, i) => sum + i.amount);

      // Лимиты 50/30/20
      final limits = BudgetCalculator.calculateLimits(totalIncome);

      // Расходы за месяц
      final allExpenses = await _db.getExpenses();
      _expenses = allExpenses.where((e) {
        final d = DateTime.fromMillisecondsSinceEpoch(e.date);
        return d.year == _selectedMonth.year && d.month == _selectedMonth.month;
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final spent = <String, double>{
        'Обязательные': 0.0,
        'Развлечения': 0.0,
        'Накопления': 0.0,
      };
      for (final e in _expenses) {
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