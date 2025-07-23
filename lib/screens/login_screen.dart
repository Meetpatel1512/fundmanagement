import 'package:flutter/material.dart';
import 'package:fund_management_app/screens/home_screen.dart';
import 'package:fund_management_app/screens/register_screen.dart';
import 'package:fund_management_app/services/auth_service.dart';
import 'package:fund_management_app/utils/app_messages.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:fund_management_app/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberMe = false; // New state variable for "Remember Me"

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final user = await _authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      setState(() {
        _isLoading = false;
      });
      if (user != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController forgotPasswordEmailController = TextEditingController();
    final GlobalKey<FormState> forgotPasswordFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            'Reset Password',
            style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: forgotPasswordFormKey,
            child: CustomTextField(
              controller: forgotPasswordEmailController,
              labelText: 'Enter your email',
              hintText: 'user@example.com',
              keyboardType: TextInputType.emailAddress,
              enabled: true, // Explicitly set enabled to true
              readOnly: false, // Explicitly set readOnly to false for user input
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppMessages.emailRequired;
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return AppMessages.emailIncorrect;
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.errorRed),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CustomButton(
              text: 'Send Reset Link',
              height: 40, // Smaller height for dialog button
              onPressed: () async {
                if (forgotPasswordFormKey.currentState!.validate()) {
                  Navigator.of(context).pop(); // Close the dialog first
                  await _authService.sendPasswordResetEmail(forgotPasswordEmailController.text.trim());
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Step Into the Future\nof Shopping', // Placeholder text from image
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 40),
                // Login/Register Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.textLight,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.buttonShadow.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Already on Login, do nothing or animate
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Email Address',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Your Email',
                  hintText: 'meet@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  enabled: true, // Explicitly set enabled to true
                  readOnly: false, // Explicitly set readOnly to false
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppMessages.emailRequired;
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return AppMessages.emailIncorrect;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Password',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _passwordController,
                  labelText: 'Your Password',
                  obscureText: true,
                  enabled: true, // Explicitly set enabled to true
                  readOnly: false, // Explicitly set readOnly to false
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppMessages.passwordRequired;
                    }
                    // Basic password length validation for login
                    if (value.length < 8) {
                      return AppMessages.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe, // Use the state variable
                          onChanged: (bool? newValue) {
                            setState(() {
                              _rememberMe = newValue ?? false; // Update the state
                            });
                          },
                          activeColor: AppColors.accentGreen,
                          checkColor: AppColors.textDark,
                        ),
                        const Text(
                          'Remember Me',
                          style: TextStyle(color: AppColors.textDark),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _showForgotPasswordDialog, // Call the new dialog
                      child: const Text(
                        'Forgot Password',
                        style: TextStyle(color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Login',
                  onPressed: _login,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Or continue with',
                    style: TextStyle(color: AppColors.hintGrey),
                  ),
                ),
                const SizedBox(height: 20),
                // User explicitly asked NOT to have Google Sign-up button
                // So, no Google button here.
                const SizedBox(height: 20),
                // Custom message at the bottom, mimicking the image
                const Center(
                  child: Text(
                    'Success', // Example message from image
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Center(
                  child: Text(
                    'Logged in with Google successfully!', // Example message from image
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
