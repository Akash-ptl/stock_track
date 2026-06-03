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
    if (_currentUser != null) return _currentUser;
    final email = await _secureStorage.read(key: 'user_email');
    final uid = await _secureStorage.read(key: 'user_uid');
    final displayName = await _secureStorage.read(key: 'user_display_name');
    if (email != null && uid != null) {
      _currentUser = AppUser(email: email, uid: uid, displayName: displayName);
      return _currentUser;
    }
    return null;
  }

  Future<AppUser> signInWithGoogle() async {
    // Force email selection prompt by signing out first
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    // Trigger the Google Authentication flow
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } catch (e) {
      throw Exception('Sign in aborted by user: $e');
    }

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception('Google Sign-in failed: ID Token is null');
    }

    // Call Better Auth social sign-in via the client
    final res = await FlutterBetterAuth.client.signIn.social(
      provider: 'google',
      idToken: SocialIdTokenBody(token: idToken),
    );

    final data = res.data;
    if (data == null) {
      throw Exception(res.error?.message ?? 'Social login failed via Better Auth');
    }

    // Retrieve session details using getSession
    final sessionRes = await FlutterBetterAuth.client.getSession();
    final sessionData = sessionRes.data;
    if (sessionData == null) {
      throw Exception(sessionRes.error?.message ?? 'Failed to retrieve session details');
    }

    final user = sessionData.user;
    final sessionToken = sessionData.session.token;

    final AppUser appUser = AppUser(
      email: user.email,
      uid: user.id,
      displayName: user.name,
    );

    _currentUser = appUser;

    // Cache user profile details in secure storage
    await _secureStorage.write(key: 'user_email', value: user.email);
    await _secureStorage.write(key: 'user_uid', value: user.id);
    await _secureStorage.write(key: 'user_display_name', value: user.name);
    await _secureStorage.write(key: 'auth_token_key', value: sessionToken);

    return appUser;
  }

  /// Authenticate with backend: return the cached Better Auth session token
  Future<String> authenticateWithBackend(AppUser user) async {
    final cachedToken = await getCachedToken();
    if (cachedToken != null) {
      return cachedToken;
    }
    throw Exception('No active session token found');
  }


  Future<String?> getCachedToken() async {
    return await _secureStorage.read(key: 'auth_token_key');
  }

  Future<void> clearAllCache() async {
    await _secureStorage.delete(key: 'auth_token_key');
    
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
  }

  /// Sign out
  Future<void> signOut() async {
    await clearAllCache();
    await _secureStorage.delete(key: 'user_email');
    await _secureStorage.delete(key: 'user_uid');
    await _secureStorage.delete(key: 'user_display_name');
    _currentUser = null;
    try {
      await FlutterBetterAuth.client.signOut();
    } catch (_) {}
    await _googleSignIn.signOut();
  }
}
