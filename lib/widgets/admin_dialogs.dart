import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<void> showEditTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String initialValue,
  required ValueChanged<String> onSave,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF5D8BAB))),
            const SizedBox(height: 6),
            TextField(controller: controller, autofocus: true),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isEmpty) return;
              onSave(val);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required VoidCallback onConfirm,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text(body, style: const TextStyle(fontSize: 13.5, color: Color(0xFF5D8BAB))),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white),
            child: const Text('احذف'),
          ),
        ],
      ),
    ),
  );
}
