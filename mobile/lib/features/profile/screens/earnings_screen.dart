import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/theme/app_theme.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  EarningsResponse? _earnings;
  bool _loading = true;
  bool _submittingPayout = false;

  // Controller fields for Payout form
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _loadEarnings() async {
    setState(() => _loading = true);
    try {
      final data = await ref.read(bookingsApiProvider).getMyEarnings();
      setState(() {
        _earnings = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load earnings dashboard.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showWithdrawModal() {
    final available = _earnings?.availableBalance ?? 0.0;
    _amountController.text = available.toStringAsFixed(0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Withdraw Earnings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available Balance: ${ListingsApi.formatPrice(available)}',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Withdrawal Amount (LKR)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter an amount';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'Please enter a valid amount';
                      if (amount > available) return 'Insufficient available balance';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      labelText: 'Bank Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please enter bank name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Account Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.pin),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please enter account number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _accountNameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please enter account name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submittingPayout ? null : _submitPayout,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppTheme.primary,
                    ),
                    child: _submittingPayout
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Payout Request'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitPayout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submittingPayout = true);
    Navigator.pop(context); // Close bottom sheet first

    try {
      final amount = double.parse(_amountController.text);
      await ref.read(bookingsApiProvider).requestPayout(
            amount: amount,
            bankName: _bankNameController.text,
            accountNumber: _accountNumberController.text,
            accountName: _accountNameController.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout request submitted successfully! Wait for admin approval.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadEarnings();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(extractError(e)), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingPayout = false);
    }
  }

  Color _getPayoutStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final earnings = _earnings;
    if (earnings == null) {
      return const Scaffold(body: Center(child: Text('Unable to load earnings.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Earnings'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEarnings,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Balance Cards
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF1E3C72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ListingsApi.formatPrice(earnings.availableBalance),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Earned', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            ListingsApi.formatPrice(earnings.totalEarned),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Escrow Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            ListingsApi.formatPrice(earnings.escrowedBalance),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Withdraw Button
            FilledButton.icon(
              onPressed: earnings.availableBalance > 0 ? _showWithdrawModal : null,
              icon: const Icon(Icons.arrow_downward),
              label: const Text('Withdraw Funds'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Payout History Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Withdrawal History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Icon(Icons.history, color: AppTheme.muted),
              ],
            ),
            const SizedBox(height: 12),

            // Payout History List
            if (earnings.payouts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No withdrawal requests yet.',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                ),
              )
            else
              ...earnings.payouts.map((p) {
                final dateStr = '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getPayoutStatusColor(p.status).withOpacity(0.1),
                      child: Icon(
                        p.status.toLowerCase() == 'paid'
                            ? Icons.check
                            : p.status.toLowerCase() == 'pending'
                                ? Icons.pending_outlined
                                : Icons.close,
                        color: _getPayoutStatusColor(p.status),
                      ),
                    ),
                    title: Text(
                      '${ListingsApi.formatPrice(p.amount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${p.bankName} · $dateStr'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPayoutStatusColor(p.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p.status,
                        style: TextStyle(
                          color: _getPayoutStatusColor(p.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
