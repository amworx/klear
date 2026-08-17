/// Route path constants used by `go_router`.
///
/// The router is built in `klear_app.dart` (root widget) so it can be
/// reactive to Riverpod auth state. This file only exposes the path
/// constants used across the app.
///
/// Note: go_router resolves locations WITHOUT a leading '/' relative to the
/// current location. Separate-bookkeeping: constants used with `go`/`push`
/// from a non-root screen MUST include the leading '/' (full path), e.g.
/// `/book/car`. Only true top-level detours (welcome/auth) are also absolute.
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
  /// Booking detail (inside the orders branch). Uses a path param for the id.
  static const String ordersDetail = '/orders/:id';
  static const String account = '/account';
  // Booking flow (child routes of the home branch). MUST be absolute paths:
  // go_router resolves a relative location ('book/car') against the CURRENT
  // location, so from /book/service it produces /book/book/car and throws
  // "no routes for location". Absolute paths match the full child route.
  static const String bookSelectService = '/book/service';
  static const String bookDetails = '/book/details';
  static const String bookConfirm = '/book/confirm';
  // My Cars (child routes of the account branch).
  static const String myCars = '/account/cars';
  static const String carAdd = '/account/cars/add';
  static const String carEdit = '/account/cars/edit';
  // Address book (child route of the account branch).
  static const String addressBook = '/account/addresses';
  // Map picker (full-screen detour; pushed with `context.push`).
  static const String mapPicker = '/map-picker';
}

/// Bottom-nav branch index keys.
class NavBranch {
  const NavBranch._();
  static const int home = 0;
  static const int services = 1;
  static const int orders = 2;
  static const int account = 3;
}
