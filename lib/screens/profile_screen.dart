import 'package:flutter/material.dart';
import 'package:fund_management_app/models/user_model.dart';
import 'package:fund_management_app/screens/login_screen.dart';
import 'package:fund_management_app/screens/update_profile_screen.dart';
import 'package:fund_management_app/services/auth_service.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For toast messages

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetches the current user's data from Firestore
  Future<void> _fetchUserData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      // Reload the Firebase Auth user to get the latest display name and photo URL
      await user.reload();
      final updatedUser = _authService.getCurrentUser(); // Get the reloaded user
      
      final userData = await _authService.getUserData(updatedUser!.uid); // Fetch from Firestore
      setState(() {
        _userModel = userData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Logs out the current user and navigates to the login screen
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

  // Navigates to the UpdateProfileScreen and refreshes data upon return
  void _navigateToUpdateProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UpdateProfileScreen()),
    );
    // Refresh profile data after returning from update screen
    _fetchUserData(); // Call fetch data to update UI
  }

  // Shows a "Coming Soon" message for the privacy policy
  Future<void> _showPrivacyPolicyComingSoon() async {
    Fluttertoast.showToast(
      msg: "Privacy Policy Coming Soon!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppColors.hintGrey,
      textColor: AppColors.textLight,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGreen),
      );
    }

    return Scaffold(
      // Removed AppBar from here, as it's now managed by HomeScreen
      backgroundColor: AppColors.primaryBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The edit icon and "My Profile" title are now handled by HomeScreen's AppBar
            const SizedBox(height: 30), // Adjusted spacing
            // Profile Picture
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.hintGrey.withOpacity(0.3),
              backgroundImage: _userModel?.profileImageUrl != null && _userModel!.profileImageUrl!.isNotEmpty
                  ? NetworkImage(_userModel!.profileImageUrl!) as ImageProvider
                  : null,
            child: _userModel?.profileImageUrl == null || _userModel!.profileImageUrl!.isEmpty
                ? Icon(
                    Icons.person,
                    size: 60,
                    color: AppColors.textDark.withOpacity(0.6),
                  )
                : null,
            ),
            const SizedBox(height: 20),
            // Username
            Text(
              _userModel?.username ?? 'Set Your Username',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            // Email
            Text(
              _userModel?.email ?? 'N/A',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 40),
            // Profile Details Card (simplified to Name and Email only)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 3,
              color: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
                  children: [
                    _buildInfoField('Name', _userModel?.username ?? 'Not Set'),
                    _buildDivider(),
                    _buildInfoField('Email Address', _userModel?.email ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Privacy Policy Button
            _buildProfileOption(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: _showPrivacyPolicyComingSoon,
            ),
            const SizedBox(height: 15),
            // Logout Button
            _buildProfileOption(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _logout,
              isDestructive: true,
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build consistent profile options (for Privacy Policy, Logout)
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? AppColors.errorRed : AppColors.accentGreen,
                size: 28,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: isDestructive ? AppColors.errorRed : AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.hintGrey.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build an info field with label above value, matching the image design
  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.hintGrey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4), // Small space between label and value
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12), // Space after the value before the next field/divider
      ],
    );
  }

  // Helper widget for dividers in the profile card
  Widget _buildDivider() {
    return Divider(
      color: AppColors.borderColor.withOpacity(0.5),
      height: 1,
      thickness: 1,
      indent: 0,
      endIndent: 0,
    );
  }
}
