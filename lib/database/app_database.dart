import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Модели данных
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

  Map<String, Object?> toMap() => {
    'id': id,
    'amount': amount,
    'source': source,
    'date': date,
  };

  factory Income.fromMap(Map<String, dynamic> map) => Income(
    id: map['id'] as int?,
    amount: (map['amount'] as num).toDouble(),
    source: map['source'] as String,
    date: map['date'] as int,
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

  Map<String, Object?> toMap() => {
    'id': id,
    'amount': amount,
    'description': description,
    'category': category,
    'date': date,
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'] as int?,
    amount: (map['amount'] as num).toDouble(),
    description: map['description'] as String,
    category: map['category'] as String,
    date: map['date'] as int,
  );
}

// База данных (Singleton)
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _db;

  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Future<void> init() async {
    if (_db != null) return; // Уже инициализирована

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'finance_app.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE income(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            source TEXT NOT NULL,
            date INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE expense(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            date INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Database get db {
    if (_db == null) {
      throw StateError('База данных не инициализирована. Вызовите init() primero.');
    }
    return _db!;
  }

  // === Доходы ===
  Future<int> insertIncome(Income income) => db.insert('income', income.toMap());

  Future<List<Income>> getIncomes() async {
    final List<Map<String, dynamic>> maps = await db.query('income');
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  Future<int> deleteIncome(int id) =>
      db.delete('income', where: 'id = ?', whereArgs: [id]);

  // === Расходы ===
  Future<int> insertExpense(Expense expense) =>
      db.insert('expense', expense.toMap());

  Future<List<Expense>> getExpenses() async {
    final List<Map<String, dynamic>> maps = await db.query('expense');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> deleteExpense(int id) =>
      db.delete('expense', where: 'id = ?', whereArgs: [id]);

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}