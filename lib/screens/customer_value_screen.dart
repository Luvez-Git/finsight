import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';

class CustomerValueScreen extends StatefulWidget {
  const CustomerValueScreen({super.key});

  @override
  State<CustomerValueScreen> createState() => _CustomerValueScreenState();
}

class _CustomerValueScreenState extends State<CustomerValueScreen> {
  final SupabaseClient _supabase = SupabaseService.client;

  bool _loading = true;
  String? _error;

  int _totalCustomers = 0;
  int _highValue = 0;
  int _premium = 0;
  int _growing = 0;
  int _standard = 0;

  double _averageValueScore = 0;
  double _totalBalance = 0;

  List<Map<String, dynamic>> _topCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomerValue();
  }

  Future<void> _loadCustomerValue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final totalResponse = await _supabase
          .from('customers')
          .select('customer_id')
          .count(CountOption.exact);

      final highValueResponse = await _supabase
          .from('customers')
          .select('customer_id')
          .eq('value_segment', 'High Value')
          .count(CountOption.exact);

      final premiumResponse = await _supabase
          .from('customers')
          .select('customer_id')
          .eq('value_segment', 'Premium')
          .count(CountOption.exact);

      final growingResponse = await _supabase
          .from('customers')
          .select('customer_id')
          .eq('value_segment', 'Growing')
          .count(CountOption.exact);

      final standardResponse = await _supabase
          .from('customers')
          .select('customer_id')
          .eq('value_segment', 'Standard')
          .count(CountOption.exact);

      final scoreResponse = await _supabase
          .from('customers')
          .select('customer_value_score');

      final balanceResponse = await _supabase
          .from('customers')
          .select('average_balance');

      final topCustomers = await _supabase
          .from('customers')
          .select('''
            customer_id,
            account_type,
            average_balance,
            customer_value_score,
            value_segment,
            number_of_products,
            recommended_product,
            recommended_action
          ''')
          .order('customer_value_score', ascending: false)
          .range(0, 4);

      final scores = List<Map<String, dynamic>>.from(scoreResponse);
      final balances = List<Map<String, dynamic>>.from(balanceResponse);

      double scoreTotal = 0;
      int scoreCount = 0;

      for (final row in scores) {
        final value = _toDouble(row['customer_value_score']);
        scoreTotal += value;
        scoreCount++;
      }

      double balanceTotal = 0;

      for (final row in balances) {
        balanceTotal += _toDouble(row['average_balance']);
      }

      if (!mounted) return;

      setState(() {
        _totalCustomers = totalResponse.count;
        _highValue = highValueResponse.count;
        _premium = premiumResponse.count;
        _growing = growingResponse.count;
        _standard = standardResponse.count;

        _averageValueScore =
            scoreCount == 0 ? 0 : scoreTotal / scoreCount;

        _totalBalance = balanceTotal;

        _topCustomers =
            List<Map<String, dynamic>>.from(topCustomers);

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
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Understand the customers creating the most value.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _loading ? null : _loadCustomerValue,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget _buildContent() {
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
                    label: 'High Value',
                    value: _formatNumber(_highValue),
                    caption: 'Highest-value segment',
                    accent: AppColors.green,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'Total Balance',
                    value: _formatCurrency(_totalBalance),
                    caption: 'Combined average balances',
                    accent: AppColors.green,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: 'Avg Value Score',
                    value: _averageValueScore.toStringAsFixed(1),
                    caption: 'Across all customers',
                    accent: AppColors.blue,
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
                  Expanded(child: _buildSegments()),
                  const SizedBox(width: 18),
                  Expanded(child: _buildValueStrategy()),
                ],
              );
            }

            return Column(
              children: [
                _buildSegments(),
                const SizedBox(height: 18),
                _buildValueStrategy(),
              ],
            );
          },
        ),

        const SizedBox(height: 18),

        _buildTopCustomers(),
      ],
    );
  }

  Widget _buildSegments() {
    return SectionCard(
      title: 'Value Segment Distribution',
      child: Column(
        children: [
          _SegmentRow(
            label: 'High Value',
            count: _highValue,
            total: _totalCustomers,
            color: AppColors.green,
          ),
          const SizedBox(height: 18),
          _SegmentRow(
            label: 'Premium',
            count: _premium,
            total: _totalCustomers,
            color: AppColors.blue,
          ),
          const SizedBox(height: 18),
          _SegmentRow(
            label: 'Growing',
            count: _growing,
            total: _totalCustomers,
            color: AppColors.amber,
          ),
          const SizedBox(height: 18),
          _SegmentRow(
            label: 'Standard',
            count: _standard,
            total: _totalCustomers,
            color: AppColors.muted,
          ),
        ],
      ),
    );
  }

  Widget _buildValueStrategy() {
    return SectionCard(
      title: 'Value Strategy',
      child: Column(
        children: const [
          _StrategyRow(
            icon: Icons.star_outline,
            title: 'Protect high-value customers',
            description:
                'Prioritize retention and personalized service for customers with strong value scores.',
          ),
          Divider(height: 28),
          _StrategyRow(
            icon: Icons.trending_up,
            title: 'Grow emerging customers',
            description:
                'Identify growing customers who could become high-value relationships.',
          ),
          Divider(height: 28),
          _StrategyRow(
            icon: Icons.account_balance_outlined,
            title: 'Increase product depth',
            description:
                'Offer relevant products to valuable customers with limited product relationships.',
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomers() {
    return SectionCard(
      title: 'Highest-Value Customers',
      child: _topCustomers.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No customer data found.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < _topCustomers.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _topCustomers.length - 1 ? 0 : 14,
                    ),
                    child: _ValueCustomerRow(
                      customer: _topCustomers[i],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildError() {
    return SectionCard(
      title: 'Unable to load customer value',
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FinSight could not retrieve customer value data from Supabase.',
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
              onPressed: _loadCustomerValue,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1)}K';
    }

    return '\$${value.toStringAsFixed(0)}';
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = total == 0 ? 0.0 : count / total;

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
                  )}  •  ${(percentage * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 9,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StrategyRow extends StatelessWidget {
  const _StrategyRow({
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
            color: AppColors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.green,
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

class _ValueCustomerRow extends StatelessWidget {
  const _ValueCustomerRow({
    required this.customer,
  });

  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context) {
    final id = customer['customer_id']?.toString() ?? 'Unknown';
    final account = customer['account_type']?.toString() ?? 'Account';
    final segment = customer['value_segment']?.toString() ?? 'Standard';
    final products = customer['number_of_products']?.toString() ?? '0';

    final score = _toDouble(customer['customer_value_score']);
    final balance = _toDouble(customer['average_balance']);

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
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.green,
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
                  '$account • $segment • $products products',
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
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '\$${balance.toStringAsFixed(0)} balance',
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
}