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
    print('[AuthBloc] AppStarted: Checking authentication state on launch...');
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        print('[AuthBloc] AppStarted: User found in cache: ${currentUser.email}');
        // Instant login: check if we have a cached JWT token
        final cachedToken = await _authRepository.getCachedToken();
        if (cachedToken != null) {
          print('[AuthBloc] AppStarted: Active session token found. Emitting Authenticated state.');
          emit(Authenticated(user: currentUser, apiToken: cachedToken));
          // Refresh in the background so it updates if needed, without blocking UI transition
          _authRepository.authenticateWithBackend(currentUser).catchError((e) {
            print('[AuthBloc] AppStarted: Background session refresh warning: $e');
            return '';
          });
        } else {
          print('[AuthBloc] AppStarted: User cached but token missing. Fetching new token...');
          final apiToken = await _authRepository.authenticateWithBackend(currentUser);
          emit(Authenticated(user: currentUser, apiToken: apiToken));
        }
      } else {
        print('[AuthBloc] AppStarted: No user cached. Emitting Unauthenticated.');
        emit(Unauthenticated());
      }
    } catch (e) {
      print('[AuthBloc] AppStarted: Error while initializing app: $e. Emitting Unauthenticated.');
      emit(Unauthenticated());
    }
  }

  Future<void> _onGoogleSignInRequested(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('[AuthBloc] GoogleSignInRequested: Google Login requested by user. Emitting AuthLoading...');
    emit(AuthLoading());
    try {
      final user = await _authRepository.signInWithGoogle();
      print('[AuthBloc] GoogleSignInRequested: Better Auth social sign-in succeeded. Email: ${user.email}');
      final apiToken = await _authRepository.authenticateWithBackend(user);
      print('[AuthBloc] GoogleSignInRequested: Emitting Authenticated state.');
      emit(Authenticated(user: user, apiToken: apiToken));
    } catch (e) {
      final errorStr = e.toString();
      print('[AuthBloc] GoogleSignInRequested: Error encountered: $errorStr');
      if (errorStr.contains('Sign in aborted by user')) {
        print('[AuthBloc] GoogleSignInRequested: User aborted sign in. Emitting Unauthenticated.');
        emit(Unauthenticated());
      } else {
        print('[AuthBloc] GoogleSignInRequested: Login failed. Emitting AuthFailure.');
        emit(AuthFailure('Authentication failed: $errorStr'));
      }
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('[AuthBloc] SignOutRequested: User requested sign out. Emitting AuthLoading...');
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      print('[AuthBloc] SignOutRequested: Sign out complete. Emitting Unauthenticated.');
      emit(Unauthenticated());
    } catch (e) {
      print('[AuthBloc] SignOutRequested: Sign out failed: $e. Emitting AuthFailure.');
      emit(AuthFailure('Sign out failed: ${e.toString()}'));
    }
  }
}
