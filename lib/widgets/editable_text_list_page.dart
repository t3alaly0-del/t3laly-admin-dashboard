import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admin_dialogs.dart';
import 'toast.dart';

/// A generic "add a line of text / list of lines with edit+delete" card pair
/// — used identically by the Rescue Tasks page and the Gifts page in the
/// prototype (`renderRescue`/`renderGifts` were near-duplicates of each
/// other there; here they share one implementation).
class EditableTextListPage extends StatefulWidget {
  final String addCardTitle;
  final String addHint;
  final String listCardTitle;
  final String listIcon;
  final String hintText;
  final String emptyIcon;
  final String emptyText;
  final List<String> items;
  final Future<String?> Function(String text) onAdd;
  final Future<String?> Function(int index, String newText) onEdit;
  final void Function(int index) onDelete;
  final String editDialogTitle;
  final String deleteDialogTitle;
  //final String? errorMessage;
  final Future<void> Function(int index)? onToggleStatus;
  final List<String>? itemStatuses;

  const EditableTextListPage({
    super.key,
    required this.addCardTitle,
    required this.addHint,
    required this.listCardTitle,
    required this.listIcon,
    required this.hintText,
    required this.emptyIcon,
    required this.emptyText,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.editDialogTitle,
    required this.deleteDialogTitle,
    //this.errorMessage,
    this.onToggleStatus,
    this.itemStatuses,
  });

  @override
  State<EditableTextListPage> createState() => _EditableTextListPageState();
}

class _EditableTextListPageState extends State<EditableTextListPage> {
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
          () => _searchQuery = _searchController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _add() async {
    final val = _controller.text.trim();
    if (val.isEmpty) {
      showToast(context, 'اكتب النص الأول ⚠️');
      return;
    }
    final error = await widget.onAdd(val);
    if (!mounted) return;
    if (error != null) {
      showToast(context, error);
    } else {
      _controller.clear();
      showToast(context, 'تمت الإضافة ✅');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.addCardTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.ink)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _add(),
                        decoration: InputDecoration(hintText: widget.addHint),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _add,
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('${widget.listIcon} ',
                      style: const TextStyle(fontSize: 18)),
                  Text(widget.listCardTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.ink)),
                ]),
                const SizedBox(height: 8),
                Text(widget.hintText,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF5D8BAB), height: 1.6)),
                const SizedBox(height: 14),

// Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'ابحث...',
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF5D8BAB)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 12),

// Filtered list
                Builder(builder: (context) {
                  final filtered = widget.items
                      .asMap()
                      .entries
                      .where(
                          (e) => e.value.toLowerCase().contains(_searchQuery))
                      .toList();

                  if (widget.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(children: [
                          Text(widget.emptyIcon,
                              style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(widget.emptyText,
                              style: const TextStyle(
                                  color: Color(0xFF5D8BAB), fontSize: 13.5)),
                        ]),
                      ),
                    );
                  }

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(30),
                        child: Text('مفيش نتائج 🔍',
                            style: TextStyle(
                                color: Color(0xFF5D8BAB), fontSize: 13.5)),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 400,
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final i = filtered[idx].key; // original index
                          final text = filtered[idx].value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 7),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FBFD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFDDEEF7), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Text('☰',
                                    style: TextStyle(
                                        color: Color(0xFFC8E2F0),
                                        fontSize: 14)),
                                const SizedBox(width: 8),
                                Expanded(
  child: GestureDetector(
    onTap: () => showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('النص الكامل', textDirection: TextDirection.rtl),
        content: Text(text,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontSize: 14, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    ),
    child: Text(text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5)),
  ),
),
                                if (widget.onToggleStatus != null &&
                                    widget.itemStatuses != null)
                                  GestureDetector(
                                    onTap: () => widget.onToggleStatus!(i),
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: widget.itemStatuses![idx] == 'on'
                                            ? const Color(0xFFE3F6EA)
                                            : const Color(0xFFFBE3DF),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        widget.itemStatuses![idx] == 'on'
                                            ? 'شغال ✅'
                                            : 'موقف ❌',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color:
                                              widget.itemStatuses![idx] == 'on'
                                                  ? const Color(0xFF1E8E4D)
                                                  : const Color(0xFFC73629),
                                        ),
                                      ),
                                    ),
                                  ),
                                IconButton(
                                  onPressed: () => showEditTextDialog(
                                    context,
                                    title: widget.editDialogTitle,
                                    label: 'النص',
                                    initialValue: text,
                                    onSave: (val) async {
                                      final error = await widget.onEdit(i, val);
                                      if (context.mounted) {
                                        if (error != null) {
                                          showToast(context, error);
                                        } else {
                                          showToast(context, 'تم التعديل ✅');
                                        }
                                      }
                                    },
                                  ),
                                  icon: const Text('✏️',
                                      style: TextStyle(fontSize: 15)),
                                ),
                                IconButton(
                                  onPressed: () => showDeleteConfirmDialog(
                                    context,
                                    title: widget.deleteDialogTitle,
                                    body:
                                        'هتحذف: "${text.length > 40 ? '${text.substring(0, 40)}...' : text}"؟',
                                    onConfirm: () {
                                      widget.onDelete(i);
                                      showToast(context, 'تم الحذف');
                                    },
                                  ),
                                  icon: const Text('🗑️',
                                      style: TextStyle(fontSize: 15)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
