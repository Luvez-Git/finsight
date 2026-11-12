import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import 'package:web/web.dart' as web;

import 'customer_profile_screen.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final SupabaseClient _supabase = SupabaseService.client;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _customers = [];

  bool _loading = true;
  String? _error;

  String _riskFilter = 'All Risk';
  String _valueFilter = 'All Value';
  String _crossSellFilter = 'All Opportunities';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // EXPORT CSV
  // ============================================================

  Future<void> _exportCsv() async {
    try {
      dynamic query = _supabase.from('customers').select(
        'customer_id,account_type,number_of_products,'
        'churn_risk_score,churn_risk_level,'
        'customer_value_score,value_segment,'
        'cross_sell_score,cross_sell_opportunity,'
        'recommended_product,recommended_action',
      );

      final search = _searchController.text.trim();

      if (search.isNotEmpty) {
        query = query.ilike('customer_id', '%$search%');
      }

      if (_riskFilter != 'All Risk') {
        query = query.eq('churn_risk_level', _riskFilter);
      }

      if (_valueFilter == 'High Value') {
        query = query.eq('value_segment', 'High Value');
      }

      if (_crossSellFilter == 'High Opportunity') {
        query = query.eq('cross_sell_opportunity', 'High');
      }

      final List<Map<String, dynamic>> allCustomers = [];

      const pageSize = 1000;
      var offset = 0;

      while (true) {
        final page = await query
            .order('churn_risk_score', ascending: false)
            .range(offset, offset + pageSize - 1);

        final rows = List<Map<String, dynamic>>.from(page);

        allCustomers.addAll(rows);

        if (rows.length < pageSize) {
          break;
        }

        offset += pageSize;
      }

      if (allCustomers.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No customer data available to export.'),
          ),
        );

        return;
      }

      final headers = [
        'Customer ID',
        'Account Type',
        'Number of Products',
        'Churn Score',
        'Churn Risk',
        'Customer Value Score',
        'Value Segment',
        'Cross-Sell Score',
        'Cross-Sell Opportunity',
        'Recommended Product',
        'Recommended Action',
      ];

      String csvValue(dynamic value) {
        final text = value?.toString() ?? '';

        if (text.contains(',') ||
            text.contains('"') ||
            text.contains('\n')) {
          return '"${text.replaceAll('"', '""')}"';
        }

        return text;
      }

      final buffer = StringBuffer();

      buffer.writeln(headers.map(csvValue).join(','));

      for (final customer in allCustomers) {
        final row = [
          customer['customer_id'],
          customer['account_type'],
          customer['number_of_products'],
          customer['churn_risk_score'],
          customer['churn_risk_level'],
          customer['customer_value_score'],
          customer['value_segment'],
          customer['cross_sell_score'],
          customer['cross_sell_opportunity'],
          customer['recommended_product'],
          customer['recommended_action'],
        ];

        buffer.writeln(row.map(csvValue).join(','));
      }

      final bytes = utf8.encode(buffer.toString());

      // Modern Flutter Web download API.
      final blob = web.Blob(
        [bytes.toJS].toJS,
        web.BlobPropertyBag(
          type: 'text/csv;charset=utf-8',
        ),
      );

      final url = web.URL.createObjectURL(blob);

      final anchor =
          web.document.createElement('a') as web.HTMLAnchorElement;

      anchor.href = url;
      anchor.download =
          'finsight_customers_${DateTime.now().millisecondsSinceEpoch}.csv';

      web.document.body?.appendChild(anchor);

      anchor.click();

      anchor.remove();

      web.URL.revokeObjectURL(url);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${allCustomers.length} customers exported successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
        ),
      );
    }
  }

  // ============================================================
  // LOAD CUSTOMERS
  // ============================================================

  Future<void> _loadCustomers() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      var query = _supabase.from('customers').select('''
        customer_id,
        account_type,
        number_of_products,
        churn_risk_score,
        churn_risk_level,
        customer_value_score,
        value_segment,
        cross_sell_score,
        cross_sell_opportunity,
        recommended_product,
        recommended_action
      ''');

      final search = _searchController.text.trim();

      if (search.isNotEmpty) {
        query = query.ilike('customer_id', '%$search%');
      }

      if (_riskFilter != 'All Risk') {
        query = query.eq('churn_risk_level', _riskFilter);
      }

      if (_valueFilter == 'High Value') {
        query = query.eq('value_segment', 'High Value');
      }

      if (_crossSellFilter == 'High Opportunity') {
        query = query.eq('cross_sell_opportunity', 'High');
      }

      final data = await query
          .order('churn_risk_score', ascending: false)
          .range(0, 99);

      if (!mounted) return;

      setState(() {
        _customers = List<Map<String, dynamic>>.from(data);
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

  // ============================================================
  // FILTERS
  // ============================================================

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _riskFilter = 'All Risk';
      _valueFilter = 'All Value';
      _crossSellFilter = 'All Opportunities';
    });

    _loadCustomers();
  }

  String _formatScore(dynamic value) {
    final number = (value as num?)?.toDouble() ?? 0;

    return '${(number * 100).round()}%';
  }

  String _profileText(Map<String, dynamic> customer) {
    final accountType = customer['account_type'] ?? 'Unknown';
    final products = customer['number_of_products'] ?? 0;

    return '$accountType • $products '
        '${products == 1 ? 'product' : 'products'}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customers',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Search customers and review the next best action.',
                      style: TextStyle(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              // EXPORT BUTTON
              FilledButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(
                  Icons.download_outlined,
                  size: 18,
                ),
                label: const Text('Export CSV'),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ====================================================
          // SEARCH
          // ====================================================

          TextField(
            controller: _searchController,
            onSubmitted: (_) => _loadCustomers(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by customer ID',
              suffixIcon: IconButton(
                tooltip: 'Search',
                onPressed: _loadCustomers,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ====================================================
          // FILTERS
          // ====================================================

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FilterDropdown(
                value: _riskFilter,
                items: const [
                  'All Risk',
                  'High',
                  'Medium',
                  'Low',
                ],
                onChanged: (value) {
                  setState(() {
                    _riskFilter = value;
                  });

                  _loadCustomers();
                },
              ),

              _FilterDropdown(
                value: _valueFilter,
                items: const [
                  'All Value',
                  'High Value',
                ],
                onChanged: (value) {
                  setState(() {
                    _valueFilter = value;
                  });

                  _loadCustomers();
                },
              ),

              _FilterDropdown(
                value: _crossSellFilter,
                items: const [
                  'All Opportunities',
                  'High Opportunity',
                ],
                onChanged: (value) {
                  setState(() {
                    _crossSellFilter = value;
                  });

                  _loadCustomers();
                },
              ),

              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(
                  Icons.clear,
                  size: 17,
                ),
                label: const Text('Clear'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ====================================================
          // LOADING
          // ====================================================

          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            )

          // ====================================================
          // ERROR
          // ====================================================

          else if (_error != null)
            _ErrorCard(
              message: _error!,
              onRetry: _loadCustomers,
            )

          // ====================================================
          // EMPTY
          // ====================================================

          else if (_customers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 42,
                        color: AppColors.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No customers found',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Try changing the search or filters.',
                        style: TextStyle(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )

          // ====================================================
          // CUSTOMER TABLE
          // ====================================================

          else
            Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 28,
                  headingRowHeight: 52,
                  dataRowMinHeight: 68,
                  dataRowMaxHeight: 78,
                  columns: const [
                    DataColumn(
                      label: Text('Customer'),
                    ),
                    DataColumn(
                      label: Text('Profile'),
                    ),
                    DataColumn(
                      label: Text('Risk'),
                    ),
                    DataColumn(
                      label: Text('Value'),
                    ),
                    DataColumn(
                      label: Text('Cross-sell'),
                    ),
                    DataColumn(
                      label: Text('Next action'),
                    ),
                  ],
                  rows: _customers.map((customer) {
                    final customerId =
                        customer['customer_id']?.toString() ?? 'Unknown';

                    final riskScore =
                        _formatScore(customer['churn_risk_score']);

                    final valueScore =
                        _formatScore(customer['customer_value_score']);

                    final crossSell =
                        customer['cross_sell_opportunity']?.toString() ??
                            'None';

                    final action =
                        customer['recommended_action']?.toString() ??
                            'Review customer';

                    return DataRow(
                      onSelectChanged: (selected) {
                        if (selected != true) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomerProfileScreen(
                              customerId: customerId,
                            ),
                          ),
                        );
                      },
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                customer['value_segment']?.toString() ??
                                    'Standard',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            _profileText(customer),
                          ),
                        ),
                        DataCell(
                          _RiskBadge(
                            value: riskScore,
                            level:
                                customer['churn_risk_level']?.toString(),
                          ),
                        ),
                        DataCell(
                          _ScoreBadge(
                            value: valueScore,
                            isPositive:
                                customer['value_segment'] == 'High Value',
                          ),
                        ),
                        DataCell(
                          _OpportunityBadge(
                            value: crossSell,
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 210,
                            child: Text(
                              action,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 12),

          if (!_loading && _customers.isNotEmpty)
            Text(
              'Showing ${_customers.length} customers',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.muted,
              ),
            ),
        ],
      ),
    );
  }
}

// ================================================================
// FILTER DROPDOWN
// ================================================================

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.border,
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}

// ================================================================
// RISK BADGE
// ================================================================

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({
    required this.value,
    required this.level,
  });

  final String value;
  final String? level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      'High' => AppColors.red,
      'Medium' => AppColors.amber,
      'Low' => AppColors.green,
      _ => AppColors.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ================================================================
// SCORE BADGE
// ================================================================

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({
    required this.value,
    required this.isPositive,
  });

  final String value;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.green : AppColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ================================================================
// OPPORTUNITY BADGE
// ================================================================

class _OpportunityBadge extends StatelessWidget {
  const _OpportunityBadge({
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    final isHigh = value == 'High';
    final color = isHigh ? AppColors.amber : AppColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ================================================================
// ERROR CARD
// ================================================================

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load customers',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}