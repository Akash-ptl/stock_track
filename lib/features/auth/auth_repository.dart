import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'app_user.dart';

class AuthRepository {
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;
  AppUser? _currentUser;

  AuthRepository({
    GoogleSignIn? googleSignIn,
    FlutterSecureStorage? secureStorage,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Get current cached user
  AppUser? get currentUser => _currentUser;

  /// Retrieve the user profile from cache
  Future<AppUser?> getCurrentUser() async {
    debugPrint('[AuthRepository] getCurrentUser: checking cache...');
    if (_currentUser != null) {
      debugPrint('[AuthRepository] getCurrentUser: returning in-memory user: ${_currentUser!.email}');
      return _currentUser;
    }
    final email = await _secureStorage.read(key: 'user_email');
    final uid = await _secureStorage.read(key: 'user_uid');
    final displayName = await _secureStorage.read(key: 'user_display_name');
    if (email != null && uid != null) {
      debugPrint('[AuthRepository] getCurrentUser: cache hit! user: $email, uid: $uid');
      _currentUser = AppUser(email: email, uid: uid, displayName: displayName);
      return _currentUser;
    }
    debugPrint('[AuthRepository] getCurrentUser: cache miss');
    return null;
  }

  Future<AppUser> signInWithGoogle() async {
    debugPrint('[AuthRepository] signInWithGoogle: starting native Google Sign-in flow...');
    // Force email selection prompt by signing out first
    try {
      await _googleSignIn.signOut();
      debugPrint('[AuthRepository] signInWithGoogle: Google Sign-in cleared previous session');
    } catch (e) {
      debugPrint('[AuthRepository] signInWithGoogle: Sign out previous Google session warning: $e');
    }

    // Trigger the Google Authentication flow
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
      debugPrint('[AuthRepository] signInWithGoogle: native Google Sign-in completed. User: ${googleUser.email}');
    } catch (e) {
      debugPrint('[AuthRepository] signInWithGoogle: native Google Sign-in failed: $e');
      throw Exception('Sign in aborted by user: $e');
    }

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      debugPrint('[AuthRepository] signInWithGoogle: ID Token is null from Google Auth');
      throw Exception('Google Sign-in failed: ID Token is null');
    }
    debugPrint('[AuthRepository] signInWithGoogle: Google ID Token retrieved successfully (Length: ${idToken.length})');

    // Call Better Auth social sign-in via the client
    debugPrint('[AuthRepository] signInWithGoogle: Sending ID Token to Better Auth endpoint...');
    final res = await FlutterBetterAuth.client.signIn.social(
      provider: 'google',
      idToken: SocialIdTokenBody(token: idToken),
    );

    final data = res.data;
    if (data == null) {
      debugPrint('[AuthRepository] signInWithGoogle: Better Auth social sign-in failed: ${res.error?.message}');
      throw Exception(res.error?.message ?? 'Social login failed via Better Auth');
    }
    debugPrint('[AuthRepository] signInWithGoogle: Better Auth social sign-in succeeded. Token: ${data.token.substring(0, 10)}...');

    // Retrieve session details using getSession
    debugPrint('[AuthRepository] signInWithGoogle: Fetching session/user profile from Better Auth...');
    final sessionRes = await FlutterBetterAuth.client.getSession();
    final sessionData = sessionRes.data;
    if (sessionData == null) {
      debugPrint('[AuthRepository] signInWithGoogle: Fetching Better Auth session failed: ${sessionRes.error?.message}');
      throw Exception(sessionRes.error?.message ?? 'Failed to retrieve session details');
    }

    final user = sessionData.user;
    final sessionToken = sessionData.session.token;
    debugPrint('[AuthRepository] signInWithGoogle: Session profile loaded. User ID: ${user.id}, Name: ${user.name}');

    final AppUser appUser = AppUser(
      email: user.email,
      uid: user.id,
      displayName: user.name,
    );

    _currentUser = appUser;

    // Cache user profile details in secure storage
    debugPrint('[AuthRepository] signInWithGoogle: Caching user details in SecureStorage...');
    await _secureStorage.write(key: 'user_email', value: user.email);
    await _secureStorage.write(key: 'user_uid', value: user.id);
    await _secureStorage.write(key: 'user_display_name', value: user.name);
    await _secureStorage.write(key: 'auth_token_key', value: sessionToken);
    debugPrint('[AuthRepository] signInWithGoogle: Authentication flow complete. Session Token cached.');

    return appUser;
  }

  /// Authenticate with backend: return the cached Better Auth session token
  Future<String> authenticateWithBackend(AppUser user) async {
    debugPrint('[AuthRepository] authenticateWithBackend: checking for cached session token...');
    final cachedToken = await getCachedToken();
    if (cachedToken != null) {
      debugPrint('[AuthRepository] authenticateWithBackend: found active session token.');
      return cachedToken;
    }
    
    debugPrint('[AuthRepository] authenticateWithBackend: no active session token found. Attempting to restore session from Better Auth...');
    try {
      final sessionRes = await FlutterBetterAuth.client.getSession();
      final sessionData = sessionRes.data;
      if (sessionData != null) {
        final sessionToken = sessionData.session.token;
        debugPrint('[AuthRepository] authenticateWithBackend: Session restored successfully. Token cached.');
        await _secureStorage.write(key: 'auth_token_key', value: sessionToken);
        return sessionToken;
      }
    } catch (e) {
      debugPrint('[AuthRepository] authenticateWithBackend: Session restore failed: $e');
    }
    
    debugPrint('[AuthRepository] authenticateWithBackend: no active session token found!');
    throw Exception('No active session token found');
  }

  Future<String?> getCachedToken() async {
    return await _secureStorage.read(key: 'auth_token_key');
  }

  Future<void> clearAllCache() async {
    debugPrint('[AuthRepository] clearAllCache: cleaning up local caches...');
    
    // Clear shared preferences for non-credential caches
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key == 'cached_businesses_key' ||
          key.startsWith('cached_locations_') ||
          key.startsWith('stock_items_key_')) {
        await prefs.remove(key);
      }
    }
    debugPrint('[AuthRepository] clearAllCache: completed.');
  }

  /// Sign out
  Future<void> signOut() async {
    debugPrint('[AuthRepository] signOut: logging out user...');
    await clearAllCache();
    await _secureStorage.deleteAll();
    _currentUser = null;
    try {
      debugPrint('[AuthRepository] signOut: sending Better Auth client signOut request...');
      await FlutterBetterAuth.client.signOut();
    } catch (e) {
      debugPrint('[AuthRepository] signOut: Better Auth signOut failed/ignored: $e');
    }
    try {
      debugPrint('[AuthRepository] signOut: signing out of native Google session...');
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[AuthRepository] signOut: Google signOut warning: $e');
    }
    debugPrint('[AuthRepository] signOut: logged out successfully.');
  }
}
