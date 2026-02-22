import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';

/// Widget pour changer la langue de l'application
class LanguageSelector extends StatelessWidget {
  final bool showAsDropdown;
  final bool showAsDialog;

  const LanguageSelector({
    super.key,
    this.showAsDropdown = false,
    this.showAsDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);

    if (showAsDropdown) {
      return _buildDropdown(context, localeProvider, theme);
    }

    return _buildButton(context, localeProvider, theme);
  }

  Widget _buildButton(
    BuildContext context,
    LocaleProvider localeProvider,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => _showLanguageDialog(context, localeProvider),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              localeProvider.currentLanguageName,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    LocaleProvider localeProvider,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: localeProvider.locale.languageCode,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          items: const [
            DropdownMenuItem(
              value: 'fr',
              child: Row(
                children: [
                  Text('🇫🇷'),
                  SizedBox(width: 12),
                  Text('Français'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Row(
                children: [
                  Text('🇬🇧'),
                  SizedBox(width: 12),
                  Text('English'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value == 'fr') {
              localeProvider.setFrench();
            } else if (value == 'en') {
              localeProvider.setEnglish();
            }
          },
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Text(context.tr('change_language')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context: context,
                localeProvider: localeProvider,
                languageCode: 'fr',
                flag: '🇫🇷',
                name: 'Français',
                subtitle: 'French',
              ),
              const SizedBox(height: 8),
              _buildLanguageOption(
                context: context,
                localeProvider: localeProvider,
                languageCode: 'en',
                flag: '🇬🇧',
                name: 'English',
                subtitle: 'Anglais',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required LocaleProvider localeProvider,
    required String languageCode,
    required String flag,
    required String name,
    required String subtitle,
  }) {
    final isSelected = localeProvider.locale.languageCode == languageCode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        if (languageCode == 'fr') {
          localeProvider.setFrench();
        } else {
          localeProvider.setEnglish();
        }
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : null,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

/// Bouton compact pour changer de langue rapidement
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);

    return IconButton(
      onPressed: () => localeProvider.toggleLocale(),
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          localeProvider.locale.languageCode.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      tooltip: context.tr('change_language'),
    );
  }
}
