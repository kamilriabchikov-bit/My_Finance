import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'database/app_database.dart';
import 'mediator/finance_mediator.dart';
import 'widgets/category_card.dart';
import 'widgets/transaction_dialog.dart';

// ГЛАВНАЯ СТРАНИЦА
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FinanceMediator _mediator = FinanceMediator();

  @override
  void initState() {
    super.initState();
    _mediator.loadMonth(_mediator.selectedMonth);
    _mediator.addListener(_onMediatorChanged);
  }

  @override
  void dispose() {
    _mediator.removeListener(_onMediatorChanged);
    super.dispose();
  }

  void _onMediatorChanged() {
    if (mounted) setState(() {});
  }

  // Форматирование с заглавной буквы
  String _formatMonthYear(DateTime date) {
    final formatted = DateFormat('LLLL yyyy', 'ru_RU').format(date);
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  // Открыть выбор даты
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _mediator.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _mediator.selectedMonth) {
      _mediator.loadMonth(DateTime(picked.year, picked.month, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = _formatMonthYear(_mediator.selectedMonth);
    final width = MediaQuery.sizeOf(context).width;
    final buttonSize = (width * 0.15).clamp(50.0, 70.0);
    final spacing = 16.0;

    final budget = _mediator.budgetData;

    return Scaffold(
      appBar: AppBar(
        title: TextButton(
          onPressed: () => _selectMonth(context),
          child: Text(
            monthName,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CategoryCard(
                        category: 'Обязательные',
                        spent: budget.spent['Обязательные'] ?? 0.0,
                        limit: budget.limits['Обязательные'] ?? 0.0,
                      ),
                      const SizedBox(height: 16),
                      CategoryCard(
                        category: 'Развлечения',
                        spent: budget.spent['Развлечения'] ?? 0.0,
                        limit: budget.limits['Развлечения'] ?? 0.0,
                      ),
                      const SizedBox(height: 16),
                      CategoryCard(
                        category: 'Накопления',
                        spent: budget.spent['Накопления'] ?? 0.0,
                        limit: budget.limits['Накопления'] ?? 0.0,
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              // Кнопки
              Positioned(
                right: spacing,
                bottom: spacing + MediaQuery.viewPaddingOf(context).bottom,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (ctx) => const TransactionDialog(isIncome: true),
                        );
                      },
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          color: Colors.green[600],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (ctx) => const TransactionDialog(isIncome: false),
                        );
                      },
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          color: Colors.orange[800],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.money_off,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// СТРАНИЦА ИСТОРИИ
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FinanceMediator _mediator = FinanceMediator();

  @override
  void initState() {
    super.initState();
    _mediator.addListener(_onMediatorChanged);
    if (_mediator.incomes.isEmpty && _mediator.expenses.isEmpty) {
      _mediator.loadMonth(_mediator.selectedMonth);
    }
  }

  @override
  void dispose() {
    _mediator.removeListener(_onMediatorChanged);
    super.dispose();
  }

  void _onMediatorChanged() {
    if (mounted) setState(() {});
  }

  String _formatDate(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateFormat('dd.MM.yyyy', 'ru_RU').format(date);
  }

  Future<void> _confirmDelete(BuildContext context, bool isIncome, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text('Удалить эту запись?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (isIncome) {
        await _mediator.deleteIncome(id);
      } else {
        await _mediator.deleteExpense(id);
      }
    }
  }

  // Адаптивный размер шрифта
  double _adaptiveFontSize(BuildContext context, double baseSize) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return baseSize * 0.85;
    if (width > 450) return baseSize * 1.1;
    return baseSize;
  }

  @override
  Widget build(BuildContext context) {
    final incomes = _mediator.incomes;
    final expenses = _mediator.expenses;

    final List<Map<String, dynamic>> allTransactions = [];

    for (final i in incomes) {
      allTransactions.add({
        'isIncome': true,
        'id': i.id,
        'amount': i.amount,
        'description': i.source,
        'date': i.date,
        'category': 'Доход',
      });
    }

    for (final e in expenses) {
      allTransactions.add({
        'isIncome': false,
        'id': e.id,
        'amount': e.amount,
        'description': e.description,
        'date': e.date,
        'category': e.category,
      });
    }

    allTransactions.sort((a, b) => (b['date'] as int).compareTo(a['date'] as int));

    return Scaffold(
      appBar: AppBar(
        title: const Text('История'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _mediator.loading
          ? const Center(child: CircularProgressIndicator())
          : allTransactions.isEmpty
          ? const Center(
        child: Text(
          'Нет операций за этот месяц',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: allTransactions.length,
        itemBuilder: (context, index) {
          final tx = allTransactions[index];
          final isIncome = tx['isIncome'] as bool;
          final amount = tx['amount'] as double;
          final description = tx['description'] as String;
          final date = tx['date'] as int;
          final category = tx['category'] as String;
          final id = tx['id'] as int?;

          final titleSize = _adaptiveFontSize(context, 16.0);
          final subtitleSize = _adaptiveFontSize(context, 12.0);
          final amountSize = _adaptiveFontSize(context, 16.0);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: _adaptiveFontSize(context, 18.0),
                        backgroundColor: isIncome ? Colors.green[100] : Colors.orange[100],
                        child: Icon(
                          isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isIncome ? Colors.green[700] : Colors.orange[700],
                          size: _adaptiveFontSize(context, 20.0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Описание с Flexible
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: titleSize,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Сумма
                      Text(
                        '${isIncome ? '+' : '-'}${amount.toStringAsFixed(2)} ₽',
                        style: TextStyle(
                          color: isIncome ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          fontSize: amountSize,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: _adaptiveFontSize(context, 14.0),
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(date),
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (id != null)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: _adaptiveFontSize(context, 20.0)),
                          onPressed: () => _confirmDelete(context, isIncome, id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// НАВИГАЦИЯ
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = const [HomePage(), HistoryPage()];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'История'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ОСНОВНОЕ ПРИЛОЖЕНИЕ
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);

  // Инициализация базы данных
  await AppDatabase().init();

  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Tracker',
      theme: ThemeData(useMaterial3: true),
      home: const MainScreen(),
    );
  }
}