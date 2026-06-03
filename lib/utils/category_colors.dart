import 'package:flutter/material.dart';

Color getCategoryColor(String category) {
  switch (category) {
    case 'Обязательные':
      return Colors.blue;
    case 'Развлечения':
      return Colors.orange;
    case 'Накопления':
      return Colors.green;
    default:
      return Colors.grey;
  }
}