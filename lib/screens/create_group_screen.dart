import 'package:flutter/material.dart';
import 'package:fund_management_app/services/group_service.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:fund_management_app/widgets/custom_text_field.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);
  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _memberEmailController = TextEditingController();
  final TextEditingController _initialContributionController = TextEditingController(text: '2000.00'); // Default
  final TextEditingController _minimumBalanceController = TextEditingController(text: '100.00'); // Default

  final List<String> _members = [];
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final GroupService _groupService = GroupService();
  String _selectedCategory = AppConstants.groupCategories[0]['name'];

  void _addMember() {
    String email = _memberEmailController.text.trim();
    if (email.isEmpty) {
      _showToast("Email address cannot be empty.", AppColors.errorRed);
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showToast("Please enter a valid email address.", AppColors.errorRed);
      return;
    }

    if (_members.contains(email)) {
      _showToast("This email is already in the group.", AppColors.hintGrey);
      _memberEmailController.clear();
      return;
    }

    setState(() {
      _members.add(email);
      _memberEmailController.clear();
    });
    _showToast("$email added.", AppColors.successGreen);
  }

  void _removeMember(int index) {
    setState(() {
      String removedEmail = _members.removeAt(index);
      _showToast("$removedEmail removed.", AppColors.hintGrey);
    });
  }

  void _createGroup() async {
    if (_formKey.currentState!.validate()) {
      if (_groupNameController.text.trim().isEmpty) {
        _showToast("Group name cannot be empty.", AppColors.errorRed);
        return;
      }
      if (_members.isEmpty) {
        _showToast("Please add at least one member to the group.", AppColors.errorRed);
        return;
      }

      final double? initialContribution = double.tryParse(_initialContributionController.text);
      final double? minimumBalance = double.tryParse(_minimumBalanceController.text);

      if (initialContribution == null || initialContribution <= 0) {
        _showToast("Please enter a valid initial contribution amount.", AppColors.errorRed);
        return;
      }
      if (minimumBalance == null || minimumBalance < 0) {
        _showToast("Please enter a valid minimum balance threshold.", AppColors.errorRed);
        return;
      }
      if (minimumBalance > initialContribution) {
        _showToast("Minimum balance cannot be greater than initial contribution.", AppColors.errorRed);
        return;
      }


      setState(() {
        _isLoading = true;
      });

      bool success = await _groupService.createGroup(
        _groupNameController.text.trim(),
        _members,
        _selectedCategory,
        initialContribution, // Pass initial contribution
        minimumBalance, // Pass minimum balance
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        Navigator.pop(context);
      }
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

  @override
  void dispose() {
    _groupNameController.dispose();
    _memberEmailController.dispose();
    _initialContributionController.dispose();
    _minimumBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Create New Group'),
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Group Name',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _groupNameController,
                  labelText: 'Enter Group Name',
                  hintText: 'e.g., Family Funds',
                  enabled: true,
                  readOnly: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Group name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Group Type',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.groupCategories.length,
                    itemBuilder: (context, index) {
                      final category = AppConstants.groupCategories[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ChoiceChip(
                          label: Text(category['name']),
                          selected: _selectedCategory == category['name'],
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategory = category['name'];
                              }
                            });
                          },
                          selectedColor: (category['color'] as Color).withOpacity(0.7),
                          backgroundColor: AppColors.textLight,
                          labelStyle: TextStyle(
                            color: _selectedCategory == category['name']
                                ? AppColors.textDark
                                : AppColors.hintGrey,
                            fontWeight: _selectedCategory == category['name']
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          avatar: Icon(
                            category['icon'],
                            color: _selectedCategory == category['name']
                                ? AppColors.textDark
                                : (category['color'] as Color),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            side: BorderSide(
                              color: _selectedCategory == category['name']
                                  ? (category['color'] as Color)
                                  : AppColors.borderColor,
                              width: 1.5,
                            ),
                          ),
                          elevation: 2,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Initial Contribution Amount
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Initial Contribution (per member)',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _initialContributionController,
                  labelText: 'Amount in Rupees (e.g., 2000)',
                  hintText: '2000.00',
                  keyboardType: TextInputType.number,
                  enabled: true,
                  readOnly: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Initial contribution is required.';
                    }
                    if (double.tryParse(value) == null || double.parse(value) <= 0) {
                      return 'Please enter a valid positive amount.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Minimum Balance Threshold
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Minimum Balance Threshold',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _minimumBalanceController,
                  labelText: 'Amount in Rupees (e.g., 100)',
                  hintText: '100.00',
                  keyboardType: TextInputType.number,
                  enabled: true,
                  readOnly: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Minimum balance is required.';
                    }
                    if (double.tryParse(value) == null || double.parse(value) < 0) {
                      return 'Please enter a valid non-negative amount.';
                    }
                    if (double.tryParse(value)! > double.tryParse(_initialContributionController.text)!) {
                      return 'Min balance cannot be > initial contribution.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add Members by Email',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _memberEmailController,
                        labelText: 'Member Email',
                        hintText: 'member@example.com',
                        keyboardType: TextInputType.emailAddress,
                        enabled: true,
                        readOnly: false,
                        validator: (value) {
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomButton(
                      text: 'Add',
                      height: 50,
                      width: 80,
                      onPressed: _addMember,
                      isLoading: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_members.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.textLight,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Members:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _members[index],
                                      style: const TextStyle(color: AppColors.textDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeMember(index),
                                    child: const Icon(
                                      Icons.close,
                                      color: AppColors.errorRed,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Create Group',
                  onPressed: _createGroup,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}