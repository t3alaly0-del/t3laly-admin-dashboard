import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot_icon.dart';

class AdminSplashScreen extends StatefulWidget {
  const AdminSplashScreen({super.key});

  @override
  State<AdminSplashScreen> createState() => _AdminSplashScreenState();
}

class _AdminSplashScreenState extends State<AdminSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), _go);
  }

  void _go() {
    if (mounted) Navigator.pushReplacementNamed(context, '/games');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _go,
      child: Scaffold(
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MascotIcon(size: 88),
                  SizedBox(height: 18),
                  Text('T3LALY',
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
                  Text('تعلالى', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.yellow)),
                  SizedBox(height: 18),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text('لوحة تحكم الأدمن — إدارة الألعاب والمحتوى',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13.5, color: Color(0xFFCFE9F7), height: 1.7)),
                  ),
                  SizedBox(height: 40),
                  Text('دوس في أي حتة للدخول', style: TextStyle(fontSize: 12.5, color: Color(0xFFBCDCEE))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
