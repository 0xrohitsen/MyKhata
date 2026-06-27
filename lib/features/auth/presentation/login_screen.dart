import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _loadingMethod;

  Future<void> _signInWithGoogle() async {
    if (_loadingMethod != null) return;
    setState(() => _loadingMethod = 'google');
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign in failed: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMethod = null);
    }
  }



  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(.65, -.9),
            radius: 1.15,
            colors: dark
                ? const [Color(0xFF193238), Color(0xFF101212)]
                : const [Color(0xFFEAF6F8), Color(0xFFFAF9F9)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 34, 16, 18),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF1E4D55)
                        : const Color(0xFF13434B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'My Khata',
                  style: TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track Every Rupee',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: .4,
                    color: colors.onSurfaceVariant.withValues(alpha: .72),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 280,
                  height: 280,
                  padding: const EdgeInsets.all(31),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dark
                        ? const Color(0xFF1B1D1D)
                        : const Color(0xFFF1F0F0),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: .55),
                    ),
                  ),
                  child: ClipPath(
                    clipper: _SoftOctagonClipper(),
                    child: Image.asset(
                      'assets/images/wallet_illustration.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    onPressed: _loadingMethod == null
                        ? _signInWithGoogle
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      shape: const StadiumBorder(),
                    ),
                    child: _loadingMethod == 'google'
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _GoogleMark(),
                              SizedBox(width: 12),
                              Text(
                                'CONTINUE WITH GOOGLE',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .45,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 27,
    height: 27,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
    child: const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _SoftOctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const cut = 18.0;
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(cut, size.height)
      ..lineTo(0, size.height - cut)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
