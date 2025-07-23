import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new group in Firestore
  Future<bool> createGroup(String groupName, List<String> members, String groupCategory) async { // Added groupCategory
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      _showToast('No user logged in.', AppColors.errorRed);
      return false;
    }

    try {
      if (!members.contains(currentUser.email!)) {
        members.add(currentUser.email!);
      }

      DocumentReference docRef = await _firestore.collection(AppConstants.groupsCollection).add(
        GroupModel(
          groupId: '',
          groupName: groupName,
          creatorUid: currentUser.uid,
          members: members,
          createdAt: DateTime.now(),
          groupCategory: groupCategory, // Store the category
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

  // Get a stream of groups where the current user is either the creator or a member
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

  // Method to update members of an existing group
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

      await _firestore.collection(AppConstants.groupsCollection).doc(groupId).update({
        'members': newMembers,
      });
      _showToast('Members updated successfully!', AppColors.successGreen);
      return true;
    } catch (e) {
      _showToast('Failed to update members: $e', AppColors.errorRed);
      return false;
    }
  }

  // Method to delete a group
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