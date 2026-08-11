import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../core/l10n/app_locales.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../features/account/presentation/account_page.dart';
import '../features/account/presentation/auth_providers.dart';
import '../features/auth/email_signin_page.dart';
import '../features/auth/otp_verify_page.dart';
import '../features/auth/profile_setup_page.dart';
import '../features/auth/welcome_page.dart';
import '../features/bookings/presentation/booking_details_page.dart';
import '../features/bookings/presentation/confirmation_page.dart';
import '../features/bookings/presentation/service_selection_page.dart';
import '../features/cars/presentation/car_form_page.dart';
import '../features/cars/presentation/cars_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/orders/presentation/orders_page.dart';
import '../features/services/presentation/services_page.dart';
import 'scaffold_with_navbar.dart';

/// Root widget for the Klear application.
class KlearApp extends StatelessWidget {
  const KlearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _KlearAppContent();
  }
}

class _KlearAppContent extends ConsumerWidget {
  const _KlearAppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Arabic by default; only changes when the user explicitly toggles it.
    final appLocale = ref.watch(localeControllerProvider);
    final router = _buildRouter(ref);
    return MaterialApp.router(
      title: 'Klear',
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      locale: appLocale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }

  GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: _AuthListenable(ref),
      redirect: (context, state) {
        final auth = ref.read(authProvider);
        final loc = state.matchedLocation;
        final isAuthRoute = loc.startsWith('/welcome') ||
            loc.startsWith('/auth/');
        final isProfileSetup = loc == '/auth/profile';
        if (!auth.isAuthenticated && !isAuthRoute) {
          return '/welcome';
        }
        if (auth.isAuthenticated && !auth.hasProfile && !isProfileSetup) {
          return '/auth/profile';
        }
        if (auth.isAuthenticated && auth.hasProfile && isAuthRoute) {
          return '/';
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                pageBuilder: (context, state) => _fadeSlidePage(const AccountPage()),
                routes: [
                  GoRoute(
                    path: 'cars',
                    pageBuilder: (context, state) =>
                        _fadeSlidePage(const CarsPage()),
                  ),
                  GoRoute(
                    path: 'cars/add',
                    pageBuilder: (context, state) =>
                        _fadeSlidePage(const CarFormPage()),
                  ),
                  GoRoute(
                    path: 'cars/edit',
                    pageBuilder: (context, state) =>
                        _fadeSlidePage(CarFormPage(
                      car: state.extra as dynamic,
                    )),
                  ),
                ],
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
          prev?.hasProfile != next.hasProfile) {
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
