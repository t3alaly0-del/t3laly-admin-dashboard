import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/admin_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/toast.dart';
import 'package:file_picker/file_picker.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _nameCtrl    = TextEditingController();
  final _emojiCtrl   = TextEditingController();
  final _searchCtrl  = TextEditingController();
  String _searchQuery = '';
  int? _expandedId;

 @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<AdminState>().fetchCategories();
    });
    _searchCtrl.addListener(() =>
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim())
    );
  }

@override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();

    if (admin.isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Add category card ──────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('➕ أضف كاتيجوري',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _LabeledField(
                        label: 'الاسم',
                        child: TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(hintText: 'مثلاً: عاطفي'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: _LabeledField(
                        label: 'إيموجي',
                        child: TextField(
                          controller: _emojiCtrl,
                          maxLength: 2,
                          decoration: const InputDecoration(hintText: '❤️', counterText: ''),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final name = _nameCtrl.text.trim();
                        if (name.isEmpty) {
                          showToast(context, 'اكتب اسم الكاتيجوري ⚠️');
                          return;
                        }
                        final error = await admin.addCategory(name, _emojiCtrl.text);
                        if (!context.mounted) return;
                        if (error != null) {
                          showToast(context, error);
                        } else {
                          _nameCtrl.clear();
                          _emojiCtrl.clear();
                          showToast(context, 'تمت إضافة «$name» ✅');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: AppColors.ink),
                      child: const Text('+ أضف'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Categories list card ───────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🗂️ الكاتيجوريز الحالية',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
                const SizedBox(height: 14),

                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ابحث عن كاتيجوري...',
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF5D8BAB)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 12),

                if (admin.categories.isEmpty)
                  const _EmptyState(icon: '📁', text: 'مفيش كاتيجوريز — أضف من الأعلى')
                else
                  Builder(builder: (context) {
                    final filtered = admin.categories
                        .where((c) => (c['name'] as String).toLowerCase().contains(_searchQuery))
                        .toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('مفيش نتائج 🔍',
                              style: TextStyle(color: Color(0xFF5D8BAB), fontSize: 13.5)),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final cat in filtered) ...[
                          _CategoryRow(
                            cat: cat,
                            isExpanded: _expandedId == cat['id'],
                            onToggleExpand: () => setState(() =>
                                _expandedId = _expandedId == cat['id'] ? null : cat['id']),
                            onEdit: () => _showEditDialog(context, admin, cat),
                            onDelete: () => showDeleteConfirmDialog(
                              context,
                              title: 'حذف الكاتيجوري',
                              body: 'هتحذف «${cat['name']}» وكل الستيكرز بتاعتها؟',
                              onConfirm: () {
                                admin.deleteCategory(cat['id']);
                                showToast(context, 'تم الحذف');
                              },
                            ),
                            onAddSticker: (bytes, fileName, name) => admin.addSticker(cat['id'], bytes, fileName, name),
                            onDeleteSticker: (stickerId) => admin.deleteSticker(cat['id'], stickerId),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, AdminState admin, Map cat) {
    final nameCtrl  = TextEditingController(text: cat['name']);
    final emojiCtrl = TextEditingController(text: cat['emoji']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الكاتيجوري'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _LabeledField(label: 'الاسم',   child: TextField(controller: nameCtrl)),
          const SizedBox(height: 10),
          _LabeledField(label: 'إيموجي', child: TextField(controller: emojiCtrl, maxLength: 2,
              decoration: const InputDecoration(counterText: ''))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final error = await admin.editCategory(
                cat['id'],
                nameCtrl.text.trim(),
                emojiCtrl.text.trim(),
              );
              nav.pop();
              if (context.mounted) {
                if (error != null) {
                  showToast(context, error);
                } else {
                  showToast(context, 'تم التعديل ✅');
                }
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}

// ── Category row with expandable stickers ─
class _CategoryRow extends StatefulWidget {
  final Map<String, dynamic> cat;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Future<void> Function(List<int> bytes, String fileName, String name) onAddSticker;
  final Future<void> Function(int stickerId) onDeleteSticker;

  const _CategoryRow({
    required this.cat,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onEdit,
    required this.onDelete,
    required this.onAddSticker,
    required this.onDeleteSticker,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat      = widget.cat;
    final stickers = List<Map<String, dynamic>>.from(cat['stickers'] ?? []);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEEF7), width: 1.5),
      ),
      child: Column(
        children: [

          // ── Main row ────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(cat['emoji'] ?? '📌', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      Text('${stickers.length} ستيكر',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF5D8BAB))),
                    ],
                  ),
                ),

                // Stickers toggle
                TextButton.icon(
                  onPressed: widget.onToggleExpand,
                  icon: Icon(
                    widget.isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18, color: AppColors.primary,
                  ),
                  label: Text(
                    widget.isExpanded ? 'إخفاء الستيكرز' : 'الستيكرز',
                    style: const TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),

                // Edit
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Text('✏️', style: TextStyle(fontSize: 15)),
                  tooltip: 'تعديل',
                ),

                // Delete
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Text('🗑️', style: TextStyle(fontSize: 15)),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ),

          // ── Stickers panel ──────────────────
          if (widget.isExpanded)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFDDEEF7), width: 1)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

// Add sticker row
Row(
  children: [
    Expanded(
      child: TextField(
        controller: _nameCtrl,
        decoration: const InputDecoration(
          hintText: 'اسم الستيكر (اختياري)',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    ),
    const SizedBox(width: 8),
    ElevatedButton.icon(
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = result.files.first;
        if (file.bytes == null) return;

        await widget.onAddSticker(
          file.bytes!,
          file.name,
          _nameCtrl.text.trim(),
        );
        if (!context.mounted) return;
        _nameCtrl.clear();
        showToast(context, 'تمت إضافة الستيكر ✅');
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white),
      icon: const Icon(Icons.upload, size: 16),
      label: const Text('ارفع صورة'),
    ),
  ],
),

                  const SizedBox(height: 12),

                  // Stickers grid
                  if (stickers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('مفيش ستيكرز — أضف من الأعلى',
                            style: TextStyle(color: Color(0xFF5D8BAB), fontSize: 13)),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: stickers.map((s) => _StickerChip(
                        sticker: s,
                        onDelete: () => widget.onDeleteSticker(s['id']),
                      )).toList(),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Single sticker chip ───────────────────
class _StickerChip extends StatelessWidget {
  final Map<String, dynamic> sticker;
  final VoidCallback onDelete;

  const _StickerChip({required this.sticker, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDEEF7), width: 1.5),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.network(
              sticker['sticker_url'],
              width: 90, height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 90, height: 70,
                color: const Color(0xFFF0F6FA),
                child: const Icon(Icons.broken_image, color: Color(0xFF5D8BAB)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              sticker['sticker_name']?.isNotEmpty == true ? sticker['sticker_name'] : 'ستيكر',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFFBE3DF),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: const Center(
                child: Text('🗑️ حذف', style: TextStyle(fontSize: 11, color: Color(0xFFC73629), fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────
class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF5D8BAB))),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String icon, text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Color(0xFF5D8BAB), fontSize: 13.5)),
        ]),
      ),
    );
  }
}