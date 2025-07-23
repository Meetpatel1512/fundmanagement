import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fund_management_app/screens/add_members_to_group_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  bool _showFabOptions = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  void _toggleFabOptions() {
    setState(() {
      _showFabOptions = !_showFabOptions;
    });
  }

  // Helper to get icon for category AND its color
  Map<String, dynamic> _getCategoryIconAndColor(String categoryName) {
    return AppConstants.groupCategories
        .firstWhere(
          (cat) => cat['name'] == categoryName,
          orElse: () => {'name': 'Other', 'icon': Icons.category, 'color': AppColors.hintGrey},
        );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserUid = _auth.currentUser?.uid;
    final bool isAdmin = currentUserUid == widget.group.creatorUid;
    final categoryData = _getCategoryIconAndColor(widget.group.groupCategory);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(widget.group.groupName),
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  categoryData['icon'],
                  color: categoryData['color'], // Use the color from categoryData
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  'Category: ${widget.group.groupCategory}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Group Name: ${widget.group.groupName}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Creator: ${widget.group.creatorUid} ${isAdmin ? '(You - Admin)' : ''}',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textDark.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Created On: ${widget.group.createdAt.day}/${widget.group.createdAt.month}/${widget.group.createdAt.year}',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Members:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            if (widget.group.members.isEmpty)
              Text(
                'No members in this group.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.hintGrey,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.group.members.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      '- ${widget.group.members[index]}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: _showFabOptions ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showFabOptions,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    if (_showFabOptions) {
                      _showToast("Add Expense button tapped!", AppColors.accentGreen);
                      _toggleFabOptions();
                      // TODO: Navigate to Add Expense Screen
                    }
                  },
                  label: const Text('Add Expense', style: TextStyle(color: AppColors.textDark)),
                  icon: const Icon(Icons.add_shopping_cart, color: AppColors.textDark),
                  backgroundColor: AppColors.accentGreen,
                  heroTag: 'addExpenseFab',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ),
          if (isAdmin)
            AnimatedOpacity(
              opacity: _showFabOptions ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showFabOptions,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      if (_showFabOptions) {
                        _toggleFabOptions();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMembersToGroupScreen(group: widget.group),
                          ),
                        );
                      }
                    },
                    label: const Text('Add Members', style: TextStyle(color: AppColors.textDark)),
                    icon: const Icon(Icons.person_add, color: AppColors.textDark),
                    backgroundColor: AppColors.accentGreen,
                    heroTag: 'addMembersFab',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
              ),
            ),
          FloatingActionButton(
            onPressed: _toggleFabOptions,
            backgroundColor: AppColors.accentGreen,
            foregroundColor: AppColors.textDark,
            heroTag: 'mainFab',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Icon(
              _showFabOptions ? Icons.close : Icons.add,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}