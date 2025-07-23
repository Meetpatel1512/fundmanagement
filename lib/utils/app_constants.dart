import 'package:flutter/material.dart'; // Import for Icons and Color

class AppConstants {
  static const int splashScreenDurationSeconds = 3;
  static const String appName = 'Fund Management App';
  static const String usersCollection = 'fundmanagement';
  static const String groupsCollection = 'groups';

  // New: Group Categories with their display name, icon, and COLOR
  static const List<Map<String, dynamic>> groupCategories = [
    {'name': 'Home', 'icon': Icons.home, 'color': Color(0xFF4CAF50)}, // Green
    {'name': 'Trip', 'icon': Icons.airplane_ticket, 'color': Color(0xFF2196F3)}, // Blue
    {'name': 'Office', 'icon': Icons.business, 'color': Color(0xFFFF9800)}, // Orange
    {'name': 'Other', 'icon': Icons.category, 'color': Color(0xFF9E9E9E)}, // Grey (hintGrey)
  ];
}