import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_card.dart';

class CrossSellScreen extends StatefulWidget {
  const CrossSellScreen({super.key});

  @override
  State<CrossSellScreen> createState() => _CrossSellScreenState();
}

class _CrossSellScreenState extends State<CrossSellScreen> {
  final SupabaseClient _supabase = SupabaseService.client;

  bool _loading = true;
  String? _error;

  int _totalCustomers = 0;
  int _highOpportunities = 0;
  double _averageScore = 0;

  Map<String, int> _productCounts = {};
  List<Map<String, dynamic>> _topCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final totalResponse = await _supabase
          .from('customers')
          .select('customer_id')
          .count(CountOption.exact);

      final highResponse = await _supabase
          .from('customers')
          .select('customer_id')
          .eq('cross_sell_opportunity', 'High')
          .count(CountOption.exact);

      final scores = await _supabase
          .from('customers')
          .select('cross_sell_score')
          .not('cross_sell_score', 'is', null)
          .range(0, 9999);

      final products = await _supabase
          .from('customers')
          .select('recommended_product')
          .not('recommended_product', 'is', null)
          .range(0, 9999);

      final top = await _supabase
          .from('customers')
          .select('''
            customer_id,
            cross_sell_score,
            cross_sell_opportunity,
            recommended_product,
            recommended_action,
            number_of_products
          ''')
          .order('cross_sell_score', ascending: false)
          .range(0, 4);

      final scoreValues = scores
          .map<double?>(
            (row) => (row['cross_sell_score'] as num?)?.toDouble(),
          )
          .whereType<double>()
          .toList();

      final average = scoreValues.isEmpty
          ? 0.0
          : scoreValues.reduce((a, b) => a + b) / scoreValues.length;

      final counts = <String, int>{};

      for (final row in products) {
        final product = row['recommended_product']?.toString();

        if (product != null && product.isNotEmpty) {
          counts[product] = (counts[product] ?? 0) + 1;
        }
      }

      counts.removeWhere((key, value) => value == 0);

      if (!mounted) return;

      setState(() {
        _totalCustomers = totalResponse.count;
        _highOpportunities = highResponse.count;
        _averageScore = average;
        _productCounts = counts;
        _topCustomers = List<Map<String, dynamic>>.from(top);
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

  String _formatNumber(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cross-Sell Intelligence',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Find the strongest product opportunities for each customer.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _ErrorCard(
              message: _error!,
              onRetry: _loadData,
            )
          else ...[
            _buildKpis(),
            const SizedBox(height: 20),
            _buildProductOpportunities(),
            const SizedBox(height: 20),
            _buildTopCustomers(),
          ],
        ],
      ),
    );
  }

  Widget _buildKpis() {
    final opportunityPercentage = _totalCustomers == 0
        ? 0
        : (_highOpportunities / _totalCustomers * 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
                ? 2
                : 1;

        final width =
            (constraints.maxWidth - ((columns - 1) * 14)) / columns;

        final cards = [
          KpiCard(
            label: 'Customers',
            value: _formatNumber(_totalCustomers),
            caption: 'Total customer base',
            accent: AppColors.blue,
          ),
          KpiCard(
            label: 'High Opportunities',
            value: _formatNumber(_highOpportunities),
            caption:
                '${opportunityPercentage.toStringAsFixed(1)}% of customers',
            accent: AppColors.amber,
          ),
          KpiCard(
            label: 'Avg Opportunity Score',
            value: _averageScore.toStringAsFixed(2),
            caption: 'Across customer base',
            accent: AppColors.green,
          ),
          KpiCard(
            label: 'Products',
            value: _productCounts.length.toString(),
            caption: 'Recommended product types',
            accent: AppColors.blue,
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

  Widget _buildProductOpportunities() {
    final sortedProducts = _productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxCount =
        sortedProducts.isEmpty ? 1 : sortedProducts.first.value;

    return SectionCard(
      title: 'Recommended Product Opportunities',
      child: Column(
        children: [
          if (sortedProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No product opportunity data available.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else
            for (final entry in sortedProducts)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _ProductOpportunityRow(
                  product: entry.key,
                  count: entry.value,
                  percentage: entry.value / maxCount,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTopCustomers() {
    return SectionCard(
      title: 'Highest-Priority Opportunities',
      child: Column(
        children: [
          for (var i = 0; i < _topCustomers.length; i++) ...[
            _CustomerOpportunityRow(
              customer: _topCustomers[i],
            ),
            if (i != _topCustomers.length - 1)
              const Divider(height: 24),
          ],
        ],
      ),
    );
  }
}

class _ProductOpportunityRow extends StatelessWidget {
  const _ProductOpportunityRow({
    required this.product,
    required this.count,
    required this.percentage,
  });

  final String product;
  final int count;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                product,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            minHeight: 9,
            backgroundColor: AppColors.border,
            color: AppColors.amber,
          ),
        ),
      ],
    );
  }
}

class _CustomerOpportunityRow extends StatelessWidget {
  const _CustomerOpportunityRow({
    required this.customer,
  });

  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context) {
    final customerId = customer['customer_id']?.toString() ?? 'Unknown';
    final product =
        customer['recommended_product']?.toString() ?? 'No product';
    final action =
        customer['recommended_action']?.toString() ?? 'No action';
    final score = (customer['cross_sell_score'] as num).toDouble();

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.amber,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customerId,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                product,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                action,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            score.toStringAsFixed(2),
            style: const TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Unable to load Cross-Sell data',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}