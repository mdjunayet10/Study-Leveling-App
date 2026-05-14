import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/leaderboard_entry.dart';
import '../models/multiplayer_room.dart';
import '../models/reward_item.dart';
import '../models/study_task.dart';
import '../models/user_profile.dart';
import '../firebase_options.dart';
import 'study_repository.dart';

class AppState extends ChangeNotifier {
  AppState(this.repository);

  final StudyRepository repository;

  UserProfile? _currentUser;
  String? _currentAuthUid;
  bool _busy = false;
  bool _googleSignInInitialized = false;
  static const String _mainMenuRouteName = '/main-menu';

  UserProfile? get currentUser => _currentUser;
  bool get isBusy => _busy;
  bool get isAuthenticated => _currentUser != null;
  bool get isGuestSession =>
      _currentUser?.username.trim().toLowerCase().startsWith('guest_') ?? false;
  bool get hasSignedInAccount => _currentUser != null && !isGuestSession;

  FirebaseAuth get _auth => FirebaseAuth.instance;
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  Future<AuthResult> ensureGuestSession() async {
    final user = _currentUser;
    if (user != null) {
      return AuthResult.success(user, 'Continuing as ${user.username}.');
    }

    return signInAnonymously();
  }

  Future<AuthResult> signInAnonymously() async {
    _busy = true;
    notifyListeners();

    try {
      final username = await _createGuestUsername();
      final guest = UserProfile.newUser(username, emailVerified: true);

      _currentAuthUid = null;
      _currentUser = guest;
      _currentUser!.initializeTracking();

      await repository.saveUser(_currentUser!);
      await _rememberSignedInUser(_currentUser!);

      notifyListeners();

      return AuthResult.success(
        _currentUser!,
        'Guest mode opened as ${_currentUser!.username}.',
      );
    } catch (error) {
      return AuthResult.failure(
        'Could not open guest mode. Details: ${_simpleErrorMessage(error)}',
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> signIn(String username, String password) async {
    _busy = true;
    notifyListeners();

    try {
      final normalizedUsername = username.trim();

      if (normalizedUsername.isEmpty || password.isEmpty) {
        return const AuthResult.failure('Enter your username and password.');
      }

      // Keep old/local accounts working first. Clear any stale Firebase session
      // so a previous Google/Firebase user cannot override this local profile
      // on the next app open.
      final localUser = await repository.signIn(normalizedUsername, password);
      if (localUser != null) {
        await _clearFirebaseAuthSession();
        _currentAuthUid = null;
        await repository.deleteUserRooms(localUser.username);
        _currentUser = localUser;
        _currentUser!.initializeTracking();
        await repository.saveUser(_currentUser!);
        await _rememberSignedInUser(_currentUser!);
        notifyListeners();

        return AuthResult.success(
          _currentUser!,
          'Welcome back, ${_currentUser!.username}!',
        );
      }

      RemoteUsernameRecord? remoteRecord;
      try {
        remoteRecord = await repository.loadRemoteUsernameRecord(
          normalizedUsername,
        );
      } catch (error) {
        return AuthResult.failure(
          'Could not reach Firebase login records. Details: ${_simpleErrorMessage(error)}',
        );
      }

      if (remoteRecord != null && remoteRecord.email.trim().isNotEmpty) {
        return _signInWithFirebase(remoteRecord, password);
      }

      return const AuthResult.failure('Invalid username or password.');
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseAuthMessage(error));
    } catch (error) {
      return AuthResult.failure(
        'Could not log in. Details: ${_simpleErrorMessage(error)}',
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> signInWithGoogle({
    bool forceAccountSelection = false,
  }) async {
    _busy = true;
    notifyListeners();

    try {
      UserCredential credential;

      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');

        if (forceAccountSelection) {
          provider.setCustomParameters(<String, String>{
            'prompt': 'select_account',
          });
        }

        credential = await _auth.signInWithPopup(provider);
      } else {
        await _ensureGoogleSignInInitialized();

        if (forceAccountSelection) {
          await _auth.signOut();
          try {
            await _googleSignIn.signOut();
          } catch (_) {
            // Account selection will still be attempted below.
          }
        }

        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;

        final idToken = googleAuth.idToken;
        if (idToken == null || idToken.isEmpty) {
          return const AuthResult.failure(
            'Google Sign-In did not return an ID token. Please try again.',
          );
        }

        final googleCredential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        credential = await _auth.signInWithCredential(googleCredential);
      }

      final authUser = credential.user ?? _auth.currentUser;
      if (authUser == null) {
        return const AuthResult.failure(
          'Google Sign-In opened, but Firebase did not return a user.',
        );
      }

      return _finishFirebaseLogin(
        authUser,
        preferredUsername: _preferredUsernameFromGoogleUser(authUser),
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseAuthMessage(error));
    } catch (error) {
      return AuthResult.failure(
        'Google Sign-In failed. Details: ${_simpleErrorMessage(error)}',
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) {
      return;
    }

    await _googleSignIn.initialize(
      clientId: _googleSignInClientId,
      serverClientId: _googleSignInServerClientId,
    );
    _googleSignInInitialized = true;
  }

  String? get _googleSignInClientId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return DefaultFirebaseOptions.appleGoogleSignInClientId;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return null;
    }
  }

  String? get _googleSignInServerClientId {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return DefaultFirebaseOptions.googleSignInServerClientId;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return null;
    }
  }

  Future<AuthResult> _signInWithFirebase(
    RemoteUsernameRecord remoteRecord,
    String password,
  ) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: remoteRecord.email,
      password: password,
    );

    final authUser = credential.user ?? _auth.currentUser;

    if (authUser == null) {
      return const AuthResult.failure('Could not verify this login session.');
    }

    return _finishFirebaseLogin(
      authUser,
      preferredUsername: remoteRecord.username,
    );
  }

  Future<AuthResult> _finishFirebaseLogin(
    User authUser, {
    String? preferredUsername,
  }) async {
    await authUser.reload();
    final refreshedUser = _auth.currentUser ?? authUser;

    UserProfile? remoteUser;
    try {
      remoteUser = await repository.loadRemoteUserByUid(refreshedUser.uid);
    } catch (_) {
      remoteUser = null;
    }

    final bool isGoogleUser = refreshedUser.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );

    final String email = _normalizeEmail(refreshedUser.email ?? '');
    final String username =
        remoteUser?.username ??
        await _createAvailableUsername(
          preferredUsername: preferredUsername,
          email: email,
          uid: refreshedUser.uid,
        );

    final user =
        remoteUser ??
        UserProfile.newUser(
          username,
          email: email,
          emailVerified: refreshedUser.emailVerified || isGoogleUser,
        );

    final localUser = await repository.loadUser(username);
    _applyProfileImageFallback(user, localUser?.profileImageBase64);

    user.email = email;
    user.emailVerified = refreshedUser.emailVerified || isGoogleUser;

    if (user.profileImageBase64 == null && refreshedUser.photoURL != null) {
      final photoBase64 = await _downloadPhotoAsBase64(refreshedUser.photoURL);
      if (photoBase64 != null) {
        user.profileImageBase64 = photoBase64;
      }
    }

    _currentAuthUid = refreshedUser.uid;
    await repository.deleteUserRooms(user.username);

    _currentUser = user;
    _currentUser!.initializeTracking();

    await _saveUser(_currentUser!);
    await _rememberSignedInUser(_currentUser!);

    try {
      await repository.saveRemoteUsernameRecord(
        username: user.username,
        email: email,
        uid: refreshedUser.uid,
      );
    } catch (_) {
      // Do not block login if the username/email index fails temporarily.
    }

    try {
      await repository.submitLeaderboardEntry(user);
    } catch (_) {
      // Leaderboard sync should not block login.
    }

    notifyListeners();

    return AuthResult.success(
      _currentUser!,
      'Welcome back, ${_currentUser!.username}!',
    );
  }

  Future<AuthResult> createAccountWithEmailPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    _busy = true;
    notifyListeners();

    try {
      final normalizedUsername = username.trim();
      final normalizedEmail = _normalizeEmail(email);

      if (normalizedUsername.isEmpty) {
        return const AuthResult.failure('Enter a username.');
      }

      if (!_isValidEmail(normalizedEmail)) {
        return const AuthResult.failure('Enter a valid email address.');
      }

      if (password.length < 6) {
        return const AuthResult.failure('Use at least 6 password characters.');
      }

      bool usernameTaken = false;
      bool emailTaken = false;

      try {
        usernameTaken =
            await repository.remoteUsernameExists(normalizedUsername) ||
            await repository.userExists(normalizedUsername);
      } catch (_) {
        usernameTaken = await repository.userExists(normalizedUsername);
      }

      try {
        emailTaken =
            await repository.remoteEmailExists(normalizedEmail) ||
            await repository.emailExists(normalizedEmail);
      } catch (_) {
        emailTaken = await repository.emailExists(normalizedEmail);
      }

      if (usernameTaken) {
        return const AuthResult.failure('This username is already registered.');
      }

      if (emailTaken) {
        return const AuthResult.failure('This email is already registered.');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final authUser = credential.user ?? _auth.currentUser;
      if (authUser == null) {
        return const AuthResult.failure(
          'Firebase created the account, but could not open the session.',
        );
      }

      final profile = UserProfile.newUser(
        normalizedUsername,
        email: normalizedEmail,
        emailVerified: authUser.emailVerified,
      );

      _currentAuthUid = authUser.uid;
      _currentUser = profile;
      _currentUser!.initializeTracking();

      await _saveUser(profile);
      await _rememberSignedInUser(profile);

      try {
        await repository.saveRemoteUsernameRecord(
          username: normalizedUsername,
          email: normalizedEmail,
          uid: authUser.uid,
        );
      } catch (_) {
        // Account can still open. Sync can retry later.
      }

      try {
        await repository.submitLeaderboardEntry(profile);
      } catch (_) {}

      notifyListeners();

      return AuthResult.success(
        profile,
        'Account created for ${profile.username}.',
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseAuthMessage(error));
    } catch (error) {
      return AuthResult.failure(
        'Could not create account. Details: ${_simpleErrorMessage(error)}',
      );
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> signUp(
    String username,
    String password, {
    String? email,
  }) async {
    return _createLocalFallbackAccount(
      username: username,
      password: password,
      email: email ?? '',
    );
  }

  Future<AuthResult> _createLocalFallbackAccount({
    required String username,
    required String password,
    required String email,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedUsername.isEmpty) {
      return const AuthResult.failure('Enter a username.');
    }

    if (password.isEmpty) {
      return const AuthResult.failure('Enter a password.');
    }

    final profile = await repository.signUp(
      normalizedUsername,
      password,
      email: normalizedEmail.isEmpty
          ? '$normalizedUsername@study.local'
          : normalizedEmail,
    );

    if (profile == null) {
      return const AuthResult.failure('This username is already registered.');
    }

    _currentAuthUid = null;
    _currentUser = profile;
    _currentUser!.initializeTracking();
    await _rememberSignedInUser(_currentUser!);
    notifyListeners();

    return AuthResult.success(
      _currentUser!,
      'Account created for ${_currentUser!.username}.',
    );
  }

  Future<EmailActionResult> createAccountAndSendVerificationEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    final result = await createAccountWithEmailPassword(
      username: username,
      email: email,
      password: password,
    );

    if (result.success) {
      return const EmailActionResult.success(
        'Account created. No email verification is required.',
      );
    }

    return EmailActionResult.failure(result.message);
  }

  Future<AuthResult> completeEmailVerifiedSignUp({
    required String username,
    required String email,
    required String password,
  }) {
    return createAccountWithEmailPassword(
      username: username,
      email: email,
      password: password,
    );
  }

  Future<AuthResult> sendPasswordResetEmailForUsername({
    required String username,
    required String email,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = _normalizeEmail(email);

    if (normalizedUsername.isEmpty) {
      return const AuthResult.failure('Enter your username.');
    }

    if (!_isValidEmail(normalizedEmail)) {
      return const AuthResult.failure('Enter a valid email address.');
    }

    try {
      final record = await repository.loadRemoteUsernameRecord(
        normalizedUsername,
      );

      if (record == null) {
        return const AuthResult.failure(
          'This account does not have Firebase password reset enabled yet. Try Google Sign-In or create a new account.',
        );
      }

      if (_normalizeEmail(record.email) != normalizedEmail) {
        return const AuthResult.failure(
          'The email does not match this username.',
        );
      }

      await _auth.sendPasswordResetEmail(email: normalizedEmail);

      return AuthResult.message(
        'Password reset email sent to ${_maskEmail(normalizedEmail)}.',
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(_firebaseAuthMessage(error));
    } catch (error) {
      return AuthResult.failure(
        'Could not send the password reset email. Details: ${_simpleErrorMessage(error)}',
      );
    }
  }

  Future<AuthResult> resetPassword(String username, String password) async {
    return const AuthResult.failure(
      'Use the Forgot Password email link to reset your password.',
    );
  }

  Future<void> signOut() async {
    await _clearFirebaseAuthSession();

    await repository.clearActiveSession();
    _currentUser = null;
    _currentAuthUid = null;
    notifyListeners();
  }

  Future<void> _clearFirebaseAuthSession() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Tests and local-only flows can construct AppState before Firebase init.
    }

    if (!kIsWeb && _googleSignInInitialized) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Local sign-out is still valid if Google cleanup fails.
      }
    }
  }

  Future<void> restorePersistedSession() async {
    if (_currentUser != null) {
      return;
    }

    // Prefer the app's remembered profile first. This prevents an old Firebase
    // browser session from replacing a local profile that has a saved photo.
    final username = repository.loadActiveUsername();
    if (username != null) {
      final localUser = await repository.loadUser(username);
      if (localUser != null) {
        _currentUser = localUser;
        _currentUser!.initializeTracking();

        final authUser = _auth.currentUser;
        if (authUser != null &&
            _firebaseUserMatchesProfile(authUser, localUser)) {
          _currentAuthUid = authUser.uid;
          try {
            final remoteUser = await repository.loadRemoteUserByUid(
              authUser.uid,
            );
            if (remoteUser != null &&
                remoteUser.profileImageBase64 != null &&
                remoteUser.profileImageBase64!.trim().isNotEmpty &&
                localUser.profileImageBase64 == null) {
              _currentUser!.profileImageBase64 = remoteUser.profileImageBase64;
              await repository.saveUser(_currentUser!);
              _submitLeaderboardEntryInBackground(_currentUser!);
            }
          } catch (_) {
            // The local profile is still usable.
          }
        } else {
          _currentAuthUid = null;
        }

        notifyListeners();
        return;
      }

      await repository.clearActiveSession();
    }

    final authUser = _auth.currentUser;
    if (authUser != null) {
      try {
        final remoteUser = await repository.loadRemoteUserByUid(authUser.uid);
        if (remoteUser != null) {
          final localUser = await repository.loadUser(remoteUser.username);
          _applyProfileImageFallback(remoteUser, localUser?.profileImageBase64);

          _currentAuthUid = authUser.uid;
          _currentUser = remoteUser;
          _currentUser!.initializeTracking();
          await _saveUser(remoteUser);
          _submitLeaderboardEntryInBackground(remoteUser);
          await repository.saveActiveUsername(remoteUser.username);
          notifyListeners();
          return;
        }
      } catch (_) {
        // No persisted profile could be restored.
      }
    }
  }

  Future<void> refreshCurrentUser() async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    final authUid = _currentAuthUid;

    UserProfile? latest;
    if (authUid == null) {
      latest = await repository.loadUser(user.username);
    } else {
      try {
        latest = await repository.loadRemoteUserByUid(authUid);
      } catch (_) {
        latest = await repository.loadUser(user.username);
      }
    }

    if (latest != null) {
      final restoredProfileImage = _applyProfileImageFallback(
        latest,
        user.profileImageBase64,
      );
      _currentUser = latest;
      if (restoredProfileImage) {
        await _saveUser(latest);
        _submitLeaderboardEntryInBackground(latest);
      }
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _saveUser(profile);
    _submitLeaderboardEntryInBackground(profile);

    if (_currentUser?.username == profile.username) {
      _currentUser = profile.copy();
      notifyListeners();
    }
  }

  Future<void> replaceCurrentUser(UserProfile profile) async {
    _currentUser = profile.copy();
    await _saveUser(_currentUser!);
    notifyListeners();
  }

  Future<bool> updateCurrentUserProfilePicture(
    String? profileImageBase64,
  ) async {
    final user = _currentUser;
    if (user == null || isGuestSession) {
      return false;
    }

    user.profileImageBase64 = profileImageBase64;
    await _saveUser(user);

    try {
      await repository.submitLeaderboardEntry(user);
    } catch (_) {
      // Local/profile save is still valid if the leaderboard is temporarily down.
    }

    _currentUser = user.copy();
    notifyListeners();

    return true;
  }

  Future<void> _saveUser(UserProfile user) async {
    await repository.saveUser(user);

    final authUid = _syncableAuthUidFor(user);
    if (authUid != null && _currentUser?.username == user.username) {
      try {
        await repository.saveRemoteUserByUid(authUid, user);
      } catch (_) {
        // Remote sync can retry on next save.
      }
    }
  }

  String? _syncableAuthUidFor(UserProfile user) {
    if (_currentAuthUid != null) {
      return _currentAuthUid;
    }

    final User? authUser;
    try {
      authUser = _auth.currentUser;
    } catch (_) {
      return null;
    }

    if (authUser == null || !_firebaseUserMatchesProfile(authUser, user)) {
      return null;
    }

    return authUser.uid;
  }

  bool _firebaseUserMatchesProfile(User authUser, UserProfile profile) {
    final profileEmail = profile.email.trim().toLowerCase();
    final authEmail = authUser.email?.trim().toLowerCase() ?? '';

    if (profileEmail.isNotEmpty && authEmail.isNotEmpty) {
      return profileEmail == authEmail;
    }

    return _currentAuthUid == authUser.uid;
  }

  bool _applyProfileImageFallback(UserProfile user, String? fallbackImage) {
    if (user.profileImageBase64 != null &&
        user.profileImageBase64!.trim().isNotEmpty) {
      return false;
    }

    if (fallbackImage == null || fallbackImage.trim().isEmpty) {
      return false;
    }

    user.profileImageBase64 = fallbackImage;
    return true;
  }

  Future<void> _rememberSignedInUser(UserProfile user) async {
    await repository.saveActiveUsername(user.username);
    await repository.saveLastLocation(routeName: _mainMenuRouteName);
  }

  Future<void> rememberNavigation(
    String routeName, {
    Map<String, dynamic> arguments = const <String, dynamic>{},
  }) {
    return repository.saveLastLocation(
      routeName: routeName,
      arguments: arguments,
    );
  }

  Future<void> clearRememberedNavigation() {
    return repository.clearLastLocation();
  }

  void _submitLeaderboardEntryInBackground(UserProfile user) {
    if (isGuestSession) {
      return;
    }

    repository.submitLeaderboardEntry(user).catchError((_) {});
  }

  Future<List<String>> loadUsernames() {
    return repository.loadUsernames();
  }

  Future<String> _createGuestUsername() async {
    final random = Random();

    for (int attempt = 0; attempt < 20; attempt++) {
      final suffix = (1000 + random.nextInt(9000)).toString();
      final candidate = attempt == 0
          ? 'guest_$suffix'
          : 'guest_${suffix}_${attempt + 1}';

      if (await repository.loadUser(candidate) == null) {
        return candidate;
      }
    }

    return 'guest_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> _createAvailableUsername({
    required String? preferredUsername,
    required String email,
    required String uid,
  }) async {
    final seed = _sanitizeUsername(
      preferredUsername?.trim().isNotEmpty == true
          ? preferredUsername!
          : email.split('@').first,
    );

    final base = seed.isEmpty ? 'student' : seed;

    for (int attempt = 0; attempt < 20; attempt++) {
      final candidate = attempt == 0 ? base : '${base}_${attempt + 1}';

      bool exists = false;
      try {
        exists =
            await repository.remoteUsernameExists(candidate) ||
            await repository.userExists(candidate);
      } catch (_) {
        exists = await repository.userExists(candidate);
      }

      if (!exists) {
        return candidate;
      }
    }

    final suffix = uid.length >= 6 ? uid.substring(0, 6).toLowerCase() : uid;
    return '${base}_$suffix';
  }

  String _preferredUsernameFromGoogleUser(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'student';
  }

  String _sanitizeUsername(String value) {
    final normalized = value.trim().toLowerCase();

    final safe = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return safe.isEmpty ? 'student' : safe;
  }

  Future<String?> _downloadPhotoAsBase64(String? photoUrl) async {
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse(photoUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      if (response.bodyBytes.isEmpty || response.bodyBytes.length > 1000000) {
        return null;
      }

      return base64Encode(response.bodyBytes);
    } catch (_) {
      return null;
    }
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  String _maskEmail(String email) {
    final parts = email.split('@');

    if (parts.length != 2 || parts.first.isEmpty) {
      return email;
    }

    final name = parts.first;
    final visibleName = name.length <= 2
        ? name[0]
        : '${name[0]}${name[name.length - 1]}';

    return '$visibleName***@${parts.last}';
  }

  String _simpleErrorMessage(Object error) {
    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Unknown error.';
    }

    final lower = message.toLowerCase();

    if (lower.contains('permission')) {
      return 'Firebase Database permission denied. Deploy database.rules.json.';
    }

    if (lower.contains('network')) {
      return 'Network request failed.';
    }

    if (lower.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled in Firebase Authentication.';
    }

    if (lower.contains('configuration-not-found')) {
      return 'Firebase Authentication is not fully configured for this project.';
    }

    if (lower.contains('unauthorized-domain')) {
      return 'This web domain is not authorized in Firebase Authentication.';
    }

    if (lower.contains('popup-closed-by-user')) {
      return 'Google Sign-In was closed before finishing.';
    }

    return message.length > 180 ? '${message.substring(0, 180)}...' : message;
  }

  String _firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'This email already uses another sign-in method. Try the original method or password reset.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in instead.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a stronger password.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Enable it in Firebase Console → Authentication → Sign-in method.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not fully configured. Enable Authentication in Firebase Console.';
      case 'unauthorized-domain':
        return 'This domain is not authorized. Add study-leveling.web.app and localhost in Firebase Authentication authorized domains.';
      case 'user-disabled':
        return 'This Firebase account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid username/email or password.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'popup-closed-by-user':
        return 'Google Sign-In was closed before finishing.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Firebase Authentication failed.';
    }
  }

  Future<void> addTask(StudyTask task) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    user.tasks.add(task);
    await _saveUser(user);
    notifyListeners();
  }

  Future<void> removeTaskAt(int index) async {
    final user = _currentUser;
    if (user == null || index < 0 || index >= user.tasks.length) {
      return;
    }

    user.tasks.removeAt(index);
    await _saveUser(user);
    notifyListeners();
  }

  Future<void> updateTaskAt(int index, StudyTask task) async {
    final user = _currentUser;
    if (user == null || index < 0 || index >= user.tasks.length) {
      return;
    }

    user.tasks[index] = task;
    await _saveUser(user);
    notifyListeners();
  }

  Future<void> startTaskAt(int index) async {
    final user = _currentUser;
    if (user == null || index < 0 || index >= user.tasks.length) {
      return;
    }

    final task = user.tasks[index];
    if (task.completed || task.startedAt != null) {
      return;
    }

    task.startedAt = DateTime.now();
    await _saveUser(user);
    notifyListeners();
  }

  Future<void> completeTaskAt(int index) async {
    final user = _currentUser;
    if (user == null || index < 0 || index >= user.tasks.length) {
      return;
    }

    final task = user.tasks[index];
    if (task.completed) {
      return;
    }

    final completedAt = DateTime.now();
    task.completed = true;
    task.completionDate = completedAt;
    user.addXp(task.xpReward);
    user.addCoins(task.coinReward);
    user.incrementCompletedTasksCounter();
    user.registerStudyCompletion(completedAt);

    await _saveUser(user);
    notifyListeners();
  }

  Future<bool> redeemReward(RewardItem reward) async {
    final user = _currentUser;
    if (user == null) {
      return false;
    }

    if (!user.spendCoins(reward.cost)) {
      return false;
    }

    user.recordRewardRedemption(reward, DateTime.now());
    await _saveUser(user);
    notifyListeners();

    return true;
  }

  Future<void> updateStudyGoals({
    required int dailyTasks,
    required int weeklyXp,
    required int targetLevel,
  }) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    user.updateGoals(
      dailyTasks: dailyTasks,
      weeklyXp: weeklyXp,
      targetLevelValue: targetLevel,
    );
    await _saveUser(user);
    notifyListeners();
  }

  Future<void> addCustomReward(RewardItem reward) async {
    final user = _currentUser;
    if (user == null) {
      return;
    }

    user.customRewards.add(reward);
    await _saveUser(user);
    notifyListeners();
  }

  Future<void> updateCustomRewardAt(int index, RewardItem reward) async {
    final user = _currentUser;
    if (user == null || index < 0 || index >= user.customRewards.length) {
      return;
    }

    user.customRewards[index] = reward;
    await _saveUser(user);
    notifyListeners();
  }

  Future<void> removeCustomRewardAt(int index) async {
    final user = _currentUser;
    if (user == null || index < 0 || index >= user.customRewards.length) {
      return;
    }

    user.customRewards.removeAt(index);
    await _saveUser(user);
    notifyListeners();
  }

  Future<List<UserProfile>> loadAllUsers() {
    return repository.loadAllUsers();
  }

  Future<List<LeaderboardEntry>> loadLeaderboardEntries() {
    final user = _currentUser;

    if (user != null && !isGuestSession) {
      return repository
          .submitLeaderboardEntry(user)
          .then((_) => repository.loadLeaderboardEntries());
    }

    return repository.loadLeaderboardEntries();
  }

  Future<List<LeaderboardEntry>> loadLocalLeaderboardEntries() {
    return repository.loadLocalLeaderboardEntries();
  }

  bool get isRemoteLeaderboardEnabled =>
      repository.leaderboardService.isRemoteEnabled;

  Future<MultiplayerRoom?> createRoom({
    required int maxPlayers,
    required bool competitiveTimer,
    required int timerMinutes,
  }) async {
    final user = _currentUser;

    if (user == null) {
      return null;
    }

    return repository.createUniqueRoom(
      maxPlayers: maxPlayers,
      creator: user,
      competitiveTimer: competitiveTimer,
      timerMinutes: timerMinutes,
    );
  }

  Future<MultiplayerRoom?> createRoomForPlayer({
    required UserProfile player,
    required int maxPlayers,
    required bool competitiveTimer,
    required int timerMinutes,
  }) async {
    return repository.createUniqueRoom(
      maxPlayers: maxPlayers,
      creator: player,
      competitiveTimer: competitiveTimer,
      timerMinutes: timerMinutes,
    );
  }

  Future<MultiplayerRoom?> joinRoom({
    required String roomId,
    bool forceJoin = false,
  }) async {
    final user = _currentUser;

    if (user == null) {
      return null;
    }

    return repository.joinRoom(
      roomId: roomId,
      user: user,
      forceJoin: forceJoin,
    );
  }

  Future<MultiplayerRoom?> joinRoomAs({
    required String roomId,
    required UserProfile player,
    bool forceJoin = false,
  }) {
    return repository.joinRoom(
      roomId: roomId,
      user: player,
      forceJoin: forceJoin,
    );
  }

  Stream<MultiplayerRoom?> watchRoom(String roomId) {
    return repository.watchRoom(roomId);
  }

  Future<void> updateRoomParticipant({
    required String roomId,
    required UserProfile participant,
  }) async {
    await repository.updateRoomParticipant(
      roomId: roomId,
      participant: participant,
    );
  }

  Future<void> applyMultiplayerTaskReward({
    required String username,
    required StudyTask task,
    required DateTime completedAt,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      return;
    }

    final isCurrentUser = _currentUser?.username == normalizedUsername;
    final UserProfile? savedUser = isCurrentUser
        ? _currentUser?.copy()
        : await repository.loadUser(normalizedUsername);

    if (savedUser == null) {
      return;
    }

    savedUser.addXp(task.xpReward);
    savedUser.addCoins(task.coinReward);
    savedUser.incrementCompletedTasksCounter();
    savedUser.registerStudyCompletion(completedAt);

    await _saveUser(savedUser);
    _submitLeaderboardEntryInBackground(savedUser);

    if (isCurrentUser) {
      _currentUser = savedUser.copy();
      notifyListeners();
    }
  }

  Future<void> leaveRoom(String roomId) async {
    final user = _currentUser;

    if (user == null) {
      return;
    }

    await repository.leaveRoom(roomId, user.username);
  }

  Future<void> leaveRoomAs(String roomId, String username) async {
    await repository.leaveRoom(roomId, username);
  }
}

class AuthResult {
  const AuthResult._(this.success, this.message, this.user);

  const AuthResult.success(UserProfile user, String message)
    : this._(true, message, user);

  const AuthResult.message(String message) : this._(true, message, null);

  const AuthResult.failure(String message) : this._(false, message, null);

  final bool success;
  final String message;
  final UserProfile? user;
}

class EmailActionResult {
  const EmailActionResult._(this.success, this.message);

  const EmailActionResult.success(String message) : this._(true, message);

  const EmailActionResult.failure(String message) : this._(false, message);

  final bool success;
  final String message;
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree.');
    return scope!.notifier!;
  }
}
