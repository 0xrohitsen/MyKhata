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
  void addCustomer({
    required String name,
    String? phone,
    String? notes,
  }) {
    final now = Timestamp.now();
    _customersRef.add({
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
  void deleteCustomer(String customerId) {
    _customersRef.doc(customerId).collection('transactions').get().then((transactions) {
      final batch = _firestore.batch();
      for (final doc in transactions.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_customersRef.doc(customerId));
      batch.commit().catchError((_) {});
    }).catchError((_) {});
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
  void addTransaction({
    required String customerId,
    required String type, // 'gave' or 'got'
    required int amountInPaise,
    String? note,
  }) {
    final customerDocRef = _customersRef.doc(customerId);
    final transactionCollectionRef = customerDocRef.collection('transactions');
    final now = Timestamp.now();
    final batch = _firestore.batch();

    int balanceDelta = amountInPaise;
    if (type == 'got') {
      balanceDelta = -amountInPaise;
    }

    final newTransactionRef = transactionCollectionRef.doc();
    batch.set(newTransactionRef, {
      'type': type,
      'amount': amountInPaise,
      'note': note,
      'createdAt': now,
    });

    batch.update(customerDocRef, {
      'balance': FieldValue.increment(balanceDelta),
      'updatedAt': now,
      'lastTxNote': note ?? (type == 'gave' ? 'Gave money' : 'Got money'),
      'lastTxTime': now,
    });

    batch.commit().catchError((_) {});
  }

  // Edit a transaction and atomically update customer's balance
  void updateTransaction({
    required String customerId,
    required String transactionId,
    required String type,
    required int amountInPaise,
    String? note,
    required String oldType,
    required int oldAmountInPaise,
  }) {
    final customerDocRef = _customersRef.doc(customerId);
    final transactionDocRef = customerDocRef.collection('transactions').doc(transactionId);
    final now = Timestamp.now();
    final batch = _firestore.batch();

    // Reverse old transaction balance change
    int oldBalanceDelta = oldAmountInPaise;
    if (oldType == 'got') {
      oldBalanceDelta = -oldAmountInPaise;
    }

    // Apply new transaction balance change
    int newBalanceDelta = amountInPaise;
    if (type == 'got') {
      newBalanceDelta = -amountInPaise;
    }
    
    // Net change to apply to current balance
    final netDelta = newBalanceDelta - oldBalanceDelta;

    batch.update(transactionDocRef, {
      'type': type,
      'amount': amountInPaise,
      'note': note,
    });

    batch.update(customerDocRef, {
      'balance': FieldValue.increment(netDelta),
      'updatedAt': now,
      'lastTxNote': note ?? (type == 'gave' ? 'Gave money' : 'Got money'),
      'lastTxTime': now,
    });

    batch.commit().catchError((_) {});
  }

  // Delete a transaction and atomically update customer's balance
  void deleteTransaction({
    required String customerId,
    required String transactionId,
    required String type,
    required int amountInPaise,
  }) {
    final customerDocRef = _customersRef.doc(customerId);
    final transactionDocRef = customerDocRef.collection('transactions').doc(transactionId);
    final now = Timestamp.now();
    final batch = _firestore.batch();

    int balanceDelta = amountInPaise;
    if (type == 'got') {
      balanceDelta = -amountInPaise;
    }

    batch.delete(transactionDocRef);

    batch.update(customerDocRef, {
      'balance': FieldValue.increment(-balanceDelta),
      'updatedAt': now,
      'lastTxNote': 'Transaction deleted',
      'lastTxTime': now,
    });

    batch.commit().catchError((_) {});
  }
}
