import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/user_model.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/app_messages.dart';
import 'package:fund_management_app/utils/custom_colors.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(
          UserModel(
            uid: user.uid,
            email: user.email!,
            password: password,
            createdAt: DateTime.now(),
            username: email.split('@')[0], // Auto-set username from email for new registrations
            profileImageUrl: null,
          ).toMap(),
        );
        _showToast(AppMessages.registrationSuccess, AppColors.successGreen);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      String message = AppMessages.somethingWentWrong;
      if (e.code == 'weak-password') {
        message = AppMessages.weakPassword;
      } else if (e.code == 'email-already-in-use') {
        message = AppMessages.emailAlreadyInUse;
      } else if (e.code == 'invalid-email') {
        message = AppMessages.invalidEmail;
      }
      _showToast(message, AppColors.errorRed);
      return null;
    } catch (e) {
      _showToast(AppMessages.somethingWentWrong, AppColors.errorRed);
      return null;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _showToast(AppMessages.loginSuccess, AppColors.successGreen);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String message = AppMessages.somethingWentWrong;
      if (e.code == 'user-not-found') {
        message = AppMessages.userNotFound;
      } else if (e.code == 'wrong-password') {
        message = AppMessages.wrongPassword;
      } else if (e.code == 'invalid-email') {
        message = AppMessages.invalidEmail;
      } else if (e.code == 'user-disabled') {
        message = AppMessages.userDisabled;
      } else if (e.code == 'too-many-requests') {
        message = AppMessages.tooManyRequests;
      }
      _showToast(message, AppColors.errorRed);
      return null;
    } catch (e) {
      _showToast(AppMessages.somethingWentWrong, AppColors.errorRed);
      return null;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showToast('Password reset link sent to your email. Please check your inbox.', AppColors.successGreen);
    } on FirebaseAuthException catch (e) {
      String message = AppMessages.somethingWentWrong;
      if (e.code == 'invalid-email') {
        message = AppMessages.invalidEmail;
      } else if (e.code == 'user-not-found') {
        message = AppMessages.userNotFound;
      }
      _showToast(message, AppColors.errorRed);
    } catch (e) {
      _showToast(AppMessages.somethingWentWrong, AppColors.errorRed);
    }
  }

  Future<void> updateUserProfile({
    String? username,
    File? profileImageFile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showToast('No user logged in.', AppColors.errorRed);
      return;
    }

    String? imageUrl;
    if (profileImageFile != null) {
      try {
        final storageRef = _storage.ref().child('profile_pictures').child('${user.uid}.jpg');
        final uploadTask = storageRef.putFile(profileImageFile);
        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        _showToast('Failed to upload profile picture: $e', AppColors.errorRed);
        return;
      }
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
      UserModel currentUserModel = UserModel.fromFirestore(userDoc);

      UserModel updatedUserModel = UserModel(
        uid: currentUserModel.uid,
        email: currentUserModel.email,
        password: currentUserModel.password,
        createdAt: currentUserModel.createdAt,
        username: username ?? currentUserModel.username,
        profileImageUrl: imageUrl ?? currentUserModel.profileImageUrl,
      );
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(
        updatedUserModel.toMap(),
        SetOptions(merge: true),
      );
      if (username != null) {
        await user.updateDisplayName(username);
      }
      if (imageUrl != null) {
        await user.updatePhotoURL(imageUrl);
      }

      _showToast('Profile updated successfully!', AppColors.successGreen);
    } catch (e) {
      _showToast('Failed to update profile: $e', AppColors.errorRed);
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // New: Get username by email
  Future<String?> getUsernameByEmail(String email) async {
    try {
      // Find user document where email matches
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        return userData['username'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching username by email: $e');
      return null;
    }
  }


  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _showToast(AppMessages.logoutSuccess, AppColors.successGreen);
    } catch (e) {
      _showToast(AppMessages.somethingWentWrong, AppColors.errorRed);
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