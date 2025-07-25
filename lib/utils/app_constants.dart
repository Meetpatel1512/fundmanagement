import 'package:flutter/material.dart';

class AppConstants {
  static const int splashScreenDurationSeconds = 3;
  static const String appName = 'Fund Management App';
  static const String usersCollection = 'fundmanagement';
  static const String groupsCollection = 'groups';
  static const String expensesCollection = 'expenses'; // New: Firebase collection name for expenses

  // Group Categories with their display name, icon, and COLOR
  static const List<Map<String, dynamic>> groupCategories = [
    {'name': 'Home', 'icon': Icons.home, 'color': Color(0xFF4CAF50)}, // Green
    {'name': 'Trip', 'icon': Icons.airplane_ticket, 'color': Color(0xFF2196F3)}, // Blue
    {'name': 'Office', 'icon': Icons.business, 'color': Color(0xFFFF9800)}, // Orange
    {'name': 'Other', 'icon': Icons.category, 'color': Color(0xFF9E9E9E)}, // Grey (hintGrey)
  ];

  // Expense Categories with their display name, icon, and COLOR
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': Icons.fastfood, 'color': Color(0xFFF44336)}, // Red
    {'name': 'Drinks', 'icon': Icons.local_drink, 'color': Color(0xFF00BCD4)}, // Cyan
    {'name': 'Groceries', 'icon': Icons.shopping_basket, 'color': Color(0xFF8BC34A)}, // Light Green
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Color(0xFF9C27B0)}, // Purple
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Color(0xFFFFC107)}, // Amber
    {'name': 'Travel', 'icon': Icons.flight, 'color': Color(0xFF3F51B5)}, // Indigo
    {'name': 'Fuel', 'icon': Icons.local_gas_station, 'color': Color(0xFF607D8B)}, // Blue Grey
    {'name': 'Other', 'icon': Icons.category, 'color': Color(0xFF9E9E9E)}, // Grey
  ];
}