import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    try {
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        // Instant login: check if we have a cached JWT token
        final cachedToken = await _authRepository.getCachedToken();
        if (cachedToken != null) {
          emit(Authenticated(user: currentUser, apiToken: cachedToken));
          // Refresh in the background so it updates if needed, without blocking UI transition
          _authRepository.authenticateWithBackend(currentUser).catchError((_) => '');
        } else {
          // No cached token, must fetch online
          final apiToken = await _authRepository.authenticateWithBackend(currentUser);
          emit(Authenticated(user: currentUser, apiToken: apiToken));
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (_) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userCredential = await _authRepository.signInWithGoogle();
      final user = userCredential.user;
      if (user != null) {
        final apiToken = await _authRepository.authenticateWithBackend(user);
        emit(Authenticated(user: user, apiToken: apiToken));
      } else {
        emit(const AuthFailure('User data could not be retrieved from Firebase.'));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'ERROR_ABORTED_BY_USER') {
        emit(Unauthenticated());
      } else {
        emit(AuthFailure(e.message ?? 'Authentication failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthFailure('Backend authentication failed: ${e.toString()}'));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure('Sign out failed: ${e.toString()}'));
    }
  }
}
