import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String creatorUid;
  final List<String> members;
  final DateTime createdAt;
  final String groupCategory;
  final double initialContributionAmount; // New: Mandatory amount each member must pay
  final double minimumBalanceThreshold; // New: Minimum balance required
  final Map<String, double> memberBalances; // New: Tracks current balance for each member (email -> amount)

  GroupModel({
    required this.groupId,
    required this.groupName,
    required this.creatorUid,
    required this.members,
    required this.createdAt,
    required this.groupCategory,
    this.initialContributionAmount = 0.0, // Default value
    this.minimumBalanceThreshold = 0.0, // Default value
    this.memberBalances = const {}, // Initialize with empty map
  });

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      groupId: doc.id,
      groupName: data['groupName'] ?? '',
      creatorUid: data['creatorUid'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      groupCategory: data['groupCategory'] ?? 'Other',
      initialContributionAmount: (data['initialContributionAmount'] as num?)?.toDouble() ?? 0.0,
      minimumBalanceThreshold: (data['minimumBalanceThreshold'] as num?)?.toDouble() ?? 0.0,
      memberBalances: Map<String, double>.from(
        (data['memberBalances'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(key as String, (value as num).toDouble()),
            ) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'creatorUid': creatorUid,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'groupCategory': groupCategory,
      'initialContributionAmount': initialContributionAmount,
      'minimumBalanceThreshold': minimumBalanceThreshold,
      'memberBalances': memberBalances,
    };
  }
}