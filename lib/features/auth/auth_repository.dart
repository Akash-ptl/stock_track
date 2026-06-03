import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_constants.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FlutterSecureStorage _secureStorage;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FlutterSecureStorage? secureStorage,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Stream of user auth changes
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithGoogle() async {
    // Force email selection prompt by signing out first
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    // Trigger the Google Authentication flow
    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate();
    } catch (e) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user: $e',
      );
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a new credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Authenticate with backend: login or register if not exists
  Future<String> authenticateWithBackend(User firebaseUser) async {
    final email = firebaseUser.email;
    final password = firebaseUser.uid;
    final name = firebaseUser.displayName ?? '';

    if (email == null) {
      throw Exception('Firebase user email is null. Cannot authenticate with backend.');
    }

    final loginUrl = Uri.parse(ApiConstants.login);
    final registerUrl = Uri.parse(ApiConstants.register);

    // 1. Try to login
    try {
      final loginResponse = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (loginResponse.statusCode == 200) {
        final data = json.decode(loginResponse.body);
        final token = data['access_token'] as String;
        await _saveTokenToPrefs(token);
        return token;
      } else if (loginResponse.statusCode == 404 || loginResponse.statusCode == 401) {
        // User not registered or invalid credentials, let's register
        final registerResponse = await http.post(
          registerUrl,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': email,
            'password': password,
            'name': name,
          }),
        ).timeout(const Duration(seconds: 10));

        if (registerResponse.statusCode == 201 || registerResponse.statusCode == 200) {
          // Login again after registration
          final retryLoginResponse = await http.post(
            loginUrl,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          ).timeout(const Duration(seconds: 10));

          if (retryLoginResponse.statusCode == 200) {
            final data = json.decode(retryLoginResponse.body);
            final token = data['access_token'] as String;
            await _saveTokenToPrefs(token);
            return token;
          } else {
            throw Exception('Backend login failed after registration: ${retryLoginResponse.body}');
          }
        } else {
          throw Exception('Backend registration failed: ${registerResponse.body}');
        }
      } else {
        throw Exception('Backend login failed with status code ${loginResponse.statusCode}: ${loginResponse.body}');
      }
    } catch (e) {
      // Offline fallback: check if we already have a cached token
      final cachedToken = await getCachedToken();
      if (cachedToken != null) {
        return cachedToken;
      }
      rethrow;
    }
  }

  Future<void> _saveTokenToPrefs(String token) async {
    await _secureStorage.write(key: 'auth_token_key', value: token);
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
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
