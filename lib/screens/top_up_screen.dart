import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/services/group_service.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:fund_management_app/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopUpScreen extends StatefulWidget {
  final GroupModel group;
  final double currentBalance;
  final double minimumBalanceThreshold;

  const TopUpScreen({
    super.key,
    required this.group,
    required this.currentBalance,
    required this.minimumBalanceThreshold,
  });

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final TextEditingController _topUpAmountController = TextEditingController();
  final GroupService _groupService = GroupService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Suggest an amount to top up to bring balance above minimum, or a round number
    double amountNeeded = widget.minimumBalanceThreshold - widget.currentBalance;
    if (amountNeeded > 0) {
      _topUpAmountController.text = (amountNeeded + 100).toStringAsFixed(2); // Suggest slightly more than needed
    } else {
      _topUpAmountController.text = '500.00'; // Default suggestion
    }
  }

  @override
  void dispose() {
    _topUpAmountController.dispose();
    super.dispose();
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

  Future<void> _recordTopUp() async {
    final userEmail = _auth.currentUser?.email;
    if (userEmail == null) {
      _showToast("You must be logged in to record payment.", AppColors.errorRed);
      return;
    }

    final double? topUpAmount = double.tryParse(_topUpAmountController.text);
    if (topUpAmount == null || topUpAmount <= 0) {
      _showToast("Please enter a valid positive amount to top up.", AppColors.errorRed);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    double newBalance = widget.currentBalance + topUpAmount;

    bool success = await _groupService.updateMemberBalanceForGroup(
      widget.group.groupId,
      userEmail,
      newBalance,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      _showToast("Balance topped up successfully!", AppColors.successGreen);
      Navigator.pop(context); // Pop this screen
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isBelowMinimum = widget.currentBalance < widget.minimumBalanceThreshold;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Top-Up for ${widget.group.groupName}'),
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        automaticallyImplyLeading: !isBelowMinimum, // Allow back if not forced to top-up
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isBelowMinimum) ...[
              Icon(Icons.account_balance_wallet_outlined, size: 80, color: AppColors.errorRed),
              const SizedBox(height: 20),
              const Text(
                'Balance Below Minimum!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.errorRed,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Your balance in "${widget.group.groupName}" is ₹${widget.currentBalance.toStringAsFixed(2)}, which is below the minimum required of ₹${widget.minimumBalanceThreshold.toStringAsFixed(2)}. Please top up to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 30),
            ] else ...[
              Icon(Icons.account_balance_wallet, size: 80, color: AppColors.accentGreen),
              const SizedBox(height: 20),
              Text(
                'Current Balance: ₹${widget.currentBalance.toStringAsFixed(2)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.currentBalance >= 0 ? AppColors.successGreen : AppColors.errorRed,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Top up your group balance for "${widget.group.groupName}".',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 30),
            ],
            // Top-up amount input
            CustomTextField(
              controller: _topUpAmountController,
              labelText: 'Enter Top-Up Amount',
              hintText: 'e.g., 500.00',
              keyboardType: TextInputType.number,
              enabled: true,
              readOnly: false,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Amount is required.';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Please enter a valid positive amount.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Add Funds',
              onPressed: _recordTopUp,
              isLoading: _isLoading,
              backgroundColor: AppColors.accentGreen,
              textColor: AppColors.textDark,
            ),
            const SizedBox(height: 20),
            if (isBelowMinimum)
              Text(
                'You must top up to access group details.',
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