import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'customer_providers.dart';

class CustomerDetailsScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  String _formatCurrency(int paise) {
    final rupees = paise / 100.0;
    if (paise % 100 == 0) {
      return rupees
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
    }
    return rupees
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dateTime.month - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12)
        .toString()
        .padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $ampm';
  }

  Color _getPastelBg(String name, bool isDark) {
    final h = name.hashCode;
    final light = [
      const Color(0xFFB2E8E8),
      const Color(0xFFD0E1FD),
      const Color(0xFFE2DDFE),
      const Color(0xFFFEDDF0),
      const Color(0xFFD1FAE5),
      const Color(0xFFFEF3C7),
    ];
    final dark = [
      const Color(0xFF0D4F4F),
      const Color(0xFF1E3A8A),
      const Color(0xFF5B21B6),
      const Color(0xFF9D174D),
      const Color(0xFF065F46),
      const Color(0xFF92400E),
    ];
    final list = isDark ? dark : light;
    return list[h.abs() % list.length];
  }

  void _showTransactionSheet(
    BuildContext context, {
    required String type,
    bool isEditing = false,
    String? transactionId,
    int? oldAmountInPaise,
    String? oldNote,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTransactionSheet(
        customerId: customerId,
        type: type,
        isEditing: isEditing,
        transactionId: transactionId,
        oldAmountInPaise: oldAmountInPaise,
        oldNote: oldNote,
      ),
    );
  }

  void _showOptionsSheet(
    BuildContext context,
    WidgetRef ref, {
    required String transactionId,
    required String type,
    required int amountInPaise,
    required String note,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF13434B),
              ),
              title: const Text(
                'Edit Record',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _showTransactionSheet(
                  context,
                  type: type,
                  isEditing: true,
                  transactionId: transactionId,
                  oldAmountInPaise: amountInPaise,
                  oldNote: note,
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFFBA1A1A),
              ),
              title: const Text(
                'Delete Record',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDelete(
                  context,
                  ref,
                  transactionId,
                  type,
                  amountInPaise,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
    String type,
    int amountInPaise,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Transaction?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This permanently deletes this record. The balance will update automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'DELETE',
              style: TextStyle(
                color: Color(0xFFBA1A1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(customerRepositoryProvider);
      try {
        await repo.deleteTransaction(
          customerId: customerId,
          transactionId: transactionId,
          type: type,
          amountInPaise: amountInPaise,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _deleteCustomer(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: const Text(
          'This deletes the customer and every transaction in this ledger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(customerRepositoryProvider).deleteCustomer(customerId);
      if (context.mounted) {
        context.go('/home');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete customer: $error')),
        );
      }
    }
  }

  void _showLedgerHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ledger records',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                'Transactions are shown newest first. Long-press a record to edit or delete it.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customerAsync = ref.watch(customerStreamProvider(customerId));
    final transactionsAsync = ref.watch(transactionsStreamProvider(customerId));

    final bgColor = isDark ? const Color(0xFF101212) : const Color(0xFFFAF9F9);
    final cardBg = isDark ? const Color(0xFF1B1D1D) : const Color(0xFFF4F3F3);
    final dividerColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFEEEEEE);
    final primaryTeal = isDark
        ? const Color(0xFF2DD4BF)
        : const Color(0xFF13434B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : const Color(0xFF13434B),
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Customer Details',
          style: TextStyle(
            fontFamily: 'Noto Sans',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF13434B),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: isDark ? Colors.white70 : const Color(0xFF40484A),
            ),
            tooltip: 'Ledger help',
            onPressed: () => _showLedgerHelp(context),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? Colors.white70 : const Color(0xFF40484A),
            ),
            onSelected: (value) {
              if (value == 'delete') {
                _deleteCustomer(context, ref);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 12),
                    Text('Delete customer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: customerAsync.when(
        data: (customerDoc) {
          final customerData = customerDoc.data() as Map<String, dynamic>?;
          if (customerData == null || !customerDoc.exists) {
            return const Center(child: Text('Customer not found.'));
          }
          final name = customerData['name'] as String? ?? 'Unnamed';
          final phone = customerData['phone'] as String? ?? '';
          final balance = (customerData['balance'] as num?)?.round() ?? 0;

          final initials = name
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase();
          final avatarBg = _getPastelBg(name, isDark);

          final isPositive = balance > 0;
          final isNegative = balance < 0;
          final balanceColor = isPositive
              ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
              : isNegative
              ? (isDark ? const Color(0xFFF87171) : const Color(0xFFBA1A1A))
              : (isDark ? const Color(0xFF64748B) : const Color(0xFF71787A));
          final balanceText = isPositive
              ? '+₹${_formatCurrency(balance)}'
              : isNegative
              ? '-₹${_formatCurrency(balance.abs())}'
              : '₹0';
          final balanceLabel = isPositive
              ? 'CUSTOMER SHOULD GIVE YOU'
              : isNegative
              ? 'YOU SHOULD GIVE CUSTOMER'
              : 'FULLY SETTLED';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer Header
              Container(
                color: bgColor,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: avatarBg,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontFamily: 'Noto Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1B1C1C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1B1C1C),
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF71787A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF40484A),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: dividerColor),

              // Balance Card
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                decoration: BoxDecoration(
                  color: primaryTeal.withValues(alpha: isDark ? .12 : .04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .7),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          balanceText,
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: balanceColor,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          balanceLabel,
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF71787A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: dividerColor),

              // Recent Transactions header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontFamily: 'Noto Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1B1C1C),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showLedgerHelp(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 16,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF71787A),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Filter',
                              style: TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF71787A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: transactionsAsync.when(
                  data: (txSnapshot) {
                    final docs = txSnapshot.docs;
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 48,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No transactions recorded yet.',
                              style: TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: docs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == docs.length) {
                          // End of Ledger footer
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 36,
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'End of Ledger',
                                  style: TextStyle(
                                    fontFamily: 'Noto Sans',
                                    fontSize: 13,
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFC0C8CA),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final txDoc = docs[index];
                        final txData = txDoc.data() as Map<String, dynamic>;
                        final type = txData['type'] as String? ?? 'gave';
                        final amount = (txData['amount'] as num?)?.round() ?? 0;
                        final note = txData['note'] as String? ?? '';
                        final timestamp = txData['createdAt'] as Timestamp?;
                        final dateString = timestamp != null
                            ? _formatDateTime(timestamp.toDate())
                            : '';

                        final isGave = type == 'gave';
                        // I Gave = you gave to customer (outflow) = red arrow up
                        // I Got = you received from customer (inflow) = green arrow down
                        final Color txColor = isGave
                            ? (isDark
                                  ? const Color(0xFFEF9A9A)
                                  : const Color(0xFFC62828))
                            : (isDark
                                  ? const Color(0xFF81C784)
                                  : const Color(0xFF2E7D32));
                        final IconData arrowIcon = isGave
                            ? Icons.arrow_upward
                            : Icons.arrow_downward;
                        final String txLabel = isGave ? 'I Gave' : 'I Got';
                        final String amountText = '₹${_formatCurrency(amount)}';

                        return GestureDetector(
                          onLongPress: () => _showOptionsSheet(
                            context,
                            ref,
                            transactionId: txDoc.id,
                            type: type,
                            amountInPaise: amount,
                            note: note,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF0F0F0),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                // Arrow Icon Circle
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: txColor.withValues(
                                      alpha: isDark ? 0.2 : 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    arrowIcon,
                                    color: txColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Label + note + date
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            txLabel,
                                            style: TextStyle(
                                              fontFamily: 'Noto Sans',
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1B1C1C),
                                            ),
                                          ),
                                          if (note.isEmpty) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFFF0F4FF),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'CASH',
                                                style: TextStyle(
                                                  fontFamily: 'Noto Sans',
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF5B617D),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        note.isNotEmpty
                                            ? '$dateString • $note'
                                            : dateString,
                                        style: TextStyle(
                                          fontFamily: 'Noto Sans',
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF64748B)
                                              : const Color(0xFF71787A),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Amount
                                Text(
                                  amountText,
                                  style: TextStyle(
                                    fontFamily: 'Noto Sans',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: txColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),

              // Bottom Action Buttons
              Container(
                color: isDark ? Colors.black : Colors.white,
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showTransactionSheet(context, type: 'gave'),
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text(
                          'I GAVE',
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF450A0A)
                              : const Color(0xFFFEF2F2),
                          foregroundColor: isDark
                              ? const Color(0xFFF87171)
                              : const Color(0xFFBA1A1A),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF7F1D1D)
                                  : const Color(0xFFFCA5A5),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _showTransactionSheet(context, type: 'got'),
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text(
                          'I GOT',
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? const Color(0xFF042F2E)
                              : const Color(0xFFF0FDF9),
                          foregroundColor: isDark
                              ? const Color(0xFF2DD4BF)
                              : const Color(0xFF13434B),
                          elevation: 0,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF134E4A)
                                  : const Color(0xFF99F6E4),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ── Add/Edit Transaction Bottom Sheet ─────────────────────────────────────────

class _AddTransactionSheet extends ConsumerStatefulWidget {
  final String customerId;
  final String type;
  final bool isEditing;
  final String? transactionId;
  final int? oldAmountInPaise;
  final String? oldNote;

  const _AddTransactionSheet({
    required this.customerId,
    required this.type,
    this.isEditing = false,
    this.transactionId,
    this.oldAmountInPaise,
    this.oldNote,
  });

  @override
  ConsumerState<_AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      if (widget.oldAmountInPaise != null) {
        _amountController.text = (widget.oldAmountInPaise! / 100.0)
            .toStringAsFixed(widget.oldAmountInPaise! % 100 == 0 ? 0 : 2);
      }
      _noteController.text = widget.oldNote ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);

    final amountDouble = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final amountInPaise = (amountDouble * 100).round();
    final note = _noteController.text.trim();
    final repo = ref.read(customerRepositoryProvider);

    try {
      if (widget.isEditing) {
        await repo.updateTransaction(
          customerId: widget.customerId,
          transactionId: widget.transactionId!,
          type: widget.type,
          amountInPaise: amountInPaise,
          note: note.isNotEmpty ? note : null,
          oldType: widget.type,
          oldAmountInPaise: widget.oldAmountInPaise!,
        );
      } else {
        await repo.addTransaction(
          customerId: widget.customerId,
          type: widget.type,
          amountInPaise: amountInPaise,
          note: note.isNotEmpty ? note : null,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGave = widget.type == 'gave';
    final themeColor = isGave
        ? (isDark ? const Color(0xFFF87171) : const Color(0xFFBA1A1A))
        : (isDark ? const Color(0xFF2DD4BF) : const Color(0xFF13434B));
    final title = widget.isEditing
        ? 'Edit Record'
        : isGave
        ? 'Record I Gave'
        : 'Record I Got';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111827) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Noto Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: themeColor,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: 'Noto Sans',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (₹) *',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                    ),
                    prefixIcon: Icon(Icons.currency_rupee, color: themeColor),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: themeColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final amt = double.tryParse(v.trim());
                    if (amt == null || amt <= 0) {
                      return 'Enter a valid amount greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  maxLength: 150,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontFamily: 'Noto Sans',
                  ),
                  decoration: InputDecoration(
                    labelText: 'Add Note (Optional)',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
                    ),
                    prefixIcon: Icon(
                      Icons.edit_note,
                      color: isDark ? const Color(0xFF64748B) : Colors.grey,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: themeColor, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: themeColor, width: 1.5),
                          foregroundColor: themeColor,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Record',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
