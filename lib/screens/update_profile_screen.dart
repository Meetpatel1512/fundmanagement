import 'dart:io'; // For File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // For picking images
import 'package:fund_management_app/services/auth_service.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:fund_management_app/widgets/custom_text_field.dart';
import 'package:fluttertoast/fluttertoast.dart'; // For toast messages

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  File? _pickedImage;
  bool _isLoading = false;
  String? _currentProfileImageUrl; // To display existing image

  @override
  void initState() {
    super.initState();
    _loadCurrentProfileData();
  }

  // Loads the current user's profile data to pre-fill the fields
  Future<void> _loadCurrentProfileData() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (userData != null) {
        setState(() {
          _usernameController.text = userData.username ?? '';
          _currentProfileImageUrl = userData.profileImageUrl;
        });
      }
    }
  }

  // Allows the user to pick an image from the gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = File(image.path);
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to pick image: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: AppColors.errorRed,
        textColor: AppColors.textLight,
      );
    }
  }

  // Updates the user's profile in Firebase
  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Only update username if it has changed
      String? usernameToUpdate = _usernameController.text.trim();
      // Fetch the current user's display name from Firebase Auth directly
      // This is more reliable for checking if the display name has changed
      final currentAuthUser = _authService.getCurrentUser();
      if (usernameToUpdate == (currentAuthUser?.displayName ?? '')) {
        usernameToUpdate = null; // No change, so don't send to update
      }


      await _authService.updateUserProfile(
        username: usernameToUpdate,
        profileImageFile: _pickedImage,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context); // Go back to profile screen after update
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Update Profile'),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: AppColors.hintGrey.withOpacity(0.3),
                    // Display picked image, then current network image, then a default icon
                    backgroundImage: _pickedImage != null
                        ? FileImage(_pickedImage!) as ImageProvider
                        : (_currentProfileImageUrl != null && _currentProfileImageUrl!.isNotEmpty
                            ? NetworkImage(_currentProfileImageUrl!)
                            : null),
                    child: _pickedImage == null && (_currentProfileImageUrl == null || _currentProfileImageUrl!.isEmpty)
                        ? Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: AppColors.textDark.withOpacity(0.6),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text(
                    'Change Profile Picture',
                    style: TextStyle(color: AppColors.accentGreen, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Username',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _usernameController,
                  labelText: 'Your Username',
                  hintText: 'e.g., JohnDoe',
                  enabled: true, // Explicitly set to true
                  readOnly: false, // Explicitly set to false as it's editable
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username cannot be empty.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email (Permanent)',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: TextEditingController(text: _authService.getCurrentUser()?.email ?? 'N/A'),
                  labelText: 'Your Email',
                  enabled: false, // Visually disabled
                  readOnly: true, // Prevents keyboard from appearing and any interaction
                ),
                const SizedBox(height: 40),
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _updateProfile,
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
