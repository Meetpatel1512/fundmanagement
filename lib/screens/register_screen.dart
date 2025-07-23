import 'package:flutter/material.dart';
import 'package:fund_management_app/screens/login_screen.dart';
import 'package:fund_management_app/services/auth_service.dart';
import 'package:fund_management_app/utils/app_messages.dart';
import 'package:fund_management_app/utils/custom_colors.dart';
import 'package:fund_management_app/widgets/custom_button.dart';
import 'package:fund_management_app/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final user = await _authService.registerWithEmailPassword(
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
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    }
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return AppMessages.passwordRequired;
    }
    if (value.length < 8) {
      return AppMessages.passwordTooShort;
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return AppMessages.passwordNoUppercase;
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return AppMessages.passwordNoLowercase;
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return AppMessages.passwordNoDigit;
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return AppMessages.passwordNoSymbol;
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  'Create Your Account',
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
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                            // Already on Register, do nothing or animate
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
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
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Confirm Password',
                    style: TextStyle(
                      color: AppColors.textDark.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  obscureText: true,
                  enabled: true, // Explicitly set enabled to true
                  readOnly: false, // Explicitly set readOnly to false
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppMessages.confirmPasswordRequired;
                    }
                    if (value != _passwordController.text) {
                      return AppMessages.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Register',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 20),
                // Custom message at the bottom, mimicking the image
                const Center(
                  child: Text(
                    'Welcome! Please register to continue.',
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
