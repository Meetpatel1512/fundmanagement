import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String groupId;
  final String groupName;
  final String creatorUid;
  final List<String> members;
  final DateTime createdAt;
  final String groupCategory;
  final double initialContributionAmount;
  final double minimumBalanceThreshold;
  final Map<String, double> memberBalances;
  final Map<String, bool> initialPaymentStatus; // New: Tracks if initial payment is done (email -> bool)

  GroupModel({
    required this.groupId,
    required this.groupName,
    required this.creatorUid,
    required this.members,
    required this.createdAt,
    required this.groupCategory,
    this.initialContributionAmount = 0.0,
    this.minimumBalanceThreshold = 0.0,
    this.memberBalances = const {},
    this.initialPaymentStatus = const {}, // Initialize with empty map
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
      initialPaymentStatus: Map<String, bool>.from(
        (data['initialPaymentStatus'] as Map<dynamic, dynamic>?)?.map(
              (key, value) => MapEntry(key as String, value as bool),
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
      'initialPaymentStatus': initialPaymentStatus,
    };
  }
}