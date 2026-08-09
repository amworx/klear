import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../account/presentation/auth_providers.dart';

/// Which entry point opened this screen.
///
/// - [AuthMode.login]: existing user signs in (Supabase is told NOT to create
///   the user, so a wrong email yields a clear error instead of a surprise
///   account).
/// - [AuthMode.signup]: a new account is created for the email, after which
///   the user fills the profile.
enum AuthMode { login, signup }

/// Email entry screen. The user types their email and receives a one-time
/// code (OTP). Whether the email must already exist (login) or accounts are
/// created on the spot (signup) is controlled by [mode].
class EmailSignInPage extends ConsumerStatefulWidget {
  const EmailSignInPage({super.key, required this.mode});

  final AuthMode mode;

  @override
  ConsumerState<EmailSignInPage> createState() => _EmailSignInPageState();
}

class _EmailSignInPageState extends ConsumerState<EmailSignInPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool get _isSignup => widget.mode == AuthMode.signup;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim().toLowerCase();
    try {
      await ref
          .read(authProvider.notifier)
          .signInWithEmail(email, shouldCreateUser: _isSignup);
      if (!mounted) return;
      context.push(KlearRoutes.otpVerify);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context).errorLoadingServices}: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSignup
              ? l10n.createAccountTitle
              : l10n.signInTitle,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: StaggerList(
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _isSignup
                    ? l10n.createAccountSubtitle
                    : l10n.signInSubtitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.otpSentSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.emailAddress,
                  hintText: 'name@example.com',
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return l10n.emailRequired;
                  if (!_emailRegex.hasMatch(email)) return l10n.emailInvalid;
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: auth.isLoading ? null : _sendOtp,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isSignup
                        ? l10n.createAccount
                        : l10n.signInTitle),
              ),
              const SizedBox(height: 12),
              // Switch between the two flows.
              TextButton(
                onPressed: () => context.go(
                  _isSignup ? KlearRoutes.signIn : KlearRoutes.signUp,
                ),
                child: Text(
                  _isSignup ? l10n.haveAccount : l10n.noAccount,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}