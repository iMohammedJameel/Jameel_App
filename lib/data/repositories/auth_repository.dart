import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jameel/models/user_model.dart';

/// All Firebase Auth / employee-profile access lives here so that cubits and
/// screens never talk to Firebase directly.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _authOverride = auth,
        _firestoreOverride = firestore,
        _googleSignInOverride = googleSignIn;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final GoogleSignIn? _googleSignInOverride;
  Future<void>? _googleInitFuture;

  // Resolved lazily so constructing the repository never throws when Firebase
  // failed to initialise (the error then surfaces on the first real call).
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn =>
      _googleSignInOverride ?? GoogleSignIn.instance;

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= _googleSignIn.initialize();
  }

  /// Signs in and returns the employee profile.
  ///
  /// If the profile cannot be loaded the user is signed out again, so we never
  /// end up authenticated in Firebase but without a usable local session.
  Future<JameelUserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'user-not-found');
    }
    try {
      return await _fetchProfile(
        uid,
        credential.user?.email ?? email,
        fallbackName: credential.user?.displayName,
        photoUrl: credential.user?.photoURL,
      );
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  /// Signs in with Google and returns the employee profile, or `null` if the
  /// user canceled the account picker.
  Future<JameelUserModel?> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }

    final oauthCredential = GoogleAuthProvider.credential(idToken: idToken);
    final credential = await _auth.signInWithCredential(oauthCredential);
    final uid = credential.user?.uid;
    if (uid == null) {
      await signOut();
      throw FirebaseAuthException(code: 'user-not-found');
    }
    try {
      return await _fetchProfile(
        uid,
        credential.user?.email ?? account.email,
        fallbackName: credential.user?.displayName ?? account.displayName,
        photoUrl: credential.user?.photoURL ?? account.photoUrl,
      );
    } catch (_) {
      await signOut();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      if (!kIsWeb) {
        await _ensureGoogleInitialized();
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Ignore Google sign-out failures so local/Firebase sign-out completes.
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  User? get currentFirebaseUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  bool get hasPasswordProvider =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  List<String> get linkedProviders =>
      _auth.currentUser?.providerData.map((p) => p.providerId).toList() ??
      const [];

  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(code: 'user-not-found');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<JameelUserModel> updateEmployeeProfile({
    required String uid,
    required String name,
    required String department,
    String? email,
    DateTime? existingJoinDate,
  }) async {
    final trimmedName = name.trim();
    final trimmedDept = department.trim();
    final docRef = _firestore.collection('employees').doc(uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.update({
        'name': trimmedName,
        'department': trimmedDept,
      });
    } else {
      await docRef.set({
        'name': trimmedName,
        'department': trimmedDept,
        if (email != null && email.isNotEmpty) 'email': email,
      });
    }

    try {
      await _auth.currentUser?.updateDisplayName(trimmedName);
    } catch (_) {
      // Non-fatal: Firestore profile is the source of truth.
    }

    final mergedData = <String, dynamic>{
      ...?snapshot.data(),
      'name': trimmedName,
      'department': trimmedDept,
    };

    return _userFromProfileData(
      uid: uid,
      data: mergedData,
      fallbackName: trimmedName,
      fallbackEmail: email,
      fallbackJoinDate: existingJoinDate,
      photoUrl: _auth.currentUser?.photoURL,
    );
  }

  Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {
    final docRef = _firestore.collection('employees').doc(uid);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      await docRef.update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final user = _auth.currentUser;
      final fallbackName = (user?.displayName ?? '').trim();
      final name = fallbackName.isNotEmpty
          ? fallbackName
          : (user?.email?.split('@').first ?? 'Employee');
      await docRef.set({
        'name': name.length > 120 ? name.substring(0, 120) : name,
        if (user?.email != null && user!.email!.isNotEmpty)
          'email': user.email,
      });
      await docRef.update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<JameelUserModel> _fetchProfile(
    String uid,
    String email, {
    String? fallbackName,
    String? photoUrl,
  }) async {
    final docRef = _firestore.collection('employees').doc(uid);
    final snapshot = await docRef.get();
    var data = snapshot.data();

    if (data == null) {
      final cleanFallback = (fallbackName ?? '').trim();
      final initialName = cleanFallback.isNotEmpty
          ? cleanFallback
          : (email.contains('@') ? email.split('@').first : 'Employee');
      final boundedName =
          initialName.length > 120 ? initialName.substring(0, 120) : initialName;
      try {
        await docRef.set({
          'name': boundedName,
          if (email.isNotEmpty) 'email': email,
        });
        data = {
          'name': boundedName,
          if (email.isNotEmpty) 'email': email,
        };
      } catch (_) {
        // Non-fatal: still build an in-memory session user.
      }
    }

    return _userFromProfileData(
      uid: uid,
      data: data,
      fallbackName: fallbackName,
      fallbackEmail: email,
      photoUrl: photoUrl,
    );
  }

  JameelUserModel _userFromProfileData({
    required String uid,
    required Map<String, dynamic>? data,
    String? fallbackName,
    String? fallbackEmail,
    DateTime? fallbackJoinDate,
    String? photoUrl,
  }) {
    if (data == null) {
      return JameelUserModel(
        uId: uid,
        userName: fallbackName,
        userEmail: fallbackEmail,
        userJoinDate: fallbackJoinDate,
        photoUrl: photoUrl,
      );
    }

    final joinDateRaw = data['joinDate'];
    final joinDate = joinDateRaw is Timestamp
        ? joinDateRaw.toDate()
        : fallbackJoinDate;
    final site = data['assignedSite'] is Map
        ? Map<String, dynamic>.from(data['assignedSite'] as Map)
        : null;
    return JameelUserModel(
      uId: uid,
      userName: data['name'] as String? ?? fallbackName,
      userEmail: data['email'] as String? ?? fallbackEmail,
      userDepartment: data['department'] as String?,
      userJoinDate: joinDate,
      photoUrl: photoUrl,
      role: (data['role'] as String?) ?? 'employee',
      annualLeaveBalance: (data['annualLeaveBalance'] as num?)?.toInt() ?? 21,
      assignedSiteName: site?['name'] as String?,
      assignedSiteLat: (site?['lat'] as num?)?.toDouble(),
      assignedSiteLng: (site?['lng'] as num?)?.toDouble(),
      assignedSiteRadiusMeters: (site?['radiusMeters'] as num?)?.toDouble(),
    );
  }
}
