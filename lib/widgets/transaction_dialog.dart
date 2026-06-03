import 'package:flutter/material.dart';
import '../mediator/finance_mediator.dart';

class TransactionDialog extends StatefulWidget {
  final bool isIncome;
  const TransactionDialog({super.key, required this.isIncome});

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) async {
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (amountText.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму')),
      );
      return;
    }

    // Используем singleton-экземпляр медиатора
    final mediator = FinanceMediator();

    if (widget.isIncome) {
      await mediator.addIncome(amount, description);
    } else {
      await mediator.addExpense(amount, description);
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isIncome ? 'Доход добавлен' : 'Расход добавлен'),
        backgroundColor: widget.isIncome ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isIncome ? 'Новый доход' : 'Новый расход';
    final hint = widget.isIncome
        ? 'Источник (зарплата...)'
        : 'Описание (кино, цирк...)';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Сумма',
                hintText: '1000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: widget.isIncome ? 'Источник' : 'Описание',
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => _onSubmit(context),
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}