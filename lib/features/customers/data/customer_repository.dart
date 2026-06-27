import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerRepository {
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CustomerRepository({required this.uid});

  // Reference to user's customers subcollection
  CollectionReference get _customersRef =>
      _firestore.collection('users').doc(uid).collection('customers');

  // Watch all customers for the current user
  Stream<QuerySnapshot> watchCustomers() {
    if (uid.isEmpty) return const Stream.empty();
    return _customersRef.orderBy('updatedAt', descending: true).snapshots();
  }

  // Fetch single customer
  Future<DocumentSnapshot> fetchCustomer(String id) {
    return _customersRef.doc(id).get();
  }

  // Watch single customer for live balance updates
  Stream<DocumentSnapshot> watchCustomer(String id) {
    return _customersRef.doc(id).snapshots();
  }

  // Add a new customer
  Future<DocumentReference> addCustomer({
    required String name,
    String? phone,
    String? notes,
  }) {
    final now = Timestamp.now();
    return _customersRef.add({
      'name': name,
      'phone': phone,
      'notes': notes,
      'balance': 0, // balance in paise (integer)
      'createdAt': now,
      'updatedAt': now,
      'lastTxNote': 'Customer added',
      'lastTxTime': now,
    });
  }

  // Delete a customer along with their transactions subcollection
  Future<void> deleteCustomer(String customerId) async {
    // Delete all transactions under the customer first
    final transactions = await _customersRef
        .doc(customerId)
        .collection('transactions')
        .get();
    final batch = _firestore.batch();
    for (final doc in transactions.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_customersRef.doc(customerId));
    await batch.commit();
  }

  // Watch transactions for a customer
  Stream<QuerySnapshot> watchTransactions(String customerId) {
    if (uid.isEmpty) return const Stream.empty();
    return _customersRef
        .doc(customerId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add a transaction and atomically update customer's balance
  Future<void> addTransaction({
    required String customerId,
    required String type, // 'gave' or 'got'
    required int amountInPaise,
    String? note,
  }) async {
    final customerDocRef = _customersRef.doc(customerId);
    final transactionCollectionRef = customerDocRef.collection('transactions');
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      // 1. Read customer current balance
      final customerSnapshot = await transaction.get(customerDocRef);
      if (!customerSnapshot.exists) {
        throw Exception("Customer does not exist!");
      }

      final currentBalance =
          (customerSnapshot.data() as Map<String, dynamic>)['balance']
              as int? ??
          0;

      // 2. Calculate new balance: balance = Σ(gave) - Σ(got)
      int balanceDelta = amountInPaise;
      if (type == 'got') {
        balanceDelta = -amountInPaise;
      }
      final newBalance = currentBalance + balanceDelta;

      // 3. Write transaction document
      final newTransactionRef = transactionCollectionRef.doc();
      transaction.set(newTransactionRef, {
        'type': type,
        'amount': amountInPaise,
        'note': note,
        'createdAt': now,
      });

      // 4. Update customer balance and cache last transaction metadata
      transaction.update(customerDocRef, {
        'balance': newBalance,
        'updatedAt': now,
        'lastTxNote': note ?? (type == 'gave' ? 'Gave money' : 'Got money'),
        'lastTxTime': now,
      });
    });
  }

  // Edit a transaction and atomically update customer's balance
  Future<void> updateTransaction({
    required String customerId,
    required String transactionId,
    required String type,
    required int amountInPaise,
    String? note,
    required String oldType,
    required int oldAmountInPaise,
  }) async {
    final customerDocRef = _customersRef.doc(customerId);
    final transactionDocRef = customerDocRef
        .collection('transactions')
        .doc(transactionId);
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      final customerSnapshot = await transaction.get(customerDocRef);
      if (!customerSnapshot.exists) {
        throw Exception("Customer does not exist!");
      }

      final currentBalance =
          (customerSnapshot.data() as Map<String, dynamic>)['balance']
              as int? ??
          0;

      // Reverse old transaction balance change
      int oldBalanceDelta = oldAmountInPaise;
      if (oldType == 'got') {
        oldBalanceDelta = -oldAmountInPaise;
      }
      int tempBalance = currentBalance - oldBalanceDelta;

      // Apply new transaction balance change
      int newBalanceDelta = amountInPaise;
      if (type == 'got') {
        newBalanceDelta = -amountInPaise;
      }
      final newBalance = tempBalance + newBalanceDelta;

      // Update transaction document
      transaction.update(transactionDocRef, {
        'type': type,
        'amount': amountInPaise,
        'note': note,
      });

      // Update customer balance and cache last transaction metadata
      transaction.update(customerDocRef, {
        'balance': newBalance,
        'updatedAt': now,
        'lastTxNote': note ?? (type == 'gave' ? 'Gave money' : 'Got money'),
        'lastTxTime': now,
      });
    });
  }

  // Delete a transaction and atomically update customer's balance
  Future<void> deleteTransaction({
    required String customerId,
    required String transactionId,
    required String type,
    required int amountInPaise,
  }) async {
    final customerDocRef = _customersRef.doc(customerId);
    final transactionDocRef = customerDocRef
        .collection('transactions')
        .doc(transactionId);
    final now = Timestamp.now();

    await _firestore.runTransaction((transaction) async {
      final customerSnapshot = await transaction.get(customerDocRef);
      if (!customerSnapshot.exists) {
        throw Exception("Customer does not exist!");
      }

      final currentBalance =
          (customerSnapshot.data() as Map<String, dynamic>)['balance']
              as int? ??
          0;

      // Reverse transaction balance change: balance = currentBalance - delta
      int balanceDelta = amountInPaise;
      if (type == 'got') {
        balanceDelta = -amountInPaise;
      }
      final newBalance = currentBalance - balanceDelta;

      // Delete transaction document
      transaction.delete(transactionDocRef);

      // Update customer balance and cache last transaction metadata
      transaction.update(customerDocRef, {
        'balance': newBalance,
        'updatedAt': now,
        'lastTxNote': 'Transaction deleted',
        'lastTxTime': now,
      });
    });
  }
}
