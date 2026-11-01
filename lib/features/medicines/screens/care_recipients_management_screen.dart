import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/medicines/models/care_recipient.dart';
import '../../../features/medicines/providers/medications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/page_content.dart';
import 'medication_recipient_screen.dart';

class CareRecipientsManagementScreen extends ConsumerStatefulWidget {
  const CareRecipientsManagementScreen({super.key});

  @override
  ConsumerState<CareRecipientsManagementScreen> createState() =>
      _CareRecipientsManagementScreenState();
}

class _CareRecipientsManagementScreenState
    extends ConsumerState<CareRecipientsManagementScreen> {
  late Future<List<CareRecipient>> _recipients;

  @override
  void initState() {
    super.initState();
    _recipients = _load();
  }

  Future<List<CareRecipient>> _load() =>
      ref.read(careRecipientRepositoryProvider).getAll();

  void _refresh() => setState(() => _recipients = _load());

  Future<void> _edit([CareRecipient? recipient]) async {
    await Navigator.of(context).push<CareRecipient>(
      MaterialPageRoute(
        builder: (_) => CareRecipientFormScreen(recipient: recipient),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _remove(CareRecipient recipient) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(l10n.removeCareRecipient),
            content: Text(l10n.removeCareRecipientBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.archiveMedication),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(careRecipientRepositoryProvider).delete(recipient.id!);
      if (mounted) _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsSaveError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageCareRecipients)),
      body: PageContent(
        children: [
          PageHeading(
            title: l10n.manageCareRecipients,
            subtitle: l10n.medicationRecipientSupport,
          ),
          FilledButton.icon(
            onPressed: () => _edit(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(l10n.medicationRecipientAdd),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<CareRecipient>>(
            future: _recipients,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: l10n.settingsLoadError,
                  message: l10n.settingsLoadError,
                  action: OutlinedButton(
                    onPressed: _refresh,
                    child: Text(l10n.retry),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final recipients = snapshot.data!;
              if (recipients.isEmpty) {
                return EmptyState(
                  icon: Icons.diversity_1_outlined,
                  title: l10n.careRecipientsEmpty,
                  message: l10n.careRecipientsEmpty,
                );
              }
              return Column(
                children:
                    recipients
                        .map(
                          (recipient) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              onTap: () => _edit(recipient),
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline_rounded),
                              ),
                              title: Text(recipient.name),
                              subtitle:
                                  recipient.relationship == null
                                      ? null
                                      : Text(recipient.relationship!),
                              trailing: IconButton(
                                tooltip: l10n.removeCareRecipient,
                                onPressed: () => _remove(recipient),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
