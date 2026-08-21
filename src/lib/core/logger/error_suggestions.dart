/// Maps common error patterns to user-facing suggestions.
///
/// Shown in the log viewer and in error SnackBars so the user gets
/// actionable guidance while the admin reviews the report.
class ErrorSuggestions {
  const ErrorSuggestions._();

  /// Returns a short, localized suggestion for [errorText], or null if no
  /// pattern matches (caller should show a generic fallback). Pass `isArabic`
  /// based on the current app locale.
  static String? forError(String errorText, {bool isArabic = false}) {
    final e = errorText.toLowerCase();

    if (e.contains('failed host lookup') ||
        e.contains('no address associated') ||
        e.contains('socketexception') ||
        e.contains('network is unreachable') ||
        e.contains('clientexception with socketexception')) {
      return isArabic
          ? 'مشكلة في الشبكة/نظام الأسماء. تحقق من الإنترنت، جرّب التبديل بين الواي فاي وبيانات الهاتف، '
              'أو اضبط نظام الأسماء الخاص على dns.google (الإعدادات → الشبكة → نظام الأسماء الخاص). ثم اضغط إعادة المحاولة.'
          : 'Network/DNS issue. Check your internet, try switching Wi-Fi ↔ mobile data, '
              'or set Private DNS to dns.google (Settings → Network → Private DNS). '
              'Then tap Retry.';
    }
    if (e.contains('signups not allowed for otp') || e.contains('otp_disabled')) {
      return isArabic
          ? 'التسجيل عبر الرمز معطّل حالياً. إذا كان لديك حساب، استخدم “تسجيل الدخول”. وإلا تواصل مع الدعم أو حاول لاحقاً.'
          : 'Sign-ups via code are currently disabled. If you already have an account, '
              'use “Sign in”. Otherwise contact support or try again later.';
    }
    if (e.contains('over_email_send_rate_limit') || e.contains('rate limit') || e.contains('429')) {
      return isArabic
          ? 'طلبات كثيرة — يرجى الانتظار حوالي 60 ثانية ثم المحاولة مرة أخرى.'
          : 'Too many requests — please wait about 60 seconds, then try again.';
    }
    if (e.contains('user not found') || e.contains('invalid login credentials')) {
      return isArabic
          ? 'لا يوجد حساب بهذا البريد. جرّب “إنشاء حساب” بدلاً من “تسجيل الدخول”، أو تحقق من الإملاء.'
          : 'No account found with this email. Try “Create account” instead of “Sign in”, '
              'or check the spelling.';
    }
    if (e.contains('invalid otp') || e.contains('otp_expired') || e.contains('token has expired')) {
      return isArabic
          ? 'الرمز غير صحيح أو منتهي الصلاحية (الرموز صالحة لحوالي ساعة). اطلب رمزاً جديداً وحاول مرة أخرى.'
          : 'The code is incorrect or has expired (codes are valid for ~1 hour). '
              'Request a new code and try again.';
    }
    if (e.contains('email not confirmed') || e.contains('email_not_confirmed')) {
      return isArabic
          ? 'بريدك الإلكتروني غير مؤكد بعد. تحقق من صندوق الوارد للحصول على رابط التأكيد.'
          : 'Your email is not yet confirmed. Check your inbox for the confirmation link.';
    }
    if (e.contains('lateinitializationerror') || e.contains("field 'client' hasn't been initialized")) {
      return isArabic
          ? 'تم بناء التطبيق بدون إعدادات الخلفية. يرجى تحديث التطبيق إلى أحدث إصدار.'
          : 'App was built without backend configuration. Please update the app to the latest version.';
    }
    return null;
  }

  static String generic(bool isArabic) => isArabic
      ? 'حاول مرة أخرى. إذا استمرت المشكلة، اضغط “مشاركة مع الإدارة” في شاشة التشخيص → السجلات لإرسال التفاصيل — سيقوم الفريق بالمراجعة والرد عليك.'
      : 'Please try again. If the problem persists, tap “Share with admin” on the Diagnostics → Logs screen '
          'to send the details — the team will review and get back to you.';
}
