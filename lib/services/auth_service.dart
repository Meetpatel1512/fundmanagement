import 'dart:io'; // For File operations
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/user_model.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/app_messages.dart';
import 'package:fund_management_app/utils/custom_colors.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage instance

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register a new user with email and password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Store user data in Firestore, including the password
        // WARNING: Storing plain text or easily reversible passwords directly
        // in your database is a security risk. Firebase Authentication
        // already handles secure password hashing and storage.
        await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(
          UserModel(
            uid: user.uid,
            email: user.email!,
            password: password, // Storing the password as requested
            createdAt: DateTime.now(),
            username: null, // Initially null
            profileImageUrl: null, // Initially null
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

  // Sign in a user with email and password
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

  // Send password reset email
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

  // Update user profile (username and profile image URL)
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
        // Upload image to Firebase Storage
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
      // Get current user data from Firestore
      DocumentSnapshot userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
      UserModel currentUserModel = UserModel.fromFirestore(userDoc);

      // Create updated UserModel
      UserModel updatedUserModel = UserModel(
        uid: currentUserModel.uid,
        email: currentUserModel.email,
        password: currentUserModel.password, // Keep existing password
        createdAt: currentUserModel.createdAt,
        username: username ?? currentUserModel.username, // Update if provided, otherwise keep existing
        profileImageUrl: imageUrl ?? currentUserModel.profileImageUrl, // Update if provided, otherwise keep existing
      );

      // Update user data in Firestore
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(
        updatedUserModel.toMap(),
        SetOptions(merge: true), // Use merge to update only specified fields
      );

      // Also update Firebase Auth profile display name and photo URL
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

  // Fetch user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e'); // For debugging
      return null;
    }
  }

  // Reload user to check email verification status (removed as email verification fields are removed)
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      // No need to update Firestore for email verification status as it's removed from UserModel
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _showToast(AppMessages.logoutSuccess, AppColors.successGreen);
    } catch (e) {
      _showToast(AppMessages.somethingWentWrong, AppColors.errorRed);
    }
  }

  // Helper function to show toast messages
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
