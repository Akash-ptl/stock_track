import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../app_user.dart';
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
      final currentUser = await _authRepository.getCurrentUser();
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
      final user = await _authRepository.signInWithGoogle();
      final apiToken = await _authRepository.authenticateWithBackend(user);
      emit(Authenticated(user: user, apiToken: apiToken));
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Sign in aborted by user')) {
        emit(Unauthenticated());
      } else {
        emit(AuthFailure('Authentication failed: $errorStr'));
      }
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
