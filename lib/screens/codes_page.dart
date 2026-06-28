import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/code_model.dart';
import '../state/admin_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/toast.dart';

class CodesPage extends StatefulWidget {
  const CodesPage({super.key});

  @override
  State<CodesPage> createState() => _CodesPageState();
}

class _CodesPageState extends State<CodesPage> {
  final _manualCtrl = TextEditingController();
  final _countCtrl  = TextEditingController(text: '5');
  int  _length      = 6;
  bool _numericOnly = false;
  bool _generating  = false;
  bool _adding      = false;

  @override
  void dispose() {
    _manualCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Stats ----
        // ---- Stats ----
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(children: [
              Row(children: [
                Expanded(child: _StatBox(value: admin.totalCodes,  label: 'إجمالي', color: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(value: admin.unusedCodes, label: 'غير مستخدمة', color: AppColors.yellowDark)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _StatBox(value: admin.usedCodes,   label: 'مستخدمة', color: const Color(0xFF1E8E4D))),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(value: admin.expiredCodes,label: 'منتهية',  color: AppColors.red)),
              ]),
            ]);
          }
          return Row(children: [
            Expanded(child: _StatBox(value: admin.totalCodes,   label: 'إجمالي الكودات', color: AppColors.primary)),
            const SizedBox(width: 12),
            Expanded(child: _StatBox(value: admin.unusedCodes,  label: 'غير مستخدمة',   color: AppColors.yellowDark)),
            const SizedBox(width: 12),
            Expanded(child: _StatBox(value: admin.usedCodes,    label: 'مستخدمة',       color: const Color(0xFF1E8E4D))),
            const SizedBox(width: 12),
            Expanded(child: _StatBox(value: admin.expiredCodes, label: 'منتهية',         color: AppColors.red)),
          ]);
        }),
        const SizedBox(height: 18),

        // ---- Generate ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚡ توليد كودات جديدة',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    SizedBox(
                      width: 110,
                      child: _Labeled(
                        label: 'عدد الكودات',
                        child: TextField(
                          controller: _countCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: _Labeled(
                        label: 'طول الكود',
                        child: DropdownButtonFormField<int>(
                          initialValue: _length,
                          decoration: const InputDecoration(),
                          items: const [6, 8, 10]
                              .map((n) => DropdownMenuItem(value: n, child: Text('$n خانات')))
                              .toList(),
                          onChanged: (v) => setState(() => _length = v ?? 6),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: _Labeled(
                        label: 'النوع',
                        child: DropdownButtonFormField<bool>(
                          initialValue: _numericOnly,
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(value: false, child: Text('حروف وأرقام')),
                            DropdownMenuItem(value: true,  child: Text('أرقام فقط')),
                          ],
                          onChanged: (v) => setState(() => _numericOnly = v ?? false),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _generating ? null : () => _generate(context, admin),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: AppColors.ink),
                      child: _generating
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('⚡ ولّد'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---- Manual add ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('➕ أضف كود يدوي',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualCtrl,
                        style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1),
                        onSubmitted: (_) => _addManual(context, admin),
                        decoration: const InputDecoration(hintText: 'مثلاً: AB-CDEF-GH'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _adding ? null : () => _addManual(context, admin),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: AppColors.ink),
                      child: _adding
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('+ أضف'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ---- List ----
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔑 كل الكودات',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _FilterChip(label: 'الكل',         value: CodeFilter.all,     current: admin.codeFilter, onTap: admin.setCodeFilter),
                          _FilterChip(label: 'غير مستخدمة', value: CodeFilter.unused,   current: admin.codeFilter, onTap: admin.setCodeFilter),
                          _FilterChip(label: 'مستخدمة',     value: CodeFilter.used,     current: admin.codeFilter, onTap: admin.setCodeFilter),
                          _FilterChip(label: 'منتهية',      value: CodeFilter.expired,  current: admin.codeFilter, onTap: admin.setCodeFilter),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDeleteUsed(context, admin),
                      icon: const Text('🗑️', style: TextStyle(fontSize: 13)),
                      label: const Text('احذف المستخدمة', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (admin.isLoadingCodes)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ))
                else if (admin.codesError != null)
                  Center(
                    child: Column(children: [
                      const Icon(Icons.wifi_off_rounded, size: 36, color: Color(0xFF5D8BAB)),
                      const SizedBox(height: 8),
                      Text(admin.codesError!, style: const TextStyle(color: Color(0xFF5D8BAB))),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          final id = int.tryParse(admin.selectedPack?.id ?? '');
                          if (id != null) admin.fetchCodes(id);
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ]),
                  )
                else if (admin.filteredCodes().isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Column(children: [
                        Text('🔑', style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text('مفيش كودات — ولّد أو أضف من الأعلى',
                            style: TextStyle(color: Color(0xFF5D8BAB), fontSize: 13.5)),
                      ]),
                    ),
                  )
                else
                  for (final code in admin.filteredCodes())
                    _CodeRow(code: code, admin: admin),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generate(BuildContext context, AdminState admin) async {
    final count = int.tryParse(_countCtrl.text) ?? 5;
    setState(() => _generating = true);
    try {
      final added = await admin.generateCodes(
          count: count, length: _length, numericOnly: _numericOnly);
      if (context.mounted) showToast(context, 'تم توليد $added كود جديد ✅');
    } catch (e) {
      if (context.mounted) showToast(context, 'فشل التوليد ❌');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _addManual(BuildContext context, AdminState admin) async {
    final val = _manualCtrl.text.trim();
    if (val.isEmpty) { showToast(context, 'اكتب الكود ⚠️'); return; }
    setState(() => _adding = true);
    try {
      await admin.addManualCode(val);
      _manualCtrl.clear();
      if (context.mounted) showToast(context, 'تمت إضافة الكود ✅');
    } catch (e) {
      if (context.mounted) showToast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _confirmDeleteUsed(BuildContext context, AdminState admin) {
    final n = admin.usedCodes;
    if (n == 0) { showToast(context, 'مفيش كودات مستخدمة ⚠️'); return; }
    showDeleteConfirmDialog(
      context,
      title: 'حذف الكودات المستخدمة',
      body: 'هتحذف $n كود مستخدم؟',
      onConfirm: () async {
        try {
          final deleted = await admin.deleteUsedCodes();
          if (context.mounted) showToast(context, 'تم حذف $deleted كود مستخدم 🗑️');
        } catch (_) {
          if (context.mounted) showToast(context, 'فشل الحذف ❌');
        }
      },
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: Color(0xFF5D8BAB), fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF5D8BAB))),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final CodeFilter value;
  final CodeFilter current;
  final ValueChanged<CodeFilter> onTap;
  const _FilterChip(
      {required this.label,
      required this.value,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return OutlinedButton(
      onPressed: () => onTap(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: active ? AppColors.primary : Colors.white,
        foregroundColor: active ? Colors.white : const Color(0xFF5D8BAB),
        side: BorderSide(color: active ? AppColors.primary : const Color(0xFFC8E2F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
    );
  }
}

class _CodeRow extends StatelessWidget {
  final CodeModel code;
  final AdminState admin;
  const _CodeRow({required this.code, required this.admin});

  @override
  Widget build(BuildContext context) {
    final status = code.status;
    const badgeColors = {
      'unused':  Color(0xFFFFFBE7),
      'used':    Color(0xFFE3F6EA),
      'expired': Color(0xFFFBE3DF),
    };
    const badgeTextColors = {
      'unused':  Color(0xFFA07C00),
      'used':    Color(0xFF1E8E4D),
      'expired': AppColors.redDark,
    };
    const badgeLabels = {
      'unused':  'غير مستخدم',
      'used':    'مستخدم ✅',
      'expired': 'منتهي الصلاحية',
    };

    final meta = StringBuffer();
    if (code.used && code.usedBy.isNotEmpty) meta.write('استخدمه: ${code.usedBy} · ');
    if (code.activatedAt != null) meta.write('فُعّل: ${_fmtDate(code.activatedAt!)}');
    if (code.expiry != null) {
      if (meta.isNotEmpty) meta.write(' · ');
      meta.write('ينتهي: ${_fmtDate(code.expiry!)}');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDEEF7), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code.code,
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppColors.ink)),
                if (meta.isNotEmpty)
                  Text(meta.toString(),
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF5D8BAB), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: badgeColors[status],
                borderRadius: BorderRadius.circular(999)),
            child: Text(badgeLabels[status]!,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: badgeTextColors[status])),
          ),
          const SizedBox(width: 6),
          if (!code.isExpired)
            IconButton(
              tooltip: code.used ? 'ارجع لغير مستخدم' : 'وضّح كمستخدم',
              onPressed: () async {
                try {
                  code.used
                      ? await admin.markCodeUnused(code.id)
                      : await admin.markCodeUsed(code.id);
                } catch (_) {
                  if (context.mounted) showToast(context, 'فشل التحديث ❌');
                }
              },
              icon: Text(code.used ? '↩️' : '✅',
                  style: const TextStyle(fontSize: 15)),
            ),
          IconButton(
            tooltip: code.expiry != null ? 'تاريخ الانتهاء: ${_fmtDate(code.expiry!)}' : 'تحديد تاريخ انتهاء',
            onPressed: () => _handleExpiry(context, code, admin),
            icon: Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: code.expiry != null ? AppColors.red : const Color(0xFF5D8BAB),
            ),
          ),
          IconButton(
            tooltip: 'نسخ الكود',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code.code));
              showToast(context, 'تم نسخ الكود: ${code.code} 📋');
            },
            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF5D8BAB)),
          ),
          IconButton(
            tooltip: 'احذف',
            onPressed: () => showDeleteConfirmDialog(
              context,
              title: 'حذف الكود',
              body: 'هتحذف الكود ${code.code}؟',
              onConfirm: () async {
                try {
                  await admin.deleteCode(code.id);
                  if (context.mounted) showToast(context, 'تم الحذف 🗑️');
                } catch (_) {
                  if (context.mounted) showToast(context, 'فشل الحذف ❌');
                }
              },
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExpiry(BuildContext context, CodeModel code, AdminState admin) async {
    if (code.expiry != null) {
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تاريخ الانتهاء', textDirection: TextDirection.rtl),
          content: Text('ينتهي في: ${_fmtDate(code.expiry!)}',
              textDirection: TextDirection.rtl),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'clear'),
              child: const Text('إزالة التاريخ',
                  style: TextStyle(color: AppColors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'change'),
              child: const Text('تغيير'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
      if (action == 'clear' && context.mounted) {
        try {
          await admin.setCodeExpiry(code.id, null);
          if (context.mounted) showToast(context, 'تم إزالة التاريخ ✅');
        } catch (_) {
          if (context.mounted) showToast(context, 'فشل ❌');
        }
      } else if (action == 'change' && context.mounted) {
        await _pickDate(context, code, admin);
      }
    } else {
      await _pickDate(context, code, admin);
    }
  }

  Future<void> _pickDate(BuildContext context, CodeModel code, AdminState admin) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: code.expiry ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && context.mounted) {
      try {
        await admin.setCodeExpiry(code.id, picked);
        if (context.mounted) showToast(context, 'تم تحديد تاريخ الانتهاء ✅');
      } catch (_) {
        if (context.mounted) showToast(context, 'فشل ❌');
      }
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
