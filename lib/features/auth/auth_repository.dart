import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Stream of user auth changes
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  /// Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    // Force email selection prompt by signing out first
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    // Trigger the Google Authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
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

    final loginUrl = Uri.parse('https://stocktrack-mach.onrender.com/api/auth/login');
    final registerUrl = Uri.parse('https://stocktrack-mach.onrender.com/api/auth/register');

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token_key', token);
  }

  Future<String?> getCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token_key');
  }

  Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key == 'auth_token_key' ||
          key == 'cached_businesses_key' ||
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
