import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

//  модели данных
class Income {
  final int? id;
  final double amount;
  final String source;
  final int date; // millisecondsSinceEpoch

  Income({
    this.id,
    required this.amount,
    required this.source,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'source': source,
    'date': date,
  };

  factory Income.fromMap(Map<String, dynamic> map) => Income(
    id: map['id'],
    amount: map['amount'],
    source: map['source'],
    date: map['date'],
  );
}

class Expense {
  final int? id;
  final double amount;
  final String description;
  final String category;
  final int date;

  Expense({
    this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'description': description,
    'category': category,
    'date': date,
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'],
    amount: map['amount'],
    description: map['description'],
    category: map['category'],
    date: map['date'],
  );
}

// база данных
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  late Database _db;

  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Future<void> init() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'finance_app.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE income(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          source TEXT NOT NULL,
          date INTEGER NOT NULL
        )''');
        await db.execute('''CREATE TABLE expense(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          description TEXT NOT NULL,
          category TEXT NOT NULL,
          date INTEGER NOT NULL
        )''');
      },
    );
  }

  // Доходы
  Future<int> insertIncome(Income income) =>
      _db.insert('income', income.toMap());
  Future<List<Income>> getIncomes() async {
    final List<Map<String, dynamic>> maps = await _db.query('income');
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  Future<void> deleteIncome(int id) =>
      _db.delete('income', where: 'id = ?', whereArgs: [id]);

  // Расходы
  Future<int> insertExpense(Expense expense) =>
      _db.insert('expense', expense.toMap());
  Future<List<Expense>> getExpenses() async {
    final List<Map<String, dynamic>> maps = await _db.query('expense');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<void> deleteExpense(int id) =>
      _db.delete('expense', where: 'id = ?', whereArgs: [id]);

  Future<void> close() async => _db.close();
}
