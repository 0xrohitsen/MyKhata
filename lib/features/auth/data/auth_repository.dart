import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    // 1. Initialize Google Sign-In via initialize() in v7.x
    // We pass the Web Client ID generated from Firebase to avoid clientConfigurationError.
    await _googleSignIn.initialize(
      serverClientId:
          '970356686968-ikc1okre4rkr00jvlg6oul85il7863gc.apps.googleusercontent.com',
    );

    // 2. Trigger Google Sign-In via authenticate()
    final googleUser = await _googleSignIn.authenticate();

    // 3. Fetch authentication tokens
    final googleAuth = googleUser.authentication;
    if (googleAuth.idToken == null) {
      throw Exception('Google sign-in failed: ID Token is null.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // 4. Authenticate with Firebase Auth
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      // 5. Initialize user profile in Firestore if it doesn't exist
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final profileSnapshot = await userDocRef.get();

      if (!profileSnapshot.exists) {
        await userDocRef.set({
          'profile': {
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL ?? '',
            'themePreference': 'system', // default value
            'createdAt': FieldValue.serverTimestamp(),
          },
        });
      }
    }

    return userCredential;
  }

  Future<UserCredential> signInAnonymously() async {
    final userCredential = await _auth.signInAnonymously();
    final user = userCredential.user;

    if (user != null) {
      final userDocRef = _firestore.collection('users').doc(user.uid);
      final profileSnapshot = await userDocRef.get();

      if (!profileSnapshot.exists) {
        await userDocRef.set({
          'profile': {
            'name': 'Guest User',
            'email': 'guest@mykhata.ask',
            'photoUrl': '',
            'themePreference': 'system',
            'createdAt': FieldValue.serverTimestamp(),
          },
        });
      }
    }

    return userCredential;
  }

  Future<void> signOut() async {
    final wasAnonymous = _auth.currentUser?.isAnonymous ?? false;
    await _auth.signOut();
    if (!wasAnonymous) {
      await _googleSignIn.signOut();
    }
  }

  // Recursive delete user account & data (Play Store Compliance)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final userDocRef = _firestore.collection('users').doc(uid);

    // 1. Fetch all customer docs
    final customersSnapshot = await userDocRef.collection('customers').get();

    final batch = _firestore.batch();

    // 2. Queue deletion for all transactions and customers
    for (final customerDoc in customersSnapshot.docs) {
      final transactionsSnapshot = await customerDoc.reference
          .collection('transactions')
          .get();
      for (final transactionDoc in transactionsSnapshot.docs) {
        batch.delete(transactionDoc.reference);
      }
      batch.delete(customerDoc.reference);
    }

    // 3. Delete user root profile doc
    batch.delete(userDocRef);

    // 4. Commit the Firestore batch
    await batch.commit();

    // 5. Delete from Firebase Authentication
    await user.delete();

    // 6. Sign out from Google to clean session
    if (!user.isAnonymous) {
      await _googleSignIn.signOut();
    }
  }
}
