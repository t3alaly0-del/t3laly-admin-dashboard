import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/admin_state.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot_icon.dart';
import 'points_page.dart';
import 'categories_page.dart';
import 'rescue_tasks_page.dart';
import 'gifts_page.dart';
import 'codes_page.dart';
import 'game_management_page.dart';

enum DashPage { game, points, codes, categories, rescue, gifts }

const _pageTitles = {
  DashPage.game: '🎮 إدارة اللعبة',
  DashPage.points: '⚙️ قيم النقاط',
  DashPage.codes: '🔑 إدارة كودات اللعبة',
  DashPage.categories: '🗂️ الكاتيجوريز',
  DashPage.rescue: '😈 أحكام كروت الإنقاذ',
  DashPage.gifts: '🎁 مكافآت الفائز',
};

class DashboardShellScreen extends StatefulWidget {
  const DashboardShellScreen({super.key});

  @override
  State<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends State<DashboardShellScreen> {
  DashPage _page = DashPage.points;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      final saved = prefs.getString('admin_tab');
      if (saved != null && mounted) {
        final restored = DashPage.values.where((p) => p.name == saved).firstOrNull;
        if (restored != null) setState(() => _page = restored);
      }
    });
  }

  void _savePage(DashPage p) {
    SharedPreferences.getInstance().then((prefs) => prefs.setString('admin_tab', p.name));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminState>();
    final pack = admin.selectedPack;

    if (pack == null) {
      // Still fetching games — wait for auto-open before deciding to redirect.
      if (admin.isLoading) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      // Games loaded but still no pack (user explicitly browsed back).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pushReplacementNamed(context, '/games');
      });
      return const Scaffold(body: SizedBox.expand());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FA),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            _Sidebar(
              packName: pack.name,
              selected: _page,
              onSelect: (p) {
                setState(() => _page = p);
                _savePage(p);
                final gameId = int.parse(pack.id);
                switch (p) {
                  case DashPage.game:       admin.fetchGameInfo();
                  case DashPage.points:     admin.fetchCards(gameId);
                  case DashPage.codes:      admin.fetchCodes(gameId);
                  case DashPage.categories: admin.fetchCategories();
                  case DashPage.rescue:     admin.fetchRescueTasks();
                  case DashPage.gifts:      admin.fetchGiftLines();
                }
              },
              onBack: () {
                admin.backToGamesList();
                Navigator.pushReplacementNamed(context, '/games');
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          bottom:
                              BorderSide(color: Color(0xFFDDEEF7), width: 1.5)),
                    ),
                    child: Row(
                      children: [
                        Text(_pageTitles[_page]!,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999)),
                          child: const Text('Admin Panel',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                      child: switch (_page) {
                        DashPage.game => const GameManagementPage(),
                        DashPage.points => const PointsPage(),
                        DashPage.codes => const CodesPage(),
                        DashPage.categories => const CategoriesPage(),
                        DashPage.rescue => const RescueTasksPage(),
                        DashPage.gifts => const GiftsPage(),
                      },
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

class _Sidebar extends StatelessWidget {
  final String packName;
  final DashPage selected;
  final ValueChanged<DashPage> onSelect;
  final VoidCallback onBack;
  const _Sidebar(
      {required this.packName,
      required this.selected,
      required this.onSelect,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.primaryDark,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0x14FFFFFF), width: 1)),
              ),
              margin: const EdgeInsets.only(bottom: 10),
              child: const Row(
                children: [
                  MascotIcon(size: 28),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تعلالى',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15)),
                      Text('لوحة الأدمن',
                          style: TextStyle(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0x1F6FC9EC),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Text('🎮 ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(packName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5)),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0x1AFFFFFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('← كل الألعاب',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const _NavSection('اللعبة'),
            _NavItem(icon: '🎮', label: 'إدارة اللعبة', active: selected == DashPage.game, onTap: () => onSelect(DashPage.game)),
            _NavItem(icon: '⚙️', label: 'قيم النقاط', active: selected == DashPage.points, onTap: () => onSelect(DashPage.points)),
            const _NavSection('الكودات'),
            _NavItem(
                icon: '🔑',
                label: 'إدارة الكودات',
                active: selected == DashPage.codes,
                onTap: () => onSelect(DashPage.codes)),
            const _NavSection('المحتوى'),
            _NavItem(
                icon: '🗂️',
                label: 'الكاتيجوريز',
                active: selected == DashPage.categories,
                onTap: () => onSelect(DashPage.categories)),
            _NavItem(
                icon: '😈',
                label: 'أحكام الإنقاذ',
                active: selected == DashPage.rescue,
                onTap: () => onSelect(DashPage.rescue)),
            _NavItem(
                icon: '🎁',
                label: 'مكافآت الفائز',
                active: selected == DashPage.gifts,
                onTap: () => onSelect(DashPage.gifts)),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String label;
  const _NavSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Text(label,
          style: const TextStyle(
              color: Color(0x59FFFFFF),
              fontWeight: FontWeight.w900,
              fontSize: 10.5,
              letterSpacing: .8)),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon, label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0x1F6FC9EC) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
              border: Border(
                  right: BorderSide(
                      color: active ? AppColors.blue : Colors.transparent,
                      width: 3))),
          child: Row(
            children: [
              SizedBox(
                  width: 22,
                  child: Text(icon,
                      style: const TextStyle(fontSize: 15),
                      textAlign: TextAlign.center)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    color: active
                        ? AppColors.blue
                        : Colors.white.withValues(alpha: .7),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
