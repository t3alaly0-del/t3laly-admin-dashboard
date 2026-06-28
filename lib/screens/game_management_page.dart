import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/admin_state.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_dialogs.dart';
import '../widgets/toast.dart';

class GameManagementPage extends StatefulWidget {
  const GameManagementPage({super.key});

  @override
  State<GameManagementPage> createState() => _GameManagementPageState();
}

class _GameManagementPageState extends State<GameManagementPage> {
  final _nameCtrl       = TextEditingController();
  final _minPlayersCtrl = TextEditingController();
  String _status        = 'open';
  bool _infoChanged     = false;

  void _applyInfo(Map<String, dynamic> info) {
    _nameCtrl.text       = info['name'] ?? '';
    _minPlayersCtrl.text = (info['min_players'] ?? 3).toString();
    _status              = info['status'] ?? 'open';
    _infoChanged         = false;
  }

@override
  void initState() {
    super.initState();

    final state = context.read<AdminState>();

    // Apply cached data immediately if available (no flicker)
    if (state.gameInfo.isNotEmpty) {
      _applyInfo(state.gameInfo);
    }

    // Always fetch fresh from server in background
    Future.microtask(() async {
      await state.fetchGameInfo();
      if (!mounted) return;
      final info = context.read<AdminState>().gameInfo;
      if (info.isNotEmpty) {
        setState(() => _applyInfo(info));
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minPlayersCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();

    if (admin.isLoadingGame) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Game info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎮 معلومات اللعبة',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
                const SizedBox(height: 16),

                const _Label('اسم اللعبة'),
                TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => setState(() => _infoChanged = true),
                  decoration: InputDecoration(
                    hintText: _nameCtrl.text.isEmpty ? 'مثلاً: تعلالى' : null,
                    suffixIcon: _nameCtrl.text.isNotEmpty
                        ? const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF5D8BAB))
                        : null,
                  ),
                ),
                const SizedBox(height: 14),

                const _Label('الحالة'),
                Row(children: [
                  _StatusChip(
                    label: 'مفتوحة ✅',
                    value: 'open',
                    selected: _status == 'open',
                    color: const Color(0xFF1E8E4D),
                    bg: const Color(0xFFE3F6EA),
                    onTap: () => setState(() { _status = 'open'; _infoChanged = true; }),
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: 'مجمّدة ❄️',
                    value: 'freeze',
                    selected: _status == 'freeze',
                    color: const Color(0xFF1565C0),
                    bg: const Color(0xFFE3F2FD),
                    onTap: () => setState(() { _status = 'freeze'; _infoChanged = true; }),
                  ),
                  const SizedBox(width: 10),
                  _StatusChip(
                    label: 'قريباً 🔜',
                    value: 'coming_soon',
                    selected: _status == 'coming_soon',
                    color: const Color(0xFFF57F17),
                    bg: const Color(0xFFFFF8E1),
                    onTap: () => setState(() { _status = 'coming_soon'; _infoChanged = true; }),
                  ),
                ]),
                const SizedBox(height: 14),

                const _Label('أقل عدد لاعبين'),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _minPlayersCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _infoChanged = true),
                    decoration: const InputDecoration(hintText: '3'),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: !_infoChanged ? null : () async {
                    final error = await admin.saveGameInfo(
                      name: _nameCtrl.text.trim(),
                      status: _status,
                      minPlayers: int.tryParse(_minPlayersCtrl.text) ?? 3,
                    );
                    if (!context.mounted) return;
                    if (error != null) {
                      showToast(context, error);
                    } else {
                      setState(() => _infoChanged = false);
                      showToast(context, 'تم الحفظ ✅');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.ink),
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text(' احفظ'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Cards card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    const Text('🃏 أنواع الكروت',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _showAddCardDialog(context, admin),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ أضف كارت'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'كل نوع كارت ليه اسم ونقاط وعدد وشرح مفصل ومختصر.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF5D8BAB), height: 1.6),
                ),

                if (admin.gameCards.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  // Summary stats row
                  _CardsSummaryBar(cards: admin.gameCards),
                ],

                const SizedBox(height: 16),

                if (admin.gameCards.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(
                              color: const Color(0xFF6FC9EC).withValues(alpha: .15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            )],
                          ),
                          child: const Center(child: Text('🃏', style: TextStyle(fontSize: 28))),
                        ),
                        const SizedBox(height: 14),
                        const Text('مفيش كروت لحد دلوقتي',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5D8BAB),
                            )),
                        const SizedBox(height: 6),
                        const Text('اضغط «+ أضف كارت» عشان تبدأ',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF8BAFC4))),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final tileWidth = w < 480
                        ? w
                        : w < 750
                            ? (w - 14) / 2
                            : 210.0;
                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: admin.gameCards.map((card) => SizedBox(
                        width: tileWidth,
                        height: 268,
                        child: _CardTile(
                          card: card,
                          onEdit: () => _showEditCardDialog(context, admin, card),
                          onDelete: () => showDeleteConfirmDialog(
                            context,
                            title: 'حذف الكارت',
                            body: 'هتحذف كارت «${card['name']}»؟',
                            onConfirm: () {
                              admin.deleteGameCard(card['id']);
                              showToast(context, 'تم الحذف');
                            },
                          ),
                        ),
                      )).toList(),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _ensureCardMeta(AdminState admin) async {
    if (admin.cardTypes.isEmpty || admin.judgeCategories.isEmpty) {
      await admin.fetchCardTypesAndJudgeCategories();
    }
  }

  // ── Add card dialog
  void _showAddCardDialog(BuildContext context, AdminState admin) {
    final nameCtrl     = TextEditingController();
    final scoreCtrl    = TextEditingController(text: '1.0');
    final quantityCtrl = TextEditingController(text: '10');
    final detailedCtrl = TextEditingController();
    final abstractCtrl = TextEditingController();
    final emojiCtrl    = TextEditingController(text: '🃏');
    bool isOneTime           = false;
    int? selectedCardTypeId;
    int? selectedJudgeCatId;

    _ensureCardMeta(admin);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cardTypes      = admin.cardTypes;
          final judgeCats      = admin.judgeCategories;
          final selectedType   = cardTypes.firstWhere(
            (t) => t['id'] == selectedCardTypeId, orElse: () => {},
          );
          final isJudgeType    = selectedType['name'] == 'judge';

          return AlertDialog(
            title: const Text('➕ أضف نوع كارت جديد'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  SizedBox(
                    width: 70,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const _Label('إيموجي'),
                      TextField(
                        controller: emojiCtrl,
                        maxLength: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                        decoration: const InputDecoration(counterText: '', hintText: '🃏'),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _Label('اسم الكارت'),
                    TextField(controller: nameCtrl,
                        decoration: const InputDecoration(hintText: 'مثلاً: احكيلي')),
                  ])),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _Label('النقاط'),
                    TextField(controller: scoreCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '1.0')),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _Label('العدد'),
                    TextField(controller: quantityCtrl, keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '10')),
                  ])),
                ]),
                const SizedBox(height: 10),
                const _Label('الوصف المختصر'),
                TextField(controller: abstractCtrl,
                    decoration: const InputDecoration(hintText: 'مثلاً: غنّى الأغنية')),
                const SizedBox(height: 10),
                const _Label('الوصف المفصل'),
                TextField(controller: detailedCtrl, maxLines: 3,
                    decoration: const InputDecoration(hintText: 'اختار الأغنية اللي في ظهر الكارت...')),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _Label('مرة واحدة فقط'),
                    Switch(
                      value: isOneTime,
                      onChanged: (v) => setDialogState(() => isOneTime = v),
                      activeThumbColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _Label('نوع الكارت'),
                _Dropdown<int>(
                  value: selectedCardTypeId,
                  hint: 'اختار النوع',
                  items: cardTypes.map((t) => DropdownMenuItem<int>(
                    value: t['id'] as int,
                    child: Text(t['name'] as String),
                  )).toList(),
                  onChanged: (v) => setDialogState(() {
                    selectedCardTypeId = v;
                    selectedJudgeCatId = null;
                  }),
                ),
                if (isJudgeType) ...[
                  const SizedBox(height: 10),
                  const _Label('فئة المحكم'),
                  _Dropdown<int>(
                    value: selectedJudgeCatId,
                    hint: 'اختار فئة المحكم',
                    items: judgeCats.map((jc) => DropdownMenuItem<int>(
                      value: jc['id'] as int,
                      child: Text(jc['name'] as String),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedJudgeCatId = v),
                  ),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) { showToast(context, 'اكتب اسم الكارت ⚠️'); return; }
                  if (isJudgeType && selectedJudgeCatId == null) {
                    showToast(context, 'اختار فئة المحكم ⚠️'); return;
                  }
                  final duplicate = admin.gameCards.any(
                    (c) => c['name'].toString().trim().toLowerCase() == name.toLowerCase(),
                  );
                  if (duplicate) { showToast(context, 'في كارت بنفس الاسم بالفعل ⚠️'); return; }
                  final nav = Navigator.of(ctx);
                  final error = await admin.addGameCard(
                    name: name,
                    score: double.tryParse(scoreCtrl.text) ?? 1.0,
                    quantity: int.tryParse(quantityCtrl.text) ?? 10,
                    detailedDesc: detailedCtrl.text.trim(),
                    abstractDesc: abstractCtrl.text.trim(),
                    emoji: emojiCtrl.text.trim().isEmpty ? '🃏' : emojiCtrl.text.trim(),
                    isOneTime: isOneTime,
                    cardTypeId: selectedCardTypeId,
                    judgeCategoriesId: isJudgeType ? selectedJudgeCatId : null,
                  );
                  nav.pop();
                  if (context.mounted) showToast(context, error ?? 'تمت الإضافة ✅');
                },
                child: const Text('أضف'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Edit card dialog
  void _showEditCardDialog(BuildContext context, AdminState admin, Map card) {
    final nameCtrl     = TextEditingController(text: card['name']);
    final scoreCtrl    = TextEditingController(text: card['score'].toString());
    final quantityCtrl = TextEditingController(text: card['quantity'].toString());
    final detailedCtrl = TextEditingController(text: card['detailed_desc'] ?? '');
    final abstractCtrl = TextEditingController(text: card['abstract_desc'] ?? '');
    final emojiCtrl    = TextEditingController(text: card['emoji'] ?? '🃏');
    bool isOneTime           = card['is_one_time'] as bool? ?? false;
    int? selectedCardTypeId  = card['card_type_id'] as int?;
    int? selectedJudgeCatId  = card['judge_categories_id'] as int?;

    _ensureCardMeta(admin);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cardTypes    = admin.cardTypes;
          final judgeCats    = admin.judgeCategories;
          final selectedType = cardTypes.firstWhere(
            (t) => t['id'] == selectedCardTypeId, orElse: () => {},
          );
          final isJudgeType  = selectedType['name'] == 'judge';

          return AlertDialog(
            title: const Text('✏️ تعديل الكارت'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  SizedBox(
                    width: 70,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const _Label('إيموجي'),
                      TextField(
                        controller: emojiCtrl,
                        maxLength: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22),
                        decoration: const InputDecoration(counterText: ''),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _Label('اسم الكارت'),
                    TextField(controller: nameCtrl),
                  ])),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _Label('النقاط'),
                    TextField(controller: scoreCtrl, keyboardType: TextInputType.number),
                  ])),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _Label('العدد'),
                    TextField(controller: quantityCtrl, keyboardType: TextInputType.number),
                  ])),
                ]),
                const SizedBox(height: 10),
                const _Label('الوصف المختصر'),
                TextField(controller: abstractCtrl),
                const SizedBox(height: 10),
                const _Label('الوصف المفصل'),
                TextField(controller: detailedCtrl, maxLines: 3),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _Label('مرة واحدة فقط'),
                    Switch(
                      value: isOneTime,
                      onChanged: (v) => setDialogState(() => isOneTime = v),
                      activeThumbColor: AppColors.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const _Label('نوع الكارت'),
                _Dropdown<int>(
                  value: selectedCardTypeId,
                  hint: 'اختار النوع',
                  items: cardTypes.map((t) => DropdownMenuItem<int>(
                    value: t['id'] as int,
                    child: Text(t['name'] as String),
                  )).toList(),
                  onChanged: (v) => setDialogState(() {
                    selectedCardTypeId = v;
                    selectedJudgeCatId = null;
                  }),
                ),
                if (isJudgeType) ...[
                  const SizedBox(height: 10),
                  const _Label('فئة المحكم'),
                  _Dropdown<int>(
                    value: selectedJudgeCatId,
                    hint: 'اختار فئة المحكم',
                    items: judgeCats.map((jc) => DropdownMenuItem<int>(
                      value: jc['id'] as int,
                      child: Text(jc['name'] as String),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedJudgeCatId = v),
                  ),
                ],
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (isJudgeType && selectedJudgeCatId == null) {
                    showToast(context, 'اختار فئة المحكم ⚠️'); return;
                  }
                  final duplicate = admin.gameCards.any(
                    (c) => c['id'] != card['id'] &&
                        c['name'].toString().trim().toLowerCase() == name.toLowerCase(),
                  );
                  if (duplicate) { showToast(context, 'في كارت بنفس الاسم بالفعل ⚠️'); return; }
                  final nav = Navigator.of(ctx);
                  final error = await admin.updateGameCard(
                    id: card['id'],
                    name: name,
                    score: double.tryParse(scoreCtrl.text) ?? 1.0,
                    quantity: int.tryParse(quantityCtrl.text) ?? 10,
                    detailedDesc: detailedCtrl.text.trim(),
                    abstractDesc: abstractCtrl.text.trim(),
                    emoji: emojiCtrl.text.trim().isEmpty ? '🃏' : emojiCtrl.text.trim(),
                    isOneTime: isOneTime,
                    cardTypeId: selectedCardTypeId,
                    judgeCategoriesId: isJudgeType ? selectedJudgeCatId : null,
                  );
                  nav.pop();
                  if (context.mounted) showToast(context, error ?? 'تم التعديل ✅');
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary stats bar
class _CardsSummaryBar extends StatelessWidget {
  final List<dynamic> cards;
  const _CardsSummaryBar({required this.cards});

  @override
  Widget build(BuildContext context) {
    final totalQty = cards.fold<int>(
      0, (sum, c) => sum + ((c['quantity'] as num?)?.toInt() ?? 0));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6FC9EC).withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          const Text('🃏', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Text(
            '${cards.length} ${cards.length == 1 ? 'نوع' : 'أنواع'}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0E5685),
            ),
          ),
          const SizedBox(width: 6),
          const Text('·', style: TextStyle(color: Color(0xFF6FC9EC), fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            '$totalQty كارت إجمالي',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5D8BAB),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card tile widget (fixed-size grid tile, tap to see full details)
class _CardTile extends StatelessWidget {
  final Map<String, dynamic> card;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CardTile({required this.card, required this.onEdit, required this.onDelete});

  void _showDetail(
    BuildContext context, {
    required Color headerGrad1,
    required Color headerGrad2,
    required Color accentColor,
    required Color scoreBg,
  }) {
    final score    = double.tryParse(card['score'].toString()) ?? 0.0;
    final emoji    = (card['emoji']?.toString().isNotEmpty == true) ? card['emoji'] : '🃏';
    final abstract = card['abstract_desc']?.toString() ?? '';
    final detailed = card['detailed_desc']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog header
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerGrad1, headerGrad2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(children: [
                Positioned(
                  right: -20, top: -20,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
              ]),
            ),
            // Dialog body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['name'] ?? '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _Pill(
                      label: '${score > 0 ? '+' : ''}$score نقطة',
                      bg: scoreBg,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      label: '${card['quantity']}x',
                      bg: const Color(0xFFF4F8FB),
                      color: const Color(0xFF5D8BAB),
                      outlined: true,
                    ),
                  ]),
                  if (abstract.isNotEmpty || detailed.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1),
                    ),
                    if (abstract.isNotEmpty) ...[
                      Text(
                        abstract,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (detailed.isNotEmpty)
                      Text(
                        detailed,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF5D8BAB),
                          height: 1.6,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            // Dialog actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إغلاق'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () { Navigator.pop(ctx); onEdit(); },
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('تعديل'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final score     = double.tryParse(card['score'].toString()) ?? 0.0;
    final isNeg     = score < 0;
    final isOneTime = card['is_one_time'] as bool? ?? false;
    final emoji     = (card['emoji']?.toString().isNotEmpty == true) ? card['emoji'] : '🃏';
    final abstract  = card['abstract_desc']?.toString() ?? '';
    final detailed  = card['detailed_desc']?.toString() ?? '';

    final Color headerGrad1;
    final Color headerGrad2;
    final Color accentColor;
    final Color scoreBg;
    final Color borderColor;

    if (isNeg) {
      headerGrad1 = const Color(0xFFE8463A);
      headerGrad2 = const Color(0xFFC73629);
      accentColor = const Color(0xFFC73629);
      scoreBg     = const Color(0xFFFBE3DF);
      borderColor = const Color(0xFFF5C6C6);
    } else if (score < 1) {
      headerGrad1 = const Color(0xFFF7D042);
      headerGrad2 = const Color(0xFFE0B82A);
      accentColor = const Color(0xFF92620A);
      scoreBg     = const Color(0xFFFEF3C7);
      borderColor = const Color(0xFFE0C060);
    } else {
      headerGrad1 = const Color(0xFF0E5685);
      headerGrad2 = const Color(0xFF073A5C);
      accentColor = const Color(0xFF0E5685);
      scoreBg     = const Color(0xFFDCF0FC);
      borderColor = const Color(0xFF6FC9EC);
    }

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor.withValues(alpha: .45), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: .10),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Tappable area: header + body
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showDetail(
                  context,
                  headerGrad1: headerGrad1,
                  headerGrad2: headerGrad2,
                  accentColor: accentColor,
                  scoreBg: scoreBg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Header
                    SizedBox(
                      height: 90,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [headerGrad1, headerGrad2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -18, top: -18,
                              child: Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .08),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              left: -10, bottom: -14,
                              child: Container(
                                width: 54, height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .06),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                                ),
                              ),
                            ),
                            // Expand hint icon
                            Positioned(
                              top: 8, right: 8,
                              child: Container(
                                width: 22, height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.open_in_full_rounded,
                                  size: 11,
                                  color: Colors.white.withValues(alpha: .85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Body — ClipRect prevents overflow errors when text is long
                    Expanded(
                      child: ClipRect(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card['name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  Flexible(
                                    child: _Pill(
                                      label: '${score > 0 ? '+' : ''}$score نقطة',
                                      bg: scoreBg,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  _Pill(
                                    label: '${card['quantity']}x',
                                    bg: const Color(0xFFF4F8FB),
                                    color: const Color(0xFF5D8BAB),
                                    outlined: true,
                                  ),
                                  if (isOneTime) ...[
                                    const SizedBox(width: 5),
                                    const _Pill(
                                      label: '1x',
                                      bg: Color(0xFFFFF3CD),
                                      color: Color(0xFF92620A),
                                    ),
                                  ],
                                ],
                              ),
                              if (abstract.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  abstract,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor.withValues(alpha: .85),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (detailed.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  detailed,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF5D8BAB),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer action bar (separate from tap target)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFD),
                border: Border(
                  top: BorderSide(color: borderColor.withValues(alpha: .3), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TileAction(
                      icon: Icons.edit_outlined,
                      label: 'تعديل',
                      color: accentColor,
                      onTap: onEdit,
                    ),
                  ),
                  Container(
                    width: 1, height: 36,
                    color: borderColor.withValues(alpha: .3),
                  ),
                  Expanded(
                    child: _TileAction(
                      icon: Icons.delete_outline,
                      label: 'حذف',
                      color: AppColors.red,
                      onTap: onDelete,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color bg, color;
  final bool outlined;
  const _Pill({required this.label, required this.bg, required this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : bg,
        borderRadius: BorderRadius.circular(999),
        border: outlined ? Border.all(color: color.withValues(alpha: .3)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _TileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _TileAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final Color color, bg;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label, required this.value, required this.selected,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? bg : Colors.white,
          border: Border.all(
              color: selected ? color : const Color(0xFFDDEEF7), width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? color : const Color(0xFF5D8BAB))),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5D8BAB))),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDEEF7), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF5D8BAB))),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}
