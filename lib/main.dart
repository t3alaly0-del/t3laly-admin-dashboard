import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/admin_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/games_list_screen.dart';
import 'screens/dashboard_shell.dart';

void main() {
  runApp(const T3LalyAdminApp());
}

class T3LalyAdminApp extends StatelessWidget {
  const T3LalyAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminState(),
      child: MaterialApp(
        title: 'تعلالى — لوحة الأدمن',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('ar'),
        builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const AdminSplashScreen(),
          '/games': (_) => const GamesListScreen(),
          '/dashboard': (_) => const DashboardShellScreen(),
        },
      ),
    );
  }
}
