import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String expenseId;
  final String groupId;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String paidBy; // Email of the user who paid the entire amount
  final String splitType; // 'equally' or 'unequally'
  final Map<String, double> shares; // Map of memberEmail -> amount owed by that member
  final String? billImageUrl; // Optional URL for the bill image
  final DateTime createdAt; // Timestamp of when the expense was recorded

  ExpenseModel({
    required this.expenseId,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.paidBy,
    required this.splitType,
    required this.shares,
    this.billImageUrl,
    required this.createdAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      expenseId: doc.id,
      groupId: data['groupId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? 'Other',
      paidBy: data['paidBy'] ?? '',
      splitType: data['splitType'] ?? 'equally',
      shares: Map<String, double>.from(
        (data['shares'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(key as String, (value as num).toDouble()),
            ) ??
            {},
      ),
      billImageUrl: data['billImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'paidBy': paidBy,
      'splitType': splitType,
      'shares': shares,
      'billImageUrl': billImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}