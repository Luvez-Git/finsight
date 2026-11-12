import 'package:flutter/material.dart';
import 'screens/cross_sell_screen.dart';
import 'screens/customer_value_screen.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/analysis_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseService.initialize();
  runApp(const FinSightApp());
}

class FinSightApp extends StatelessWidget {
  const FinSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinSight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const FinSightShell(),
    );
  }
}

class FinSightShell extends StatefulWidget {
  const FinSightShell({super.key});

  @override
  State<FinSightShell> createState() => _FinSightShellState();
}

class _FinSightShellState extends State<FinSightShell> {
  int selectedIndex = 0;

  final pages = const [
    DashboardScreen(),
    CustomersScreen(),
    AnalysisScreen(
      title: 'Churn Analysis',
      subtitle: 'Identify customers who may be at risk of leaving.',
    ),
    CustomerValueScreen(),
    CrossSellScreen(),
  ];

  final labels = const [
    'Dashboard',
    'Customers',
    'Churn Analysis',
    'Customer Value',
    'Cross-Sell',
  ];

  final icons = const [
    Icons.dashboard_outlined,
    Icons.people_outline,
    Icons.warning_amber_outlined,
    Icons.insights_outlined,
    Icons.shopping_bag_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;

    return Scaffold(
      body: Row(
        children: [
          if (!compact)
            Container(
              width: 248,
              color: AppColors.navy,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 34),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'FinSight',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < labels.length; i++)
                      _NavItem(
                        icon: icons[i],
                        label: labels[i],
                        selected: selectedIndex == i,
                        onTap: () => setState(() => selectedIndex = i),
                      ),
                    const Spacer(),
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Banking Intelligence\nPlatform',
                        style: TextStyle(
                          color: Colors.white54,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  if (compact)
                    _MobileHeader(
                      onMenu: () => _showMobileNav(context),
                    ),
                  Expanded(child: pages[selectedIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileNav(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++)
              ListTile(
                leading: Icon(icons[i]),
                title: Text(labels[i]),
                selected: selectedIndex == i,
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() => selectedIndex = i);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : Colors.white60,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.navy,
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu, color: Colors.white),
          ),
          const SizedBox(width: 4),
          const Text(
            'FinSight',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 19,
            ),
          ),
        ],
      ),
    );
  }
}
