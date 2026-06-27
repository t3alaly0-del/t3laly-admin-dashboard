import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game.dart';
import '../state/admin_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot_icon.dart';
import '../widgets/toast.dart';

class GamesListScreen extends StatelessWidget {
  const GamesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FA),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              ),
              child: const Row(
                children: [
                  MascotIcon(size: 34),
                  SizedBox(width: 12),
                  Text('تعلالى',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(width: 8),
                  Text('لوحة الأدمن', style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w700, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              child: admin.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : admin.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFF5D8BAB)),
                              const SizedBox(height: 12),
                              Text(admin.error!, textAlign: TextAlign.center,
                                  style: const TextStyle(color: Color(0xFF5D8BAB))),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: admin.fetchGames,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('الألعاب المتاحة',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF5D8BAB), letterSpacing: .5)),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  for (final game in admin.games)
                                    _GameCard(game: game, onTap: () {
                                      admin.openGame(game);
                                      Navigator.pushNamed(context, '/dashboard');
                                    }),
                                  _AddGameCard(onAdd: (name) {
                                    showToast(context, 'قريباً — إضافة الألعاب من قاعدة البيانات');
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  const _GameCard({required this.game, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: AppColors.blueLight, borderRadius: BorderRadius.circular(16)),
                      alignment: Alignment.center,
                      child: const MascotIcon(size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(game.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.ink)),
                          if (game.description != null)
                            Text(game.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF5D8BAB))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0F6FA), width: 1.5))),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: game.isOpen ? const Color(0xFFE3F6EA) : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        game.isOpen ? 'متاحة ✅' : 'مجمدة ❄️',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: game.isOpen ? const Color(0xFF1E8E4D) : const Color(0xFF8A6D1B),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text('←', style: TextStyle(fontSize: 18, color: Color(0xFF5D8BAB))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddGameCard extends StatelessWidget {
  final ValueChanged<String> onAdd;
  const _AddGameCard({required this.onAdd});

  void _openDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('لعبة جديدة', style: TextStyle(fontWeight: FontWeight.w900)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'اسم الحزمة، مثلاً: حزمة العيد'),
          ),
          actions: [
            OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                onAdd(name);
                Navigator.pop(ctx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 120,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openDialog(context),
          child: const DottedBorderBox(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('＋', style: TextStyle(fontSize: 28, color: Color(0xFF5D8BAB))),
                  SizedBox(height: 6),
                  Text('أضف لعبة جديدة', style: TextStyle(color: Color(0xFF5D8BAB), fontWeight: FontWeight.w800, fontSize: 13.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple dashed-border container (Flutter has no built-in dashed border).
class DottedBorderBox extends StatelessWidget {
  final Widget child;
  const DottedBorderBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC8E2F0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20));
    final path = Path()..addRRect(rrect);
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        const dashLength = 6.0, gapLength = 5.0;
        dashPath.addPath(metric.extractPath(distance, distance + dashLength), Offset.zero);
        distance += dashLength + gapLength;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
