import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/supabase_service.dart';
import '../domain/klear_user.dart';
import '../data/users_repository.dart';

/// Auth state — tracks the current Supabase user and their profile.
class AuthState {
  const AuthState({
    this.user,
    this.profile,
    this.pendingEmail,
    this.isLoading = false,
    this.error,
  });

  /// The Supabase auth user (null if signed out).
  final User? user;

  /// The Klear profile (loaded from `profiles` table after sign-in).
  final KlearUser? profile;

  /// Email entered for an OTP that has not been verified yet
  /// (used by the OTP screen until the user is actually signed in).
  final String? pendingEmail;

  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;
  bool get hasProfile => profile != null && !profile!.isGuest;

  AuthState copyWith({
    User? user,
    KlearUser? profile,
    String? pendingEmail,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearProfile = false,
    bool clearPendingEmail = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      profile: clearProfile ? null : (profile ?? this.profile),
      pendingEmail:
          clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for the auth state.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState()) {
    _init();
  }

  final Ref _ref;

  void _init() {
    // No backend configured (tests / offline mode): stay signed out so the
    // router redirects everyone to the welcome screen.
    if (!SupabaseClientManager.isReady) return;

    // Watch auth state changes.
    SupabaseClientManager.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      if (event == AuthChangeEvent.signedIn && session?.user != null) {
        // Don't override profile if already loaded.
        state = state.copyWith(user: session!.user);
        _loadProfile(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        state = state.copyWith(clearUser: true, clearProfile: true);
      }
    });

    // Check current session.
    final currentUser = SupabaseClientManager.instance.client.auth.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser, isLoading: true);
      _loadProfile(currentUser.id);
    }
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final repo = _ref.read(usersRepositoryProvider);
      final profile = await repo.getProfile(userId);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Send a one-time code (OTP) to the given email address.
  ///
  /// [shouldCreateUser]: `true` (signup) creates the account when the email is
  /// unknown; `false` (login) fails with a clear "no account" error instead of
  /// silently creating one.
  Future<void> signInWithEmail(String email,
      {bool shouldCreateUser = true}) async {
    state = state.copyWith(isLoading: true, error: null, pendingEmail: email);
    try {
      await SupabaseClientManager.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: AppConfig.emailRedirectUrl,
        shouldCreateUser: shouldCreateUser,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Verify the email OTP token.
  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await SupabaseClientManager.instance.client.auth
          .verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isLoading: true,
          clearPendingEmail: true,
        );
        await _loadProfile(response.user!.id);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Update the user's profile.
  Future<void> updateProfile(KlearUser profile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(usersRepositoryProvider);
      final updated = await repo.upsertProfile(profile);
      state = state.copyWith(profile: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await SupabaseClientManager.instance.client.auth.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

/// Provider for the auth state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
