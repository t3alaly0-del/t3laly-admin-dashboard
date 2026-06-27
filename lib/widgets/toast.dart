import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(
        child: Text(message, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      width: 360,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      duration: const Duration(seconds: 2),
    ),
  );
}
