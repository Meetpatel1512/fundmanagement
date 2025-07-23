import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fund_management_app/screens/login_screen.dart';
import 'package:fund_management_app/utils/app_constants.dart';
import 'package:fund_management_app/utils/custom_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(
      const Duration(seconds: AppConstants.splashScreenDurationSeconds),
      () {},
    );
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your app logo here
            Image.asset(
              'assets/logo.png', // Make sure to add a logo.png in your assets folder
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            Text(
              ('My Profile'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 40),
            SpinKitFadingCircle(color: AppColors.accentGreen, size: 50.0),
          ],
        ),
      ),
    );
  }
}
