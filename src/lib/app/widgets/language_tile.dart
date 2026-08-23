import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../core/l10n/app_locales.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/widgets/motion.dart';

/// Persisted Arabic/English language switcher.
///
/// Shown on the Welcome screen (guests) and in the Account tab
/// (authenticated users). Arabic is always the default; English is an
/// explicit opt-in only.
///
/// Each option renders in its own script (العربية / English) as an
/// active-pill button, so the choice is obvious at a glance in both RTL
/// and LTR directions.
class LanguageTile extends ConsumerWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(localeControllerProvider);
    final isArabic = locale == AppLocales.arabic;

    final notifier = ref.read(localeControllerProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              leading: const Icon(Icons.translate),
              title: Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _LanguagePill(
                    label: l10n.languageArabic,
                    active: isArabic,
                    semanticLabel: l10n.languageArabic,
                    onTap: () => notifier.setLocale(AppLocales.arabic),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LanguagePill(
                    label: l10n.languageEnglish,
                    active: !isArabic,
                    semanticLabel: l10n.languageEnglish,
                    onTap: () => notifier.setLocale(AppLocales.english),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-icon language switcher for compact placements (e.g. the top corner
/// of the Welcome screen).
///
/// Opens a Material popup listing both languages in their own script
/// (العربية / English) with the active one checked — same persistence and
/// Arabic-default rules as [LanguageTile], one icon instead of a card.
class LanguageMenuButton extends ConsumerWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isArabic = ref.watch(localeControllerProvider) == AppLocales.arabic;
    final notifier = ref.read(localeControllerProvider.notifier);

    return PopupMenuButton<Locale>(
      tooltip: l10n.language,
      icon: const Icon(Icons.translate),
      onSelected: notifier.setLocale,
      itemBuilder: (_) => [
        CheckedPopupMenuItem(
          value: AppLocales.arabic,
          checked: isArabic,
          child: Text(l10n.languageArabic),
        ),
        CheckedPopupMenuItem(
          value: AppLocales.english,
          checked: !isArabic,
          child: Text(l10n.languageEnglish),
        ),
      ],
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.label,
    required this.active,
    required this.semanticLabel,
    required this.onTap,
  });

  /// Shown in the language's own script (e.g. العربية / English).
  final String label;
  final bool active;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final foreground = active ? scheme.onPrimary : scheme.onSurfaceVariant;
    final background = active ? scheme.primary : scheme.surfaceContainerHigh;
    final borderColor = active ? scheme.primary : scheme.outlineVariant;

    return Semantics(
      label: semanticLabel,
      selected: active,
      button: true,
      child: AnimatedPress(
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      active
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      key: ValueKey(active),
                      size: 18,
                      color: active ? foreground : scheme.outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
