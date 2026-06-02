class BudgetCalculator {
  static Map<String, double> calculateLimits(double totalIncome) => {
    'Обязательные': totalIncome * 0.5,
    'Развлечения': totalIncome * 0.3,
    'Накопления': totalIncome * 0.2,
  };
}
