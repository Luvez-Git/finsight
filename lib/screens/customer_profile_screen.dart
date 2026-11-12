import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.customerId,
  });

  final String customerId;

  @override
  State<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends State<CustomerProfileScreen> {
  final SupabaseClient _supabase = SupabaseService.client;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _customer;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('customers')
          .select('''
            customer_id,
            age,
            account_type,
            monthly_income,
            average_balance,
            transaction_frequency_monthly,
            digital_banking_usage_score,
            number_of_products,
            loan_status,
            tenure_months,
            activity_change_pct,
            balance_change_pct,
            days_since_last_transaction,
            activity_score,
            customer_value_score,
            churn_risk_score,
            churn_risk_level,
            value_segment,
            cross_sell_score,
            cross_sell_opportunity,
            recommended_product,
            recommended_action
          ''')
          .eq('customer_id', widget.customerId)
          .maybeSingle();

      if (!mounted) return;

      if (response == null) {
        setState(() {
          _error = 'Customer not found.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _customer = response;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _text(String key) {
    return _customer?[key]?.toString() ?? '—';
  }

  String _number(String key) {
    final value = _customer?[key];

    if (value is num) {
      return value.toString();
    }

    return '—';
  }

  String _money(String key) {
    final value = _customer?[key];

    if (value is num) {
      return '\$${value.toStringAsFixed(2)}';
    }

    return '—';
  }

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return AppColors.red;
      case 'medium':
        return AppColors.amber;
      default:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? _buildError()
              : _buildProfile(),
    );
  }

  Widget _buildError() {
    return Center(
      child: SectionCard(
        title: 'Unable to load customer',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _error ?? 'Unknown error',
              style: const TextStyle(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCustomer,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    final risk = _text('churn_risk_level');
    final riskColor = _riskColor(risk);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              const Text(
                'Customer Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              'Detailed customer intelligence and recommended actions.',
              style: const TextStyle(
                color: AppColors.muted,
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildCustomerHeader(risk, riskColor),

          const SizedBox(height: 20),

          _buildKpis(),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildCustomerDetails(),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _buildIntelligence(),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildCustomerDetails(),
                  const SizedBox(height: 18),
                  _buildIntelligence(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader(
    String risk,
    Color riskColor,
  ) {
    return SectionCard(
      title: 'Customer',
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 30,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text('customer_id'),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_text('account_type')} • ${_number('tenure_months')} months tenure',
                  style: const TextStyle(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          _Badge(
            text: '$risk Risk',
            color: riskColor,
          ),
        ],
      ),
    );
  }

  Widget _buildKpis() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
                ? 2
                : 1;

        final width =
            (constraints.maxWidth - ((columns - 1) * 14)) /
                columns;

        final cards = [
          KpiCard(
            label: 'Average Balance',
            value: _money('average_balance'),
            caption: 'Current customer balance',
            accent: AppColors.blue,
          ),
          KpiCard(
            label: 'Value Score',
            value: _number('customer_value_score'),
            caption: _text('value_segment'),
            accent: AppColors.green,
          ),
          KpiCard(
            label: 'Churn Score',
            value: _number('churn_risk_score'),
            caption: '${
              _text('churn_risk_level')
            } risk',
            accent: AppColors.red,
          ),
          KpiCard(
            label: 'Cross-Sell Score',
            value: _number('cross_sell_score'),
            caption: _text('cross_sell_opportunity'),
            accent: AppColors.amber,
          ),
        ];

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final card in cards)
              SizedBox(
                width: width,
                child: card,
              ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerDetails() {
    return SectionCard(
      title: 'Customer Details',
      child: Column(
        children: [
          _DetailRow(
            label: 'Age',
            value: _number('age'),
          ),
          _DetailRow(
            label: 'Account Type',
            value: _text('account_type'),
          ),
          _DetailRow(
            label: 'Monthly Income',
            value: _money('monthly_income'),
          ),
          _DetailRow(
            label: 'Number of Products',
            value: _number('number_of_products'),
          ),
          _DetailRow(
            label: 'Loan Status',
            value: _text('loan_status'),
          ),
          _DetailRow(
            label: 'Transaction Frequency',
            value:
                '${_number('transaction_frequency_monthly')} / month',
          ),
          _DetailRow(
            label: 'Digital Banking Score',
            value: _number('digital_banking_usage_score'),
          ),
          _DetailRow(
            label: 'Days Since Last Transaction',
            value: _number('days_since_last_transaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildIntelligence() {
    return SectionCard(
      title: 'FinSight Intelligence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsightBlock(
            icon: Icons.warning_amber_outlined,
            title: 'Churn Assessment',
            value: _text('churn_risk_level'),
            description:
                'Activity change: ${_number('activity_change_pct')}% • '
                'Balance change: ${_number('balance_change_pct')}%',
            color: AppColors.red,
          ),

          const SizedBox(height: 18),

          _InsightBlock(
            icon: Icons.shopping_bag_outlined,
            title: 'Cross-Sell Opportunity',
            value: _text('recommended_product'),
            description: _text('recommended_action'),
            color: AppColors.amber,
          ),

          const SizedBox(height: 18),

          _InsightBlock(
            icon: Icons.insights_outlined,
            title: 'Customer Value',
            value: _text('value_segment'),
            description:
                'Customer value score: ${_number('customer_value_score')}',
            color: AppColors.green,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}