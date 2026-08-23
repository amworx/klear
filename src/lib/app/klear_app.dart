import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../core/l10n/app_locales.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/account/presentation/auth_providers.dart';
import '../features/account/presentation/profile_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/addresses/presentation/address_book_page.dart';
import '../features/addresses/presentation/map_picker_page.dart';
import '../features/auth/email_signin_page.dart';
import '../features/auth/otp_verify_page.dart';
import '../features/auth/profile_setup_page.dart';
import '../features/auth/welcome_page.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/diagnostics/presentation/logs_page.dart';
import '../features/bookings/presentation/booking_details_page.dart';
import '../features/bookings/presentation/confirmation_page.dart';
import '../features/bookings/presentation/service_selection_page.dart';
import '../features/cars/presentation/car_form_page.dart';
import '../features/cars/presentation/cars_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/orders/presentation/order_details_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/services/presentation/services_page.dart';
import 'scaffold_with_navbar.dart';
import 'app_router.dart';
import 'widgets/klear_splash_page.dart';

/// Root widget for the Klear application.
class KlearApp extends StatelessWidget {
  const KlearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _KlearAppContent();
  }
}

class _KlearAppContent extends ConsumerStatefulWidget {
  const _KlearAppContent();

  @override
  ConsumerState<_KlearAppContent> createState() => _KlearAppContentState();
}

class _KlearAppContentState extends ConsumerState<_KlearAppContent> {
  // The router is created ONCE and reused for the lifetime of the app.
  //
  // Creating it inside `build()` (as this class did previously) meant every
  // rebuild of MaterialApp — notably a language switch, which changes
  // `localeControllerProvider` — constructed a brand-new GoRouter whose
  // initial location is `/`. Tapping العربية/English on the Account tab
  // therefore bounced the user back to Home. Keeping one instance preserves
  // navigation state across locale (and theme) changes.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(ref);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Arabic by default; only changes when the user explicitly toggles it.
    final appLocale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'Klear',
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: appLocale,
      themeMode: themeMode,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: _router,
    );
  }

  GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: _AuthListenable(ref),
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final loc = state.matchedLocation;
        // Startup gate: stay on the branded splash until the persisted session
        // has been recovered and (for signed-in users) the profile has loaded.
        // Without this the router flashes the welcome / profile-setup form
        // while the async profile fetch is still in flight.
        if (auth.isInitializing) return '/splash';
        // Leave the splash as soon as initialization completes.
        if (loc == '/splash') {
          return (auth.isAuthenticated && auth.hasProfile) ? '/' : '/welcome';
        }
        final isAuthRoute = loc.startsWith('/welcome') ||
            loc.startsWith('/auth/') ||
            loc.startsWith('/diagnostics');
        // Guests are not allowed into the main app (tabs, profile, settings,
        // cars, addresses) — they are bounced to the welcome screen.
        final isProfileSetup = loc == '/auth/profile';
        // Map picker and diagnostics are reachable before AND after profile setup
        // and even when unauthenticated (so an error SnackBar's "View logs"
        // works from the sign-in form and the welcome screen).
        final isMapPicker = loc == '/map-picker';
        final isDiagnostics = loc == '/diagnostics/logs';
        if (!auth.isAuthenticated &&
            !isAuthRoute &&
            !isMapPicker &&
            !isDiagnostics) {
          return '/welcome';
        }
        // Only redirect to profile-setup when we have actually checked the
        // profile and know it is missing — not while it is still loading.
        if (auth.isAuthenticated &&
            !auth.hasProfile &&
            !auth.isLoading &&
            !auth.isInitializing &&
            !isProfileSetup &&
            !isMapPicker &&
            !isDiagnostics) {
          return '/auth/profile';
        }
        // Allow an authenticated user with a profile to explicitly visit
        // /auth/profile to edit their profile (via Profile → Edit profile).
        // Without this exception the rule below would bounce them back to
        // `/` — authed users must never linger on the sign-up/sign-in forms.
        final isProfileSetupExplicit = isProfileSetup;
        if (auth.isAuthenticated &&
            auth.hasProfile &&
            !auth.isLoading &&
            loc.startsWith('/auth/') &&
            !isProfileSetupExplicit) {
          return '/';
        }
        // New-user onboarding gate: a freshly signed-up user (with a profile
        // now saved) is sent to the onboarding flow exactly once. Once
        // completed (or for any returning user) they go straight to Home.
        if (auth.isAuthenticated &&
            auth.hasProfile &&
            auth.shouldShowOnboarding &&
            loc != KlearRoutes.onboarding) {
          return KlearRoutes.onboarding;
        }
        return null;
      },
      routes: _buildRoutes(),
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(state.error?.toString() ?? 'Unknown error')),
      ),
    );
  }

  List<RouteBase> _buildRoutes() {
    return [
      // Startup splash (shown while the persisted session is recovered).
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            _fadeSlidePage(const KlearSplashPage()),
      ),
      // Auth routes live OUTSIDE the bottom-nav shell.
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => _fadeSlidePage(const WelcomePage()),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (context, state) =>
            _fadeSlidePage(const EmailSignInPage(mode: AuthMode.login)),
      ),
      GoRoute(
        path: '/auth/signup',
        pageBuilder: (context, state) =>
            _fadeSlidePage(const EmailSignInPage(mode: AuthMode.signup)),
      ),
      GoRoute(
        path: '/auth/otp',
        pageBuilder: (context, state) => _fadeSlidePage(const OtpVerifyPage()),
      ),
      GoRoute(
        path: '/auth/profile',
        pageBuilder: (context, state) =>
            _fadeSlidePage(const ProfileSetupPage()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadeSlidePage(const OnboardingPage()),
      ),
      // Full-screen detours (outside the bottom-nav shell): map picker and
      // the address book. Both are pushed with `context.push` from any branch.
      GoRoute(
        path: '/map-picker',
        pageBuilder: (context, state) => _fadeSlidePage(const MapPickerPage()),
      ),
      GoRoute(
        path: '/diagnostics/logs',
        pageBuilder: (context, state) => _fadeSlidePage(const LogsPage()),
      ),
      // User profile — full-screen detour from the top-bar avatar.
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _fadeSlidePage(const ProfilePage()),
      ),
      // My Cars — pushed from the profile screen.
      GoRoute(
        path: '/cars',
        pageBuilder: (context, state) => _fadeSlidePage(const CarsPage()),
        routes: [
          GoRoute(
            path: 'add',
            pageBuilder: (context, state) =>
                _fadeSlidePage(const CarFormPage()),
          ),
          GoRoute(
            path: 'edit',
            pageBuilder: (context, state) => _fadeSlidePage(CarFormPage(
              car: state.extra as dynamic,
            )),
          ),
        ],
      ),
      // Address book — pushed from the profile screen or booking flow.
      GoRoute(
        path: '/addresses',
        pageBuilder: (context, state) => _fadeSlidePage(
          AddressBookPage(selectable: state.extra == true),
        ),
      ),
      // Main app with bottom nav.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ScaffoldWithNavBar(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                pageBuilder: (context, state) => _fadeSlidePage(const HomePage()),
                routes: [
                  GoRoute(
                    path: 'book/service',
                    pageBuilder: (context, state) =>
                        _fadeSlidePage(const ServiceSelectionPage()),
                  ),
                  GoRoute(
                    path: 'book/details',
                    pageBuilder: (context, state) =>
                        _fadeSlidePage(const BookingDetailsPage()),
                  ),
                  GoRoute(
                    path: 'book/confirm',
                    pageBuilder: (context, state) =>
                        _fadeSlidePage(const ConfirmationPage()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/services',
                pageBuilder: (context, state) => _fadeSlidePage(const ServicesPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                pageBuilder: (context, state) => _fadeSlidePage(const OrdersPage()),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) => _fadeSlidePage(
                      OrderDetailPage(
                        bookingId: state.pathParameters['id'] ?? '',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    _fadeSlidePage(const SettingsPage()),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

/// Shared fade + subtle slide page transition for all routes.
///
/// Honors reduced-motion (renders instantly) and keeps durations short
/// (280ms in / 220ms out) per the app motion system.
Page<void> _fadeSlidePage(Widget child) {
  return CustomTransitionPage<void>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Makes the router refresh when auth state changes.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _sub = _ref.listenManual<AuthState>(authProvider, (prev, next) {
      if (prev?.isAuthenticated != next.isAuthenticated ||
          prev?.hasProfile != next.hasProfile ||
          prev?.isInitializing != next.isInitializing ||
          prev?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });
  }

  final WidgetRef _ref;
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
