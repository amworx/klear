import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_router.dart';
import '../../../core/widgets/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../account/presentation/auth_providers.dart';

/// OTP verification screen. User enters the 6-digit code sent to their email.
class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final _tokenController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final token = _tokenController.text.trim();
    final auth = ref.read(authProvider);
    final email = auth.pendingEmail ?? auth.user?.email;
    if (email == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email missing — go back and re-enter it.'),
        ),
      );
      return;
    }
    try {
      await ref.read(authProvider.notifier).verifyEmailOtp(
            email: email,
            token: token,
          );
      if (!mounted) return;
      // After sign-in, go to profile setup (or home if profile already exists).
      final state = ref.read(authProvider);
      if (state.hasProfile) {
        context.go('/');
      } else {
        context.go(KlearRoutes.profileSetup);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).errorLoadingServices}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final email = auth.pendingEmail ?? auth.user?.email;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyCode)),
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
                l10n.otpSent,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                email != null
                    ? '${l10n.otpSentSubtitle}\n$email'
                    : l10n.otpSentSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _tokenController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: l10n.otpCode,
                  hintText: '------',
                  counterText: '',
                ),
                validator: (value) {
                  final len = value?.trim().length ?? 0;
                  if (len < 6 || len > 8) {
                    return l10n.otpInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: auth.isLoading ? null : _verify,
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.verify),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
