import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

final userProfileStreamProvider = StreamProvider<DocumentSnapshot?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authState.uid)
      .snapshots();
});

final themePreferenceProvider = Provider<ThemeMode>((ref) {
  final profileSnapshot = ref.watch(userProfileStreamProvider).value;
  if (profileSnapshot == null || !profileSnapshot.exists) {
    return ThemeMode.system;
  }

  final data = profileSnapshot.data() as Map<String, dynamic>?;
  final profile = data?['profile'] as Map<String, dynamic>?;
  final themePref = profile?['themePreference'] as String? ?? 'system';

  if (themePref == 'light') return ThemeMode.light;
  if (themePref == 'dark') return ThemeMode.dark;
  return ThemeMode.system;
});
