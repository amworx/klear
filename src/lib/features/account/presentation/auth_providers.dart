import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logger/app_logger.dart';
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
    this.isInitializing = false,
    this.justSignedUp = false,
    this.onboardingCompleted = false,
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

  /// True while the persisted session is being recovered at startup (and the
  /// profile is loading for a signed-in user). The router must stay on the
  /// branded splash — never render welcome/profile-setup — until this is false.
  final bool isInitializing;

  /// True only for the short window after a brand-new account is created in
  /// this session. Used to show the new-user onboarding once (existing users
  /// who simply restored a session never get it).
  final bool justSignedUp;

  /// Persisted flag: the new-user onboarding has been completed at least once.
  final bool onboardingCompleted;

  final String? error;

  bool get isAuthenticated => user != null;
  bool get hasProfile => profile != null && !profile!.isGuest;

  /// Show the onboarding only to users who just signed up and haven't
  /// completed it yet.
  bool get shouldShowOnboarding => justSignedUp && !onboardingCompleted;

  AuthState copyWith({
    User? user,
    KlearUser? profile,
    String? pendingEmail,
    bool? isLoading,
    bool? isInitializing,
    bool? justSignedUp,
    bool? onboardingCompleted,
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
      isInitializing: isInitializing ?? this.isInitializing,
      justSignedUp: justSignedUp ?? this.justSignedUp,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      error: error,
    );
  }
}

/// Notifier for the auth state.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState(isInitializing: true)) {
    _init();
  }

  final Ref _ref;

  /// SharedPreferences key for the persisted onboarding-completed flag.
  static const String _onboardingKey = 'klear_onboarding_completed_v1';

  void _init() {
    // No backend configured (tests / offline mode): stay signed out and ready
    // so the router redirects everyone to the welcome screen.
    if (!SupabaseClientManager.isReady) {
      state = const AuthState();
      return;
    }

    // Recover the persisted onboarding flag (async, non-blocking). Subsequent
    // `copyWith` calls below preserve it.
    SharedPreferences.getInstance().then((prefs) {
      final done = prefs.getBool(_onboardingKey) ?? false;
      if (mounted) state = state.copyWith(onboardingCompleted: done);
    });

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

    // Check current session. `Supabase.initialize()` is awaited in main(), so
    // the persisted session has already been recovered and `currentUser` is
    // authoritative here. We stay `isInitializing` until the profile load
    // finishes so the router never flashes the profile-setup form at startup.
    final currentUser = SupabaseClientManager.instance.client.auth.currentUser;
    if (currentUser != null) {
      state = state.copyWith(user: currentUser, isLoading: true);
      _loadProfile(currentUser.id);
    } else {
      // No session recovered — the welcome screen is the correct landing page.
      state = const AuthState();
    }
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final repo = _ref.read(usersRepositoryProvider);
      final profile = await repo.getProfile(userId);
      AppLogger.instance.i('auth', 'profile loaded for $userId');
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        isInitializing: false,
      );
    } catch (e, st) {
      AppLogger.instance.e('auth', 'loadProfile failed for $userId', e, st);
      state = state.copyWith(
        isLoading: false,
        isInitializing: false,
        error: e.toString(),
      );
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
    AppLogger.instance.i('auth', 'signInWithEmail $email (create=$shouldCreateUser)');
    try {
      await SupabaseClientManager.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: AppConfig.emailRedirectUrl,
        shouldCreateUser: shouldCreateUser,
      );
       AppLogger.instance.i('auth', 'signInWithOtp succeeded for $email');
       state = state.copyWith(isLoading: false);
    } catch (e, st) {
      AppLogger.instance.e('auth', 'signInWithOtp failed for $email', e, st);
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
    AppLogger.instance.i('auth', 'verifyOTP for $email');
    try {
      final response = await SupabaseClientManager.instance.client.auth
          .verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      if (response.user != null) {
        AppLogger.instance.i('auth', 'verifyOTP succeeded for $email');
        state = state.copyWith(
          user: response.user,
          isLoading: true,
          clearPendingEmail: true,
        );
        await _loadProfile(response.user!.id);
      } else {
        AppLogger.instance.w('auth', 'verifyOTP returned no user for $email');
        state = state.copyWith(isLoading: false);
      }
    } catch (e, st) {
      AppLogger.instance.e('auth', 'verifyOTP failed for $email', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// Mark the new-user onboarding as completed (persisted) so it is never
  /// shown again for this user/device.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    state = state.copyWith(onboardingCompleted: true, justSignedUp: false);
  }

  /// Update the user's profile.
  Future<void> updateProfile(KlearUser profile) async {
    // A user saving their profile for the first time (profile was null) is a
    // brand-new sign-up — flag them so the router shows the onboarding once.
    final wasNewUser = state.profile == null;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = _ref.read(usersRepositoryProvider);
      final updated = await repo.upsertProfile(profile);
      state = state.copyWith(
        profile: updated,
        isLoading: false,
        justSignedUp: wasNewUser,
      );
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
