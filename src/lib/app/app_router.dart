/// Route path constants used by `go_router`.
///
/// The router is built in `klear_app.dart` (root widget) so it can be
/// reactive to Riverpod auth state. This file only exposes the path
/// constants used across the app.
///
/// Note: child routes of '/' (home branch) should NOT start with '/'.
/// Only top-level routes (outside the shell) start with '/'.
class KlearRoutes {
  const KlearRoutes._();
  // Top-level routes (outside the bottom-nav shell).
  static const String welcome = '/welcome';
  static const String signIn = '/auth/login';
  static const String signUp = '/auth/signup';
  static const String otpVerify = '/auth/otp';
  static const String profileSetup = '/auth/profile';
  // Shell routes (inside the bottom-nav).
  static const String home = '/';
  static const String services = '/services';
  static const String orders = '/orders';
  static const String account = '/account';
  // Booking flow (child routes of home).
  static const String bookSelectService = 'book/service';
  static const String bookLocation = 'book/location';
  static const String bookDateTime = 'book/datetime';
  static const String bookConfirm = 'book/confirm';
}

/// Bottom-nav branch index keys.
class NavBranch {
  const NavBranch._();
  static const int home = 0;
  static const int services = 1;
  static const int orders = 2;
  static const int account = 3;
}
