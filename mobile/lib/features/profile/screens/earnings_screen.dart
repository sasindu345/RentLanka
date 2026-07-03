import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/api/api_client.dart';
import 'package:mobile/core/api/bookings_api.dart';
import 'package:mobile/core/api/listings_api.dart';
import 'package:mobile/core/theme/app_spacing.dart';
import 'package:mobile/core/theme/app_radius.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.sheet),
          topRight: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Withdraw Earnings',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available Balance: ${ListingsApi.formatPrice(available)}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Amount
                  Text('Withdrawal Amount (LKR)', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 5000',
                      prefixIcon: Icon(LucideIcons.creditCard, size: 18),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter an amount';
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) return 'Please enter a valid amount';
                      if (amount > available) return 'Insufficient available balance';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Bank Name
                  Text('Bank Name', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Hatton National Bank',
                      prefixIcon: Icon(LucideIcons.landmark, size: 18),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please enter bank name';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Account Number
                  Text('Account Number', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _accountNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1020304050',
                      prefixIcon: Icon(LucideIcons.hash, size: 18),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please enter account number';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  // Account Name
                  Text('Account Name', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _accountNameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. A.B.C. Perera',
                      prefixIcon: Icon(LucideIcons.user, size: 18),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Please enter account name';
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _submittingPayout ? null : _submitPayout,
                    child: _submittingPayout
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Payout Request'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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

  Color _getPayoutStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'paid':
        return Colors.green;
      case 'rejected':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Host Earnings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final earnings = _earnings;
    if (earnings == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('Host Earnings')),
        body: const Center(child: Text('Unable to load earnings.')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Host Earnings'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEarnings,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Balance Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE BALANCE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ListingsApi.formatPrice(earnings.availableBalance),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Earned',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ListingsApi.formatPrice(earnings.totalEarned),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Escrow Balance',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ListingsApi.formatPrice(earnings.escrowedBalance),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Withdraw Button
            FilledButton.icon(
              onPressed: earnings.availableBalance > 0 ? _showWithdrawModal : null,
              icon: const Icon(LucideIcons.arrowDown, size: 18),
              label: const Text('Withdraw Funds'),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Payout History Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Withdrawal History',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Icon(LucideIcons.history, color: theme.colorScheme.onSurfaceVariant, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Payout History List
            if (earnings.payouts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(
                    'No withdrawal requests yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...earnings.payouts.map((p) {
                final dateStr = '${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}';
                final statusColor = _getPayoutStatusColor(p.status, theme);
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.08),
                      child: Icon(
                        p.status.toLowerCase() == 'paid'
                            ? LucideIcons.check
                            : p.status.toLowerCase() == 'pending'
                                ? LucideIcons.clock
                                : LucideIcons.x,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      ListingsApi.formatPrice(p.amount),
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${p.bankName} · $dateStr'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Text(
                        p.status.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
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
