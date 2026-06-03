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

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();

  static Future<AppDatabase> get instance async {
    await _instance._init();
    return _instance;
  }

  late Database _db;
  bool _isInitialized = false;

  AppDatabase._internal();


  Future<void> _init() async {
    if (_isInitialized) return;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_finance.db');

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
    _isInitialized = true;
  }

  // Доходы
  Future<int> insertIncome(Income income) async {
    await _ensureInitialized();
    return _db.insert('income', income.toMap());
  }

  Future<List<Income>> getIncomes() async {
    await _ensureInitialized();
    final List<Map<String, dynamic>> maps = await _db.query('income');
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  Future<void> deleteIncome(int id) async {
    await _ensureInitialized();
    await _db.delete('income', where: 'id = ?', whereArgs: [id]);
  }

  // Расходы
  Future<int> insertExpense(Expense expense) async {
    await _ensureInitialized();
    return _db.insert('expense', expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    await _ensureInitialized();
    final List<Map<String, dynamic>> maps = await _db.query('expense');
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<void> deleteExpense(int id) async {
    await _ensureInitialized();
    await _db.delete('expense', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _init();
    }
  }

  Future<void> close() async {
    if (_isInitialized) {
      await _db.close();
      _isInitialized = false;
    }
  }
}