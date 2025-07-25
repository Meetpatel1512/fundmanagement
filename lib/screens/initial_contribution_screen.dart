import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/services/group_service.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InitialContributionScreen extends StatefulWidget {
  final GroupModel group;

  const InitialContributionScreen({
    super.key,
    required this.group,
  });

  @override
  State<InitialContributionScreen> createState() => _InitialContributionScreenState();
}

class _InitialContributionScreenState extends State<InitialContributionScreen> {
  final GroupService _groupService = GroupService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

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

  Future<void> _recordPayment() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) {
      _showToast("You must be logged in to record payment.", AppColors.errorRed);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Update the user's balance for this group to the initialContributionAmount
    bool success = await _groupService.updateMemberBalanceForGroup(
      widget.group.groupId,
      userEmail,
      widget.group.initialContributionAmount, // Set balance to the required amount
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.pop(context); // Pop this screen, allowing entry to group details
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Initial Contribution for ${widget.group.groupName}'),
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.warning_amber, size: 80, color: AppColors.errorRed),
            const SizedBox(height: 20),
            const Text(
              'Mandatory Contribution Required!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Before you can access the group details for "${widget.group.groupName}", each member is required to contribute an initial amount of ₹${widget.group.initialContributionAmount.toStringAsFixed(2)}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: 'Pay ₹${widget.group.initialContributionAmount.toStringAsFixed(2)} Now',
              onPressed: _recordPayment,
              isLoading: _isLoading,
              backgroundColor: AppColors.accentGreen,
              textColor: AppColors.textDark,
            ),
            const SizedBox(height: 20),
            Text(
              'You will not be able to view group expenses or add new ones until this contribution is made.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.hintGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}