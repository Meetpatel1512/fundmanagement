import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/services/group_service.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:fund_management_app/widgets/custom_text_field.dart';

class AddMembersToGroupScreen extends StatefulWidget {
  final GroupModel group;

  const AddMembersToGroupScreen({super.key, required this.group});

  @override
  State<AddMembersToGroupScreen> createState() => _AddMembersToGroupScreenState();
}

class _AddMembersToGroupScreenState extends State<AddMembersToGroupScreen> {
  final TextEditingController _memberEmailController = TextEditingController();
  final List<String> _currentSessionMembers = []; // Members added in this session
  final GroupService _groupService = GroupService();
  bool _isAddingMember = false;
  bool _isSavingChanges = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing members for display, but allow adding new ones.
    // The actual update will merge these.
    _currentSessionMembers.addAll(widget.group.members);
  }

  void _addMemberToSession() {
    String email = _memberEmailController.text.trim();
    if (email.isEmpty) {
      _showToast("Email address cannot be empty.", AppColors.errorRed);
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showToast("Please enter a valid email address.", AppColors.errorRed);
      return;
    }

    if (_currentSessionMembers.contains(email)) {
      _showToast("This email is already in the group.", AppColors.hintGrey);
      _memberEmailController.clear();
      return;
    }

    setState(() {
      _isAddingMember = true;
    });

    // For now, just add to session list. Actual Firestore update is on "Save"
    setState(() {
      _currentSessionMembers.add(email);
      _memberEmailController.clear();
      _isAddingMember = false;
    });
    _showToast("$email added for this session.", AppColors.successGreen);
  }

  void _removeMemberFromSession(int index) {
    setState(() {
      String removedEmail = _currentSessionMembers.removeAt(index);
      _showToast("$removedEmail removed from session.", AppColors.hintGrey);
    });
  }

  Future<void> _saveMembersToGroup() async {
    setState(() {
      _isSavingChanges = true;
    });

    // Filter out duplicates that might exist if the initial list contained them
    // and consolidate with newly added members.
    // Use a Set to ensure uniqueness, then convert back to List.
    Set<String> uniqueMembers = Set<String>.from(widget.group.members);
    uniqueMembers.addAll(_currentSessionMembers);

    bool success = await _groupService.updateGroupMembers(
      widget.group.groupId,
      uniqueMembers.toList(),
    );

    setState(() {
      _isSavingChanges = false;
    });

    if (success && mounted) {
      _showToast("Group members updated successfully!", AppColors.successGreen);
      Navigator.pop(context); // Go back to GroupDetailsScreen
    } else {
      _showToast("Failed to update group members.", AppColors.errorRed);
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
    _memberEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Add Members to ${widget.group.groupName}'),
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add New Member by Email',
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
                        // We do immediate validation in _addMemberToSession()
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  CustomButton(
                    text: 'Add',
                    height: 50,
                    width: 80,
                    onPressed: _addMemberToSession,
                    isLoading: _isAddingMember,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Current Group Members:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              if (_currentSessionMembers.isEmpty)
                Text(
                  'No members added yet.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.hintGrey,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentSessionMembers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _currentSessionMembers[index],
                                style: const TextStyle(color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeMemberFromSession(index),
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
                ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Save Changes',
                onPressed: _saveMembersToGroup,
                isLoading: _isSavingChanges,
              ),
            ],
          ),
        ),
      ),
    );
  }
}