import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/admin_state.dart';
import '../widgets/editable_text_list_page.dart';

class GiftsPage extends StatefulWidget {
  const GiftsPage({super.key});

  @override
  State<GiftsPage> createState() => _GiftsPageState();
}

class _GiftsPageState extends State<GiftsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AdminState>().fetchGiftLines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();

    if (admin.isLoadingGifts) {
      return const Center(child: CircularProgressIndicator());
    }

    return EditableTextListPage(
      addCardTitle: '➕ أضف مكافأة جديدة',
      addHint: 'مثلاً: هاتوله شاورما 🌯',
      listCardTitle: 'مكافآت الفائز',
      listIcon: '🎁',
      hintText: 'التطبيق بيختار منها عشوائياً عند انتهاء اللعبة.',
      emptyIcon: '🎁',
      emptyText: 'مفيش مكافآت — أضف من الأعلى',
      items: admin.giftLines.map((e) => e['description'] as String).toList(),
      itemStatuses: admin.giftLines.map((e) => e['status'] as String).toList(),
      //errorMessage: admin.giftLineError,
      onAdd: admin.addGiftLine,
      onEdit: admin.editGiftLine,
      onDelete: admin.deleteGiftLine,
      onToggleStatus: admin.toggleGiftStatus,
      editDialogTitle: 'تعديل المكافأة',
      deleteDialogTitle: 'حذف المكافأة',
    );
  }
}