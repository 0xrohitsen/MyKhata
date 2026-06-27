import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../customers/presentation/add_customer_screen.dart';
import '../../customers/presentation/customer_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _money(Object? value) => value is num ? value.round() : 0;

  String _currency(int paise) {
    final value = paise.abs() / 100;
    final raw = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return raw.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _ago(Object? value) {
    if (value is! Timestamp) {
      return 'No entries yet';
    }
    final diff = DateTime.now().difference(value.toDate());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} week${diff.inDays < 14 ? '' : 's'} ago';
    }
    return '${(diff.inDays / 30).floor()} month${diff.inDays < 60 ? '' : 's'} ago';
  }

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join()
      .toUpperCase();

  Color _avatarColor(String name, bool dark) {
    final light = [0xFFBCEAF4, 0xFFDCE1FF, 0xFFE3E2E2, 0xFFFFD9E3, 0xFFD9F0DD];
    final darkColors = [
      0xFF1E4D55,
      0xFF3F4660,
      0xFF40484A,
      0xFF633B48,
      0xFF285231,
    ];
    final values = dark ? darkColors : light;
    return Color(values[name.hashCode.abs() % values.length]);
  }

  void _addCustomer() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddCustomerScreen(),
  );

  void _showReports(List<QueryDocumentSnapshot> customers) {
    final balances = customers.map(
      (doc) => _money((doc.data() as Map<String, dynamic>)['balance']),
    );
    final receivable = balances
        .where((v) => v > 0)
        .fold<int>(0, (a, b) => a + b);
    final payable = balances
        .where((v) => v < 0)
        .fold<int>(0, (a, b) => a + b.abs());
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ledger Summary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: 'RECEIVABLE',
                      amount: '₹${_currency(receivable)}',
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      label: 'PAYABLE',
                      amount: '₹${_currency(payable)}',
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${customers.length} customers • Net ₹${_currency(receivable - payable)}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final customers = ref.watch(customersStreamProvider);
    return Scaffold(
      key: _scaffoldKey,
      drawer: _AppDrawer(
        onClose: () => _scaffoldKey.currentState?.closeDrawer(),
      ),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search customers',
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              )
            : const Text('My Khata'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Close search' : 'Search',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _query = '';
                _searchController.clear();
              }
            }),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: customers.when(
        data: (snapshot) {
          final all = snapshot.docs;
          final visible = all.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['name'] as String? ?? '').toLowerCase().contains(
              _query,
            );
          }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Row(
                  children: [
                    Text(
                      '${visible.length} Customer${visible.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showReports(all),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.chevron_right, size: 19),
                      label: const Text('View Reports'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? _EmptyCustomers(
                        searching: _query.isNotEmpty,
                        onAdd: _addCustomer,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final doc = visible[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] as String? ?? 'Unnamed';
                          final balance = _money(data['balance']);
                          final note = (data['lastTxNote'] as String?)?.trim();
                          final positive = balance > 0;
                          final negative = balance < 0;
                          final amountColor = positive
                              ? (dark
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFF2E7D32))
                              : negative
                              ? (dark
                                    ? const Color(0xFFEF9A9A)
                                    : const Color(0xFFC62828))
                              : colors.onSurfaceVariant;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => context.push('/customer/${doc.id}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: _avatarColor(name, dark),
                                    child: Text(
                                      _initials(name),
                                      style: TextStyle(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${_ago(data['lastTxTime'])}${note == null || note.isEmpty ? '' : ' • $note'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${positive
                                            ? '+'
                                            : negative
                                            ? '-'
                                            : ''}₹${_currency(balance)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: amountColor,
                                        ),
                                      ),
                                      Text(
                                        positive
                                            ? 'RECEIVABLE'
                                            : negative
                                            ? 'PAYABLE'
                                            : 'SETTLED',
                                        style: TextStyle(
                                          fontSize: 11,
                                          letterSpacing: .55,
                                          color: colors.onSurfaceVariant
                                              .withValues(alpha: .65),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: error.toString(),
          onRetry: () => ref.invalidate(customersStreamProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('+ Add Customer'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
      bottomNavigationBar: _BottomNav(
        selected: 0,
        onReports: () => customers.value == null
            ? null
            : _showReports(customers.value!.docs),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selected, required this.onReports});
  final int selected;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) => NavigationBar(
    height: 72,
    selectedIndex: selected,
    onDestinationSelected: (index) {
      if (index == 0 || index == 1) context.go('/home');
      if (index == 2) onReports();
      if (index == 3) context.go('/settings');
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Customers',
      ),
      NavigationDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment),
        label: 'Reports',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final String amount;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, letterSpacing: .5, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers({required this.searching, required this.onAdd});
  final bool searching;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searching ? Icons.search_off : Icons.menu_book_outlined,
            size: 58,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            searching ? 'No matching customers' : 'No customers yet',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Try a different name.'
                : 'Add your first customer to start a ledger.',
            textAlign: TextAlign.center,
          ),
          if (!searching) ...[
            const SizedBox(height: 18),
            FilledButton(onPressed: onAdd, child: const Text('Add Customer')),
          ],
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          const Text('Could not load customers'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.account_balance_wallet_rounded),
            title: Text(
              'My Khata',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: onClose,
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              onClose();
              context.go('/settings');
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    ),
  );
}
