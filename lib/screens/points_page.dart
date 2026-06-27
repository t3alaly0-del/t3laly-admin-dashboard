import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/admin_state.dart';
import '../theme/app_theme.dart';
import '../widgets/format.dart';
import '../widgets/toast.dart';

class PointsPage extends StatelessWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Text('⚙️ ', style: TextStyle(fontSize: 18)),
              Text('قيم النقاط لكل كرت', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.ink)),
            ]),
            const SizedBox(height: 6),
            const Text('عدّل النقاط اللي بتتحسب لكل نوع من الكروت — بتأثر على اللعب الجاي.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF5D8BAB), height: 1.6)),
            const SizedBox(height: 18),
            if (admin.isLoadingCards)
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (admin.cardError != null)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFF5D8BAB)),
                    const SizedBox(height: 8),
                    Text(admin.cardError!, style: const TextStyle(color: Color(0xFF5D8BAB))),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final id = int.tryParse(admin.selectedPack?.id ?? '');
                        if (id != null) admin.fetchCards(id);
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final detail in admin.cardDetails)
                    _PointBox(
                      emoji: detail.emoji,
                      label: detail.name,
                      value: detail.score,
                      color: detail.score < 0 ? AppColors.red : AppColors.primary,
                      valueColor: detail.score < 0 ? AppColors.redDark : null,
                      onAdjust: (d) => admin.adjustCardScore(detail.id, d),
                    ),
                ],
              ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
            ElevatedButton(
              onPressed: admin.cardDetails.isEmpty
                  ? null
                  : () async {
                      try {
                        await admin.saveCardScores();
                        if (context.mounted) showToast(context, 'تم حفظ قيم النقاط ✅');
                      } catch (_) {
                        if (context.mounted) showToast(context, 'فشل الحفظ، حاول تاني ❌');
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink),
              child: const Text('💾 احفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointBox extends StatelessWidget {
  final String emoji, label;
  final double value;
  final Color color;
  final Color? valueColor;
  final ValueChanged<double> onAdjust;

  const _PointBox({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.onAdjust,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDEEF7), width: 1.5),
      ),
      child: Column(
        children: [
          Text('$emoji $label', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF5D8BAB))),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepperButton(symbol: '−', color: color, onTap: () => onAdjust(-0.5)),
              SizedBox(
                width: 56,
                child: Text(fmtNum(value),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valueColor ?? AppColors.primary)),
              ),
              _StepperButton(symbol: '+', color: color, onTap: () => onAdjust(0.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final String symbol;
  final Color color;
  final VoidCallback onTap;
  const _StepperButton({required this.symbol, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(child: Text(symbol, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
        ),
      ),
    );
  }
}
