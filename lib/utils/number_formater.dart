String formatNumber(num value) {
  final parts = value.toInt().toString().split('');

  String result = '';

  for (int i = 0; i < parts.length; i++) {
    final position = parts.length - i;

    result += parts[i];

    if (position > 1 && position % 3 == 1) {
      result += ' ';
    }
  }

  return result;
}