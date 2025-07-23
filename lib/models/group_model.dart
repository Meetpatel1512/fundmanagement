import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String creatorUid; // UID of the user who created the group
  final List<String> members; // List of member emails
  final DateTime createdAt;
  final String groupCategory; // New: Category of the group (e.g., 'Home', 'Trip')

  GroupModel({
    required this.groupId,
    required this.groupName,
    required this.creatorUid,
    required this.members,
    required this.createdAt,
    required this.groupCategory, // Initialize new field
  });
  // Factory constructor to create a GroupModel from a Firestore DocumentSnapshot
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      groupId: doc.id,
      groupName: data['groupName'] ?? '',
      creatorUid: data['creatorUid'] ?? '',
      members: List<String>.from(data['members'] ?? []), // Ensure members is a List<String>
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      groupCategory: data['groupCategory'] ?? 'Other', // Retrieve category, default to 'Other'
    );
  }

  // Method to convert a GroupModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'creatorUid': creatorUid,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'groupCategory': groupCategory, // Include category in the map for storage
    };
  }
}