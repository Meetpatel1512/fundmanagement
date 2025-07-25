import 'dart:ui';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/models/expense_model.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<bool> createGroup(
      String groupName,
      List<String> members,
      String groupCategory,
      double initialContributionAmount,
      double minimumBalanceThreshold,
      ) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showToast('No user logged in.', AppColors.errorRed);
      return false;
    }

    try {
      if (!members.contains(currentUser.email!)) {
        members.add(currentUser.email!);
      }

      Map<String, double> balances = {};
      for (String memberEmail in members) {
        balances[memberEmail] = 0.0;
      }

      DocumentReference docRef = await _firestore.collection(AppConstants.groupsCollection).add(
        GroupModel(
          groupId: '',
          groupName: groupName,
          creatorUid: currentUser.uid,
          members: members,
          createdAt: DateTime.now(),
          groupCategory: groupCategory,
          initialContributionAmount: initialContributionAmount,
          minimumBalanceThreshold: minimumBalanceThreshold,
          memberBalances: balances,
        ).toMap(),
      );
      await docRef.update({'groupId': docRef.id});
      _showToast('Group "$groupName" created successfully!', AppColors.successGreen);
      return true;
    } catch (e) {
      _showToast('Failed to create group: $e', AppColors.errorRed);
      return false;
    }
  }

  Stream<List<GroupModel>> getUsersGroups() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.groupsCollection)
        .where('members', arrayContains: currentUser.email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GroupModel.fromFirestore(doc)).toList();
    });
  }

  Future<bool> updateGroupMembers(String groupId, List<String> newMembers) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showToast('No user logged in.', AppColors.errorRed);
      return false;
    }

    try {
      DocumentSnapshot groupDoc = await _firestore.collection(AppConstants.groupsCollection).doc(groupId).get();

      if (!groupDoc.exists) {
        _showToast('Group not found.', AppColors.errorRed);
        return false;
      }

      if (groupDoc['creatorUid'] != currentUser.uid) {
        _showToast('Only the group creator can add/remove members.', AppColors.errorRed);
        return false;
      }

      Map<String, double> existingBalances = Map<String, double>.from(
        (groupDoc.data() as Map<String, dynamic>)['memberBalances'] ?? {},
      );

      Map<String, double> updatedBalances = {};
      for (String memberEmail in newMembers) {
        updatedBalances[memberEmail] = existingBalances[memberEmail] ?? 0.0;
      }

      await _firestore.collection(AppConstants.groupsCollection).doc(groupId).update({
        'members': newMembers,
        'memberBalances': updatedBalances,
      });
      _showToast('Members updated successfully!', AppColors.successGreen);
      return true;
    } catch (e) {
      _showToast('Failed to update members: $e', AppColors.errorRed);
      return false;
    }
  }

  Future<bool> updateMemberBalanceForGroup(String groupId, String userEmail, double newBalance) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email != userEmail) {
      _showToast('Authentication error. Please log in as the correct user.', AppColors.errorRed);
      return false;
    }

    try {
      DocumentReference groupRef = _firestore.collection(AppConstants.groupsCollection).doc(groupId);
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot groupDoc = await transaction.get(groupRef);

        if (!groupDoc.exists) {
          throw Exception('Group not found!');
        }

        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        Map<String, double> currentBalances = Map<String, double>.from(data['memberBalances'] ?? {});

        currentBalances[userEmail] = newBalance; // Directly set new balance

        transaction.update(groupRef, {
          'memberBalances': currentBalances,
        });
      });
      _showToast('Balance updated for group!', AppColors.successGreen);
      return true;
    } catch (e) {
      _showToast('Failed to update balance: $e', AppColors.errorRed);
      return false;
    }
  }

  // Modified: Add an expense to a group and update member balances based on new pooled fund logic
  Future<bool> addExpense(
      String groupId,
      String description,
      double amount,
      DateTime date,
      String category,
      String paidBy, // User who paid the total amount
      String splitType,
      Map<String, double> shares, // Who owes what
      File? billImageFile,
      ) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email != paidBy) {
      _showToast('Authentication error. You must be logged in as the payer.', AppColors.errorRed);
      return false;
    }

    String? billImageUrl;
    if (billImageFile != null) {
      try {
        final storageRef = _storage.ref().child('bill_images').child('${DateTime.now().millisecondsSinceEpoch}_${billImageFile.path.split('/').last}');
        final uploadTask = storageRef.putFile(billImageFile);
        final snapshot = await uploadTask.whenComplete(() {});
        billImageUrl = await snapshot.ref.getDownloadURL();
        _showToast('Bill image uploaded successfully!', AppColors.successGreen);
      } catch (e) {
        _showToast('Failed to upload bill image: $e', AppColors.errorRed);
        return false;
      }
    }

    try {
      DocumentReference groupRef = _firestore.collection(AppConstants.groupsCollection).doc(groupId);
      DocumentReference expenseDocRef = _firestore.collection(AppConstants.expensesCollection).doc();

      await _firestore.runTransaction((transaction) async {
        // 1. Get current group data
        DocumentSnapshot groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) {
          throw Exception('Group not found!');
        }
        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
        Map<String, double> currentBalances = Map<String, double>.from(groupData['memberBalances'] ?? {});

        // --- NEW POOLED FUND BALANCE LOGIC ---
        // 1. Deduct the total expense amount from the payer's balance.
        //    This means the payer's individual share of the overall pool is reduced by the amount they spent.
        currentBalances[paidBy] = (currentBalances[paidBy] ?? 0.0) - amount;

        // 2. For each member who is part of the split: add back their specific share amount to their balance.
        //    This means their individual share of the overall pool is then adjusted back by what they "repaid"
        //    for their portion of the expense.
        shares.forEach((memberEmail, shareAmount) {
          currentBalances[memberEmail] = (currentBalances[memberEmail] ?? 0.0) + shareAmount;
        });
        // --- END NEW POOLED FUND BALANCE LOGIC ---


        // 3. Update group document with new balances
        transaction.update(groupRef, {'memberBalances': currentBalances});

        // 4. Create new expense document
        ExpenseModel newExpense = ExpenseModel(
          expenseId: expenseDocRef.id,
          groupId: groupId,
          description: description,
          amount: amount,
          date: date,
          category: category,
          paidBy: paidBy,
          splitType: splitType,
          shares: shares,
          billImageUrl: billImageUrl,
          createdAt: DateTime.now(),
        );
        transaction.set(expenseDocRef, newExpense.toMap());
      });

      _showToast('Expense added successfully!', AppColors.successGreen);
      return true;
    } catch (e) {
      _showToast('Failed to add expense: $e', AppColors.errorRed);
      return false;
    }
  }

  Stream<List<ExpenseModel>> getExpensesForGroup(String groupId) {
    return _firestore
        .collection(AppConstants.expensesCollection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();
    });
  }

  Future<bool> deleteGroup(String groupId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showToast('No user logged in.', AppColors.errorRed);
      return false;
    }

    try {
      DocumentSnapshot groupDoc = await _firestore.collection(AppConstants.groupsCollection).doc(groupId).get();

      if (!groupDoc.exists) {
        _showToast('Group not found.', AppColors.errorRed);
        return false;
      }

      if (groupDoc['creatorUid'] != currentUser.uid) {
        _showToast('You do not have permission to delete this group.', AppColors.errorRed);
        return false;
      }

      await _firestore.collection(AppConstants.groupsCollection).doc(groupId).delete();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _showToast('Permission denied. You are not authorized to delete this group.', AppColors.errorRed);
      } else {
        _showToast('Failed to delete group: ${e.message}', AppColors.errorRed);
      }
      return false;
    } catch (e) {
      _showToast('An unexpected error occurred: $e', AppColors.errorRed);
      return false;
    }
  }

  void _showToast(String message, Color backgroundColor) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: AppColors.textLight,
      fontSize: 16.0,
    );
  }
}