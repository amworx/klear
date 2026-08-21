/// Maps common error patterns to user-facing suggestions.
///
/// Shown in the log viewer and in error SnackBars so the user gets
/// actionable guidance while the admin reviews the report.
class ErrorSuggestions {
  const ErrorSuggestions._();

  /// Returns a short, localized suggestion for [errorText], or null if no
  /// pattern matches (caller should show a generic fallback).
  static String? forError(String errorText) {
    final e = errorText.toLowerCase();

    if (e.contains('failed host lookup') ||
        e.contains('no address associated') ||
        e.contains('socketexception') ||
        e.contains('network is unreachable') ||
        e.contains('clientexception with socketexception')) {
      return 'Network/DNS issue. Check your internet, try switching Wi-Fi ↔ mobile data, '
          'or set Private DNS to dns.google (Settings → Network → Private DNS). '
          'Then tap Retry.';
    }
    if (e.contains('signups not allowed for otp') || e.contains('otp_disabled')) {
      return 'Sign-ups via code are currently disabled. If you already have an account, '
          'use “Sign in”. Otherwise contact support or try again later.';
    }
    if (e.contains('over_email_send_rate_limit') || e.contains('rate limit') || e.contains('429')) {
      return 'Too many requests — please wait about 60 seconds, then try again.';
    }
    if (e.contains('user not found') || e.contains('invalid login credentials')) {
      return 'No account found with this email. Try “Create account” instead of “Sign in”, '
          'or check the spelling.';
    }
    if (e.contains('invalid otp') || e.contains('otp_expired') || e.contains('token has expired')) {
      return 'The code is incorrect or has expired (codes are valid for ~1 hour). '
          'Request a new code and try again.';
    }
    if (e.contains('email not confirmed') || e.contains('email_not_confirmed')) {
      return 'Your email is not yet confirmed. Check your inbox for the confirmation link.';
    }
    if (e.contains('lateinitializationerror') || e.contains("field 'client' hasn't been initialized")) {
      return 'App was built without backend configuration. Please update the app to the latest version.';
    }
    return null;
  }

  static const String generic =
      'Please try again. If the problem persists, tap “Share with admin” on the Diagnostics → Logs screen '
      'to send the details — the team will review and get back to you.';
}
