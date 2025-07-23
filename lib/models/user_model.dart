import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? password; // Added password field
  final String? username; // New: Username for the user
  final String? profileImageUrl; // New: URL for the user's profile picture
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.password,
    this.username, // Initialize new field
    this.profileImageUrl, // Initialize new field
    required this.createdAt,
  });

  // Factory constructor to create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      password: data['password'],
      username: data['username'], // Retrieve username from Firestore
      profileImageUrl: data['profileImageUrl'], // Retrieve profile image URL from Firestore
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Method to convert a UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'password': password,
      'username': username, // Include username in the map for storage
      'profileImageUrl': profileImageUrl, // Include profile image URL in the map for storage
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
