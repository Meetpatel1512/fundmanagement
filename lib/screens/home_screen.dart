import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fund_management_app/models/group_model.dart';
import 'package:fund_management_app/screens/login_screen.dart';
import 'package:fund_management_app/screens/profile_screen.dart';
import 'package:fund_management_app/screens/create_group_screen.dart';
import 'package:fund_management_app/screens/update_profile_screen.dart';
import 'package:fund_management_app/screens/group_details_screen.dart';
import 'package:fund_management_app/services/auth_service.dart';
import 'package:fund_management_app/services/group_service.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  late final List<Widget> _widgetOptions;
  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      _buildHomeTabContent(),
      const Center(
        child: Text(
          'History Screen Content',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ),
      const ProfileScreen(),
    ];
  }

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'History';
      case 2:
        return 'My Profile';
      default:
        return AppConstants.appName;
    }
  }

  void _navigateToUpdateProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpdateProfileScreen()),
    );
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

  void _deleteGroup(String groupId, String groupName, String creatorUid) async {
    final String? currentUserUid = _firebaseAuth.currentUser?.uid;

    if (currentUserUid != creatorUid) {
      _showToast('You are not the admin of this group and cannot delete it.', AppColors.errorRed);
      return;
    }

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Confirm Deletion', style: TextStyle(color: AppColors.textDark)),
          content: Text('Are you sure you want to delete the group "$groupName"? This action cannot be undone.',
              style: TextStyle(color: AppColors.textDark.withOpacity(0.8))),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.hintGrey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      bool success = await _groupService.deleteGroup(groupId);
      if (success) {
        _showToast('Group "$groupName" deleted successfully!', AppColors.successGreen);
      }
    }
  }

  // Helper to get icon for category AND its color
  Map<String, dynamic> _getCategoryIconAndColor(String categoryName) {
    return AppConstants.groupCategories
        .firstWhere(
          (cat) => cat['name'] == categoryName,
          orElse: () => {'name': 'Other', 'icon': Icons.category, 'color': AppColors.hintGrey}, // Default values
        );
  }

  Widget _buildHomeTabContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CustomButton(
                text: 'Create New Group',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                  );
                },
                isLoading: false,
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'My Groups',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<GroupModel>>(
            stream: _groupService.getUsersGroups(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accentGreen));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.errorRed)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No groups created yet or you are not a member of any group. Click "Create New Group" to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.hintGrey, fontSize: 16),
                  ),
                );
              }

              List<GroupModel> groups = snapshot.data!;
              final String? currentLoggedInUserUid = _firebaseAuth.currentUser?.uid;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  GroupModel group = groups[index];
                  bool isGroupAdmin = currentLoggedInUserUid == group.creatorUid;
                  final categoryData = _getCategoryIconAndColor(group.groupCategory); // Get icon and color

                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    color: AppColors.cardBackground,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailsScreen(group: group),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Category Icon on the left with dynamic color
                            Icon(
                              categoryData['icon'],
                              color: categoryData['color'], // Use the color from categoryData
                              size: 40,
                            ),
                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.groupName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created: ${group.createdAt.day}/${group.createdAt.month}/${group.createdAt.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.hintGrey.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_forever,
                                color: isGroupAdmin ? AppColors.errorRed : AppColors.hintGrey.withOpacity(0.5),
                                size: 28,
                              ),
                              onPressed: () => _deleteGroup(group.groupId, group.groupName, group.creatorUid),
                              tooltip: isGroupAdmin ? 'Delete group' : 'Only group admin can delete',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.textDark, size: 28),
              onPressed: _navigateToUpdateProfile,
            ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.textLight,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              color: AppColors.buttonShadow.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25.0),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: AppColors.accentGreen,
            unselectedItemColor: AppColors.hintGrey,
            onTap: _onItemTapped,
            backgroundColor: AppColors.textLight,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}