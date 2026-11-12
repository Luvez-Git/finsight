import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient _supabase = SupabaseService.client;

  bool _loading = true;
  String? _error;

  int _totalCustomers = 0;
  int _highRisk = 0;
  int _mediumRisk = 0;
  int _lowRisk = 0;
  int _highValue = 0;
  int _crossSell = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<int> _countCustomers({
    String? column,
    String? value,
  }) async {
    var query = _supabase
        .from('customers')
        .select('customer_id');

    if (column != null && value != null) {
      query = query.eq(column, value);
    }

    final response = await query.count(CountOption.exact);
    return response.count;
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<int>([
        // Total customers
        _countCustomers(),

        // Churn risk
        _countCustomers(
          column: 'churn_risk_level',
          value: 'High',
        ),
        _countCustomers(
          column: 'churn_risk_level',
          value: 'Medium',
        ),
        _countCustomers(
          column: 'churn_risk_level',
          value: 'Low',
        ),

        // Customer value
        _countCustomers(
          column: 'value_segment',
          value: 'High Value',
        ),

        // Cross-sell opportunities
        _countCustomers(
          column: 'cross_sell_opportunity',
          value: 'High',
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _totalCustomers = results[0];
        _highRisk = results[1];
        _mediumRisk = results[2];
        _lowRisk = results[3];
        _highValue = results[4];
        _crossSell = results[5];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('row-level security') ||
        message.contains('permission denied') ||
        message.contains('jwt') ||
        message.contains('authentication')) {
      return 'You need to be signed in to view live customer analytics.';
    }

    return 'Unable to load live customer data. Please try again.';
  }

  String _percentage(int value) {
    if (_totalCustomers == 0) return '0.0%';

    return '${((value / _totalCustomers) * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'A clear view of customer risk, value and growth opportunities.',
            style: TextStyle(
              color: AppColors.muted,
            ),
          ),

          const SizedBox(height: 24),

          if (_loading)
            const _LoadingDashboard()
          else if (_error != null)
            _ErrorDashboard(
              message: _error!,
              onRetry: _loadDashboardData,
            )
          else
            _DashboardContent(
              totalCustomers: _totalCustomers,
              highRisk: _highRisk,
              mediumRisk: _mediumRisk,
              lowRisk: _lowRisk,
              highValue: _highValue,
              crossSell: _crossSell,
              percentage: _percentage,
            ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.totalCustomers,
    required this.highRisk,
    required this.mediumRisk,
    required this.lowRisk,
    required this.highValue,
    required this.crossSell,
    required this.percentage,
  });

  final int totalCustomers;
  final int highRisk;
  final int mediumRisk;
  final int lowRisk;
  final int highValue;
  final int crossSell;

  final String Function(int value) percentage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 700
                    ? 2
                    : 1;

            final width =
                (constraints.maxWidth - ((columns - 1) * 14)) / columns;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'Customers',
                    value: _formatNumber(totalCustomers),
                    caption: 'Live customer portfolio',
                  ),
                ),

                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'At-Risk Customers',
                    value: _formatNumber(highRisk),
                    caption: '${percentage(highRisk)} of customers',
                    accent: AppColors.red,
                  ),
                ),

                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'High-Value Customers',
                    value: _formatNumber(highValue),
                    caption: '${percentage(highValue)} of customers',
                    accent: AppColors.green,
                  ),
                ),

                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'Cross-Sell Opportunities',
                    value: _formatNumber(crossSell),
                    caption: 'Priority opportunities',
                    accent: AppColors.amber,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 850) {
              return Column(
                children: [
                  SectionCard(
                    title: 'Customer Risk Distribution',
                    subtitle: 'Current churn risk profile',
                    child: _RiskBars(
                      lowRisk: lowRisk,
                      mediumRisk: mediumRisk,
                      highRisk: highRisk,
                      totalCustomers: totalCustomers,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SectionCard(
                    title: 'Priority Actions',
                    child: _Actions(
                      highRisk: highRisk,
                      highValue: highValue,
                      crossSell: crossSell,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SectionCard(
                    title: 'FinSight Intelligence',
                    child: _Insight(
                      highRisk: highRisk,
                      crossSell: crossSell,
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: SectionCard(
                    title: 'Customer Risk Distribution',
                    subtitle: 'Current churn risk profile',
                    child: _RiskBars(
                      lowRisk: lowRisk,
                      mediumRisk: mediumRisk,
                      highRisk: highRisk,
                      totalCustomers: totalCustomers,
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  flex: 2,
                  child: SectionCard(
                    title: 'Priority Actions',
                    child: _Actions(
                      highRisk: highRisk,
                      highValue: highValue,
                      crossSell: crossSell,
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        SectionCard(
          title: 'FinSight Intelligence',
          child: _Insight(
            highRisk: highRisk,
            crossSell: crossSell,
          ),
        ),
      ],
    );
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}

class _RiskBars extends StatelessWidget {
  const _RiskBars({
    required this.lowRisk,
    required this.mediumRisk,
    required this.highRisk,
    required this.totalCustomers,
  });

  final int lowRisk;
  final int mediumRisk;
  final int highRisk;
  final int totalCustomers;

  double _ratio(int value) {
    if (totalCustomers == 0) return 0;
    return value / totalCustomers;
  }

  String _percentage(int value) {
    if (totalCustomers == 0) return '0.0%';
    return '${((value / totalCustomers) * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Bar(
          label: 'Low Risk',
          value: _ratio(lowRisk),
          count: '${_formatNumber(lowRisk)} (${_percentage(lowRisk)})',
          color: AppColors.green,
        ),

        const SizedBox(height: 18),

        _Bar(
          label: 'Medium Risk',
          value: _ratio(mediumRisk),
          count: '${_formatNumber(mediumRisk)} (${_percentage(mediumRisk)})',
          color: AppColors.amber,
        ),

        const SizedBox(height: 18),

        _Bar(
          label: 'High Risk',
          value: _ratio(highRisk),
          count: '${_formatNumber(highRisk)} (${_percentage(highRisk)})',
          color: AppColors.red,
        ),
      ],
    );
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });

  final String label;
  final String count;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count,
              style: const TextStyle(
                color: AppColors.muted,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 9,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.highRisk,
    required this.highValue,
    required this.crossSell,
  });

  final int highRisk;
  final int highValue;
  final int crossSell;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionRow(
          icon: Icons.shield_outlined,
          title: 'Retention outreach',
          count: _formatNumber(highRisk),
          color: AppColors.red,
        ),

        _ActionRow(
          icon: Icons.star_outline,
          title: 'VIP relationship review',
          count: _formatNumber(highValue),
          color: AppColors.green,
        ),

        _ActionRow(
          icon: Icons.add_chart_outlined,
          title: 'Product offers',
          count: _formatNumber(crossSell),
          color: AppColors.amber,
        ),
      ],
    );
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            count,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight({
    required this.highRisk,
    required this.crossSell,
  });

  final int highRisk;
  final int crossSell;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: AppColors.blue,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'FinSight currently identifies '
              '${_formatNumber(highRisk)} high-risk customers and '
              '${_formatNumber(crossSell)} high-priority cross-sell '
              'opportunities. Prioritise retention outreach for customers '
              'at risk and targeted product offers for customers with '
              'strong cross-sell potential.',
              style: const TextStyle(
                color: AppColors.text,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
  }
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading customer intelligence...',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorDashboard extends StatelessWidget {
  const _ErrorDashboard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: AppColors.red,
            ),

            const SizedBox(height: 14),

            const Text(
              'Could not load dashboard data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}