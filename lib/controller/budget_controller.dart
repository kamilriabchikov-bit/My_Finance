import '../mediator/finance_mediator.dart';

class BudgetController {
  final FinanceMediator _mediator = FinanceMediator();

  FinanceMediator get mediator => _mediator;

  void selectMonth(DateTime month) => _mediator.loadMonth(month);

  Future<void> addIncome(double amount, String source) =>
      _mediator.addIncome(amount, source);

  Future<void> addExpense(double amount, String desc) =>
      _mediator.addExpense(amount, desc);

  Future<void> deleteIncome(int id) => _mediator.deleteIncome(id);

  Future<void> deleteExpense(int id) => _mediator.deleteExpense(id);
}