import 'package:flutter/material.dart';

import '../../../core/constants/app_info.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/page_content.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({required this.isPrivacy, super.key});
  final bool isPrivacy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isPrivacy ? l10n.privacy : l10n.about)),
      body: PageContent(
        children: [
          PageHeading(
            title: isPrivacy ? l10n.privacyTitle : l10n.appTitle,
            subtitle:
                isPrivacy
                    ? l10n.privateOnDevice
                    : '${l10n.version} ${AppInfo.versionLabel}',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                isPrivacy ? l10n.privacyBody : l10n.aboutBody,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.9),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.disclaimerTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            l10n.disclaimer,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.9),
          ),
        ],
      ),
    );
  }
}
