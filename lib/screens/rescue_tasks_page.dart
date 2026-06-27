import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/admin_state.dart';
import '../widgets/editable_text_list_page.dart';

class RescueTasksPage extends StatefulWidget {
  const RescueTasksPage({super.key});

  @override
  State<RescueTasksPage> createState() => _RescueTasksPageState();
}

class _RescueTasksPageState extends State<RescueTasksPage> {
  @override
  void initState() {
    super.initState();
    // Fetch from backend when page opens
    Future.microtask(() {
      if (mounted) context.read<AdminState>().fetchRescueTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();

    if (admin.isLoadingRescue) {
      return const Center(child: CircularProgressIndicator());
    }

    return EditableTextListPage(
      addCardTitle: '➕ أضف حكم إنقاذ جديد',
      addHint: 'مثلاً: اعمل رقصة لمدة 20 ثانية...',
      listCardTitle: 'أحكام كروت الإنقاذ',
      listIcon: '😈',
      hintText:
          'دي الأحكام اللي التطبيق بيختار منها عشوائياً لما اللاعب يستخدم كرت الإنقاذ.',
      emptyIcon: '😈',
      emptyText: 'مفيش أحكام — أضف من الأعلى',
      items: admin.rescueTasks.map((e) => e['description'] as String).toList(),
      itemStatuses:
          admin.rescueTasks.map((e) => e['status'] as String).toList(),
      //errorMessage: admin.rescueTaskError,
      onAdd: admin.addRescueTask,
      onToggleStatus: admin.toggleRescueTaskStatus,
      onEdit: admin.editRescueTask,
      onDelete: admin.deleteRescueTask,
      editDialogTitle: 'تعديل حكم الإنقاذ',
      deleteDialogTitle: 'حذف الحكم',
    );
  }
}
