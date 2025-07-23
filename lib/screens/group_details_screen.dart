import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fund_management_app/screens/add_members_to_group_screen.dart';
import 'package:fund_management_app/screens/add_expense_screen.dart'; // Import the new screen
import 'package:fund_management_app/services/auth_service.dart';

class GroupDetailsScreen extends StatefulWidget {
  final GroupModel group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  bool _showFabOptions = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  String? _creatorUsername;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCreatorUsername();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCreatorUsername() async {
    final userModel = await _authService.getUserData(widget.group.creatorUid);
    if (mounted) {
      setState(() {
        _creatorUsername = userModel?.username ?? 'Unknown User';
      });
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

  void _toggleFabOptions() {
    setState(() {
      _showFabOptions = !_showFabOptions;
    });
  }

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
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Bar Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              color: AppColors.primaryBackground,
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  // Category Icon
                  Icon(
                    categoryData['icon'],
                    color: categoryData['color'],
                    size: 38,
                  ),
                  const SizedBox(width: 15),
                  // Group Name and Creator
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.groupName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Created by ${_creatorUsername ?? 'Loading...'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.hintGrey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Delete Icon (remain on the right)
                  IconButton(
                    icon: Icon(
                      Icons.delete_forever,
                      color: isAdmin ? AppColors.errorRed : AppColors.hintGrey.withOpacity(0.5),
                      size: 28,
                    ),
                    onPressed: () {
                      if (isAdmin) {
                        _showToast("Delete group functionality not implemented yet.", AppColors.hintGrey);
                        // TODO: Implement actual delete group functionality here
                      } else {
                        _showToast('You are not the admin of this group and cannot delete it.', AppColors.errorRed);
                      }
                    },
                    tooltip: isAdmin ? 'Delete group' : 'Only group admin can delete',
                  ),
                ],
              ),
            ),
            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: AppColors.textLight,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonShadow.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: AppColors.accentGreen,
                ),
                labelColor: AppColors.textDark,
                unselectedLabelColor: AppColors.hintGrey,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                tabs: const [
                  Tab(text: 'Expense'),
                  Tab(text: 'Summary'),
                ],
              ),
            ),
            // Tab Bar View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Expense Tab Content
                  _buildExpenseTabContent(),
                  // Summary Tab Content
                  _buildSummaryTabContent(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Add Expense Button
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
                      _toggleFabOptions(); // Close options before navigating
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddExpenseScreen(group: widget.group), // Navigate to AddExpenseScreen
                        ),
                      );
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
          // Add Members Button (only visible/tappable if current user is admin)
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
          // Main Plus FAB
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

  // Placeholder content for Expense tab
  Widget _buildExpenseTabContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'July 2025', // Placeholder for current month
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 15),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Icon(Icons.receipt_long, size: 80, color: AppColors.hintGrey.withOpacity(0.5)),
                const SizedBox(height: 20),
                Text(
                  'No expenses yet. Click the + button to add one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.hintGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder content for Summary tab
  Widget _buildSummaryTabContent() {
    return const Center(
      child: Text(
        'Summary Screen Content',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
      ),
    );
  }
}