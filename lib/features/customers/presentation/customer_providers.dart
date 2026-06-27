import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/customer_repository.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  // Watch auth state to get the current user's UID
  final authState = ref.watch(authStateProvider).value;
  final uid = authState?.uid ?? '';
  return CustomerRepository(uid: uid);
});

final customersStreamProvider = StreamProvider<QuerySnapshot>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchCustomers();
});

final transactionsStreamProvider = StreamProvider.family<QuerySnapshot, String>(
  (ref, customerId) {
    final repository = ref.watch(customerRepositoryProvider);
    return repository.watchTransactions(customerId);
  },
);

final customerStreamProvider = StreamProvider.family<DocumentSnapshot, String>((
  ref,
  customerId,
) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.watchCustomer(customerId);
});
