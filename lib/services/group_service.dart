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
      Map<String, bool> paymentStatus = {}; // Initialize new map
      for (String memberEmail in members) {
        balances[memberEmail] = 0.0;
        paymentStatus[memberEmail] = false; // Set initial payment status to false
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
          initialPaymentStatus: paymentStatus, // Store initial status
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
      Map<String, bool> existingPaymentStatus = Map<String, bool>.from(
        (groupDoc.data() as Map<String, dynamic>)['initialPaymentStatus'] ?? {},
      );

      Map<String, double> updatedBalances = {};
      Map<String, bool> updatedPaymentStatus = {};
      for (String memberEmail in newMembers) {
        updatedBalances[memberEmail] = existingBalances[memberEmail] ?? 0.0;
        updatedPaymentStatus[memberEmail] = existingPaymentStatus[memberEmail] ?? false; // New members start as false
      }

      await _firestore.collection(AppConstants.groupsCollection).doc(groupId).update({
        'members': newMembers,
        'memberBalances': updatedBalances,
        'initialPaymentStatus': updatedPaymentStatus, // Update initial payment status map
      });
      _showToast('Members updated successfully!', AppColors.successGreen);
      return true;
    } catch (e) {
      _showToast('Failed to update members: $e', AppColors.errorRed);
      return false;
    }
  }

  // Modified: updateMemberBalanceForGroup now can optionally mark initial payment done
  Future<bool> updateMemberBalanceForGroup(
      String groupId,
      String userEmail,
      double newBalance, {
      bool markInitialPaymentDone = false, // New optional parameter
      }) async {
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
        Map<String, bool> currentPaymentStatus = Map<String, bool>.from(data['initialPaymentStatus'] ?? {});

        currentBalances[userEmail] = newBalance;

        if (markInitialPaymentDone) {
          currentPaymentStatus[userEmail] = true;
        }

        transaction.update(groupRef, {
          'memberBalances': currentBalances,
          'initialPaymentStatus': currentPaymentStatus, // Update status
        });
      });
      _showToast('Balance updated for group!', AppColors.successGreen);
      return true;
    } catch (e) {
      _showToast('Failed to update balance: $e', AppColors.errorRed);
      return false;
    }
  }

  Future<bool> addExpense(
      String groupId,
      String description,
      double amount,
      DateTime date,
      String category,
      String paidBy,
      String splitType,
      Map<String, double> shares,
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
        DocumentSnapshot groupDoc = await transaction.get(groupRef);
        if (!groupDoc.exists) {
          throw Exception('Group not found!');
        }
        Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
        Map<String, double> currentBalances = Map<String, double>.from(groupData['memberBalances'] ?? {});

        // --- POOLED FUND (SUBTRACTION-ONLY) BALANCE LOGIC ---
        // For each member who is part of the split: their balance is REDUCED by their share.
        // This includes the payer, who also has their share deducted.
        shares.forEach((memberEmail, shareAmount) {
          currentBalances[memberEmail] = (currentBalances[memberEmail] ?? 0.0) - shareAmount;
        });

        // The payer's role in this model is simply to record the expense;
        // their balance is NOT directly impacted by the total amount paid, only by their share.
        // The total group balance (sum of member balances) will correctly reflect total - expense.
        // This is why we remove the previous line that added 'amount' to paidBy's balance.
        // --- END POOLED FUND (SUBTRACTION-ONLY) BALANCE LOGIC ---


        transaction.update(groupRef, {'memberBalances': currentBalances});

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