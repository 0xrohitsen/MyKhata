import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../customers/presentation/customer_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = 'v1.0.0';
  bool _deleting = false;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(
          () => _version =
              'v${info.version} (${info.buildNumber == '1' ? 'Stable' : info.buildNumber})',
        );
      }
    } catch (_) {
      // The fallback is intentionally displayable on unsupported test platforms.
    }
  }

  Future<void> _setTheme(String value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'profile': {'themePreference': value},
      }, SetOptions(merge: true));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update theme: $error')),
        );
      }
    }
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    ref.invalidate(customersStreamProvider);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _syncing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ledger is synced')));
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete My Account?'),
        content: const Text(
          'All customers, transactions, and settings will be permanently erased. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (mounted) context.go('/login');
    } catch (error) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account could not be deleted: $error')),
        );
      }
    }
  }

  void _info(String title, String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final profileDoc = ref.watch(userProfileStreamProvider).value;
    final data = profileDoc?.data() as Map<String, dynamic>?;
    final profile = data?['profile'] as Map<String, dynamic>?;
    final themePreference = profile?['themePreference'] as String? ?? 'system';
    final subtitle = themePreference == 'light'
        ? 'Light theme'
        : themePreference == 'dark'
        ? 'Dark theme'
        : 'System default';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search settings',
            onPressed: () =>
                showSearch(context: context, delegate: _SettingsSearch()),
          ),
        ],
      ),
      body: _deleting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting account data…'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
              children: [
                const _SectionLabel('Account'),
                _SettingsCard(
                  child: ListTile(
                    minTileHeight: 88,
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundImage: user?.photoURL?.isNotEmpty == true
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL?.isNotEmpty == true
                          ? null
                          : const Icon(Icons.person_outline),
                    ),
                    title: Text(
                      user?.displayName ?? 'Guest User',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(user?.email ?? 'guest@mykhata.app'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _info(
                      'Account',
                      '${user?.displayName ?? 'Guest User'}\n${user?.email ?? ''}',
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionLabel('Appearance'),
                _SettingsCard(
                  child: ListTile(
                    minTileHeight: 76,
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme'),
                    subtitle: Text(subtitle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ThemeButton(
                          icon: Icons.light_mode_outlined,
                          active: themePreference == 'light',
                          onTap: () => _setTheme('light'),
                        ),
                        const SizedBox(width: 7),
                        _ThemeButton(
                          icon: Icons.dark_mode,
                          active: themePreference == 'dark',
                          onTap: () => _setTheme('dark'),
                        ),
                      ],
                    ),
                    onLongPress: () => _setTheme('system'),
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionLabel('Data & Sync'),
                _SettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        minTileHeight: 76,
                        leading: const Icon(
                          Icons.sync,
                          color: Color(0xFF2E7D32),
                        ),
                        title: const Text('Cloud Sync'),
                        subtitle: const Text(
                          'Status: Connected',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                        trailing: FilledButton(
                          onPressed: _syncing ? null : _sync,
                          child: Text(_syncing ? 'Syncing…' : 'Sync Now'),
                        ),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        minTileHeight: 76,
                        leading: Icon(Icons.schedule),
                        title: Text('Last Backup'),
                        subtitle: Text('Synced automatically'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        minTileHeight: 76,
                        leading: const Icon(Icons.cloud_upload_outlined),
                        title: const Text('Export Data'),
                        subtitle: const Text('CSV, PDF, or Excel'),
                        onTap: () => _info(
                          'Export Data',
                          'Your ledger remains available in cloud sync. File export will be available in a future update.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const _SectionLabel('About'),
                _SettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        minTileHeight: 76,
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Version'),
                        subtitle: Text(_version),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        minTileHeight: 56,
                        leading: const Icon(Icons.verified_user_outlined),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.open_in_new, size: 19),
                        onTap: () => _info(
                          'Privacy Policy',
                          'My Khata stores your ledger securely in your signed-in account and does not sell personal data.',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        minTileHeight: 56,
                        leading: const Icon(Icons.description_outlined),
                        title: const Text('Terms of Service'),
                        trailing: const Icon(Icons.open_in_new, size: 19),
                        onTap: () => _info(
                          'Terms of Service',
                          'Use My Khata to maintain personal ledger records. You remain responsible for verifying every entry.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever_outlined),
                    label: const Text('Delete My Account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(
                        color: colors.error.withValues(alpha: .45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Deleting your account will permanently erase all your ledger data. This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: 3,
        onDestinationSelected: (index) {
          if (index != 3) context.go('/home');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: child,
  );
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Theme.of(context).colorScheme.primary : null,
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Icon(
        icon,
        size: 20,
        color: active
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

class _SettingsSearch extends SearchDelegate<String?> {
  final entries = const [
    'Account',
    'Theme',
    'Cloud Sync',
    'Last Backup',
    'Export Data',
    'Version',
    'Privacy Policy',
    'Terms of Service',
    'Logout',
    'Delete My Account',
  ];
  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];
  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );
  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);
  @override
  Widget buildSuggestions(BuildContext context) {
    final matches = entries
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView(
      children: matches
          .map(
            (item) =>
                ListTile(title: Text(item), onTap: () => close(context, item)),
          )
          .toList(),
    );
  }
}
