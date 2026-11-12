import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final SupabaseClient _supabase = SupabaseService.client;

  bool _loading = true;
  String? _error;

  int _totalCustomers = 0;
  int _highRisk = 0;
  int _mediumRisk = 0;
  int _lowRisk = 0;

  double _highRiskPercentage = 0;
  double _mediumRiskPercentage = 0;
  double _lowRiskPercentage = 0;

  List<Map<String, dynamic>> _topRiskCustomers = [];

  @override
  void initState() {
    super.initState();

    if (widget.title == 'Churn Analysis') {
      _loadChurnAnalysis();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadChurnAnalysis() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final total = await _supabase
          .from('customers')
          .select('customer_id')
          .count(CountOption.exact);

      final high = await _supabase
          .from('customers')
          .select('customer_id')
          .eq('churn_risk_level', 'High')
          .count(CountOption.exact);

      final medium = await _supabase
          .from('customers')
          .select('customer_id')
          .eq('churn_risk_level', 'Medium')
          .count(CountOption.exact);

      final low = await _supabase
          .from('customers')
          .select('customer_id')
          .eq('churn_risk_level', 'Low')
          .count(CountOption.exact);

      final riskCustomers = await _supabase
          .from('customers')
          .select('''
            customer_id,
            account_type,
            churn_risk_score,
            churn_risk_level,
            activity_change_pct,
            balance_change_pct,
            days_since_last_transaction,
            digital_banking_usage_score,
            number_of_products,
            recommended_action
          ''')
          .eq('churn_risk_level', 'High')
          .order('churn_risk_score', ascending: false)
          .range(0, 4);

      final totalCount = total.count;
      final highCount = high.count;
      final mediumCount = medium.count;
      final lowCount = low.count;

      if (!mounted) return;

      setState(() {
        _totalCustomers = totalCount;
        _highRisk = highCount;
        _mediumRisk = mediumCount;
        _lowRisk = lowCount;

        _highRiskPercentage =
            totalCount == 0 ? 0 : (highCount / totalCount) * 100;

        _mediumRiskPercentage =
            totalCount == 0 ? 0 : (mediumCount / totalCount) * 100;

        _lowRiskPercentage =
            totalCount == 0 ? 0 : (lowCount / totalCount) * 100;

        _topRiskCustomers =
            List<Map<String, dynamic>>.from(riskCustomers);

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.title != 'Churn Analysis') {
      return _buildPlaceholderAnalysis();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _buildError()
          else
            _buildChurnContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Churn Analysis',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Identify customers who may be at risk of leaving.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _loading ? null : _loadChurnAnalysis,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildChurnContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 650
                    ? 2
                    : 1;

            final width =
                (constraints.maxWidth - (columns - 1) * 14) / columns;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'Customers',
                    value: _formatNumber(_totalCustomers),
                    caption: 'Total customer base',
                    accent: AppColors.blue,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'High Risk',
                    value: _formatNumber(_highRisk),
                    caption:
                        '${_highRiskPercentage.toStringAsFixed(1)}% of customers',
                    accent: AppColors.red,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'Medium Risk',
                    value: _formatNumber(_mediumRisk),
                    caption:
                        '${_mediumRiskPercentage.toStringAsFixed(1)}% of customers',
                    accent: AppColors.amber,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'Low Risk',
                    value: _formatNumber(_lowRisk),
                    caption:
                        '${_lowRiskPercentage.toStringAsFixed(1)}% of customers',
                    accent: AppColors.green,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRiskDistribution()),
                  const SizedBox(width: 18),
                  Expanded(child: _buildChurnDrivers()),
                ],
              );
            }

            return Column(
              children: [
                _buildRiskDistribution(),
                const SizedBox(height: 18),
                _buildChurnDrivers(),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        _buildTopRiskCustomers(),
      ],
    );
  }

  Widget _buildRiskDistribution() {
    return SectionCard(
      title: 'Churn Risk Distribution',
      child: Column(
        children: [
          _RiskBar(
            label: 'High Risk',
            count: _highRisk,
            percentage: _highRiskPercentage,
            color: AppColors.red,
          ),
          const SizedBox(height: 22),
          _RiskBar(
            label: 'Medium Risk',
            count: _mediumRisk,
            percentage: _mediumRiskPercentage,
            color: AppColors.amber,
          ),
          const SizedBox(height: 22),
          _RiskBar(
            label: 'Low Risk',
            count: _lowRisk,
            percentage: _lowRiskPercentage,
            color: AppColors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildChurnDrivers() {
    return SectionCard(
      title: 'Top Churn Drivers',
      child: Column(
        children: [
          _DriverRow(
            icon: Icons.trending_down,
            title: 'Activity decline',
            description:
                'Reduced transaction activity can indicate disengagement.',
          ),
          const Divider(height: 28),
          _DriverRow(
            icon: Icons.schedule_outlined,
            title: 'Days since transaction',
            description:
                'Longer periods without activity increase churn concern.',
          ),
          const Divider(height: 28),
          _DriverRow(
            icon: Icons.account_balance_outlined,
            title: 'Balance decline',
            description:
                'Falling balances may indicate reduced customer engagement.',
          ),
          const Divider(height: 28),
          _DriverRow(
            icon: Icons.phone_android_outlined,
            title: 'Low digital usage',
            description:
                'Lower digital banking activity can signal weaker engagement.',
          ),
          const Divider(height: 28),
          _DriverRow(
            icon: Icons.inventory_2_outlined,
            title: 'Low product count',
            description:
                'Customers using fewer products have fewer reasons to stay.',
          ),
        ],
      ),
    );
  }

  Widget _buildTopRiskCustomers() {
    return SectionCard(
      title: 'Highest-Risk Customers',
      child: _topRiskCustomers.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No high-risk customers found.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < _topRiskCustomers.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _topRiskCustomers.length - 1 ? 0 : 14,
                    ),
                    child: _RiskCustomerRow(
                      customer: _topRiskCustomers[i],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildError() {
    return SectionCard(
      title: 'Unable to load churn analysis',
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FinSight could not retrieve the churn data from Supabase.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadChurnAnalysis,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAnalysis() {
    final value = widget.title == 'Customer Value';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.subtitle,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 1000
                  ? 3
                  : c.maxWidth >= 650
                      ? 2
                      : 1;

              final width =
                  (c.maxWidth - (cols - 1) * 14) / cols;

              final cards = value
                  ? [
                      const KpiCard(
                        label: 'Portfolio Value',
                        value: r'$48.7M',
                        caption: 'Estimated customer value',
                        accent: AppColors.green,
                      ),
                      const KpiCard(
                        label: 'Premium',
                        value: '3,102',
                        caption: 'Top value segment',
                        accent: AppColors.green,
                      ),
                      const KpiCard(
                        label: 'Avg Value Score',
                        value: '74.2',
                        caption: 'Across customers',
                        accent: AppColors.blue,
                      ),
                    ]
                  : [
                      const KpiCard(
                        label: 'Opportunities',
                        value: '3,862',
                        caption: 'Customers with fit',
                        accent: AppColors.amber,
                      ),
                      const KpiCard(
                        label: 'Personal Loan',
                        value: '1,140',
                        caption: 'Top opportunity',
                        accent: AppColors.blue,
                      ),
                      const KpiCard(
                        label: 'Investment',
                        value: '824',
                        caption: 'Strong fit',
                        accent: AppColors.green,
                      ),
                    ];

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final card in cards)
                    SizedBox(width: width, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          SectionCard(
            title: value
                ? 'Value Segment Distribution'
                : 'Recommended Offers',
            child: Column(
              children: [
                for (final item in value
                    ? ['Premium', 'High Value', 'Growing', 'Standard']
                    : [
                        'Personal Loan',
                        'Investment Account',
                        'Digital Savings',
                        'Credit Card',
                      ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Text(
                          'View details',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );
  }
}

class _RiskBar extends StatelessWidget {
  const _RiskBar({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  final String label;
  final int count;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              '${count.toString().replaceAllMapped(
                    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                    (match) => '${match.group(1)},',
                  )}  •  ${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 10,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _DriverRow extends StatelessWidget {
  const _DriverRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RiskCustomerRow extends StatelessWidget {
  const _RiskCustomerRow({
    required this.customer,
  });

  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context) {
    final id = customer['customer_id']?.toString() ?? 'Unknown';
    final account = customer['account_type']?.toString() ?? 'Account';

    final score = _toDouble(customer['churn_risk_score']);
    final days = _toInt(customer['days_since_last_transaction']);
    final action =
        customer['recommended_action']?.toString() ?? 'Review account';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$account • $days days since transaction',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.red,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}