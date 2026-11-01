import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../features/medicines/models/care_recipient.dart';
import '../../../features/medicines/providers/medications_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'medication_frequency_screen.dart';

class MedicationRecipientScreen extends ConsumerStatefulWidget {
  const MedicationRecipientScreen({super.key});

  @override
  ConsumerState<MedicationRecipientScreen> createState() =>
      _MedicationRecipientScreenState();
}

class _MedicationRecipientScreenState
    extends ConsumerState<MedicationRecipientScreen> {
  List<CareRecipient> _recipients = [];
  bool _loading = true;
  bool _openingMedication = false;
  bool _creatingRecipient = false;
  int _recipientLoadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    final generation = ++_recipientLoadGeneration;
    try {
      final recipients =
          await ref.read(careRecipientRepositoryProvider).getAll();
      if (!mounted || generation != _recipientLoadGeneration) return;
      setState(() {
        _recipients = recipients;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _recipientLoadGeneration) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).settingsLoadError)),
      );
    }
  }

  Future<void> _addRecipient() async {
    if (_creatingRecipient || _openingMedication) return;
    setState(() => _creatingRecipient = true);
    try {
      final added = await Navigator.of(context).push<CareRecipient>(
        MaterialPageRoute(builder: (_) => const CareRecipientFormScreen()),
      );
      if (added == null || !mounted) return;
      _recipientLoadGeneration++;
      setState(() {
        _recipients = [
          ..._recipients.where((recipient) => recipient.id != added.id),
          added,
        ];
        _loading = false;
      });
      await _openMedicationFrequency(added.id, recipientName: added.name);
    } finally {
      if (mounted) setState(() => _creatingRecipient = false);
    }
  }

  Future<void> _chooseSelf() => _openMedicationFrequency(
    null,
    recipientName: AppLocalizations.of(context).measurementSelf,
  );

  Future<void> _openMedicationFrequency(
    int? recipientId, {
    String? recipientName,
  }) async {
    if (_openingMedication) return;
    setState(() => _openingMedication = true);
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder:
              (_) => MedicationFrequencyScreen(
                recipientId: recipientId,
                recipientName: recipientName,
              ),
        ),
      );
      if (!mounted) return;
      if (saved == true) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _openingMedication = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).height < 720;
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final accent = AppColors.accentFor(brightness);
    final primaryText = AppColors.primaryText(brightness);
    final secondaryText = AppColors.mutedText(brightness);
    return Scaffold(
      backgroundColor: AppColors.pageBackground(brightness),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [Color(0xFF071F2D), Color(0xFF10384B), Color(0xFF071F2D)]
                : const [Colors.white, Color(0xFFF0F8FA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 20, top: 8),
                  child: IconButton.filledTonal(
                    tooltip:
                        MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(false),
                    style: IconButton.styleFrom(
                      backgroundColor: dark
                          ? Colors.white.withValues(alpha: .08)
                          : AppColors.brand.withValues(alpha: .08),
                      foregroundColor: primaryText,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(26, compact ? 18 : 28, 26, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.medicationRecipientTitle,
                        textAlign: TextAlign.end,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(
                          color: primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.medicationRecipientBody,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: secondaryText,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: compact ? 28 : 42),
                      const _RecipientIllustration(),
                      SizedBox(height: compact ? 24 : 34),
                      Center(
                        child: TextButton.icon(
                          onPressed:
                              _creatingRecipient || _openingMedication
                                  ? null
                                  : _addRecipient,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.medicationRecipientAdd),
                          style: TextButton.styleFrom(
                            foregroundColor: accent,
                            textStyle: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_recipients.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ..._recipients.map(
                          (recipient) => _SavedRecipientRow(
                            recipient: recipient,
                            onTap:
                                _openingMedication
                                    ? null
                                    : () => _openMedicationFrequency(
                                      recipient.id,
                                      recipientName: recipient.name,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(22, 8, 22, compact ? 12 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.medicationRecipientSupport,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: secondaryText.withValues(alpha: dark ? .72 : 1),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 54,
                      child: OutlinedButton(
                        onPressed:
                            _openingMedication
                                ? null
                                : () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dark ? Colors.white : AppColors.brand,
                          side: BorderSide(
                            color: dark
                                ? Colors.white.withValues(alpha: .18)
                                : AppColors.subtleBorder(brightness),
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(l10n.medicationRecipientLater),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 58,
                      child: FilledButton(
                        onPressed:
                            _openingMedication || _creatingRecipient
                                ? null
                                : _chooseSelf,
                        style: FilledButton.styleFrom(
                          backgroundColor: dark ? const Color(0xFFB8F4DF) : AppColors.brand,
                          foregroundColor: dark ? const Color(0xFF073A37) : Colors.white,
                          disabledBackgroundColor: dark
                              ? const Color(0xFF47736A)
                              : const Color(0xFFE3EAED),
                          shape: const StadiumBorder(),
                        ),
                        child:
                            _openingMedication
                                ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  l10n.medicationRecipientOwn,
                                  textAlign: TextAlign.center,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipientIllustration extends StatelessWidget {
  const _RecipientIllustration();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 116,
    child: Center(
      child: SizedBox(
        width: 246,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: const [
            PositionedDirectional(
              start: 0,
              child: _AvatarBubble(
                icon: Icons.person_rounded,
                color: Color(0xFFA4E5D2),
                rotation: -.08,
              ),
            ),
            _AvatarBubble(
              icon: Icons.face_3_rounded,
              color: Color(0xFFC9B7EA),
              rotation: 0,
            ),
            PositionedDirectional(
              end: 0,
              child: _AvatarBubble(
                icon: Icons.pets_rounded,
                color: Color(0xFFEAAFC4),
                rotation: .06,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.icon,
    required this.color,
    required this.rotation,
  });

  final IconData icon;
  final Color color;
  final double rotation;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: rotation,
    child: Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF10384B)
              : Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? .18 : .08,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 46,
        color: const Color(0xFF25343A),
      ),
    ),
  );
}

class _SavedRecipientRow extends StatelessWidget {
  const _SavedRecipientRow({required this.recipient, required this.onTap});
  final CareRecipient recipient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final dark = brightness == Brightness.dark;
    final primaryText = AppColors.primaryText(brightness);
    final secondaryText = AppColors.mutedText(brightness);
    return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Material(
      color: dark ? Colors.white.withValues(alpha: .07) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.chevron_left_rounded,
                color: dark ? Colors.white70 : AppColors.brand,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    recipient.name,
                    style: TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (recipient.relationship?.isNotEmpty ?? false)
                    Text(
                      recipient.relationship!,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFA4E5D2),
                child: Text(
                  recipient.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF25343A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class CareRecipientFormScreen extends ConsumerStatefulWidget {
  const CareRecipientFormScreen({this.recipient, super.key});

  final CareRecipient? recipient;

  @override
  ConsumerState<CareRecipientFormScreen> createState() =>
      _CareRecipientFormScreenState();
}

class _CareRecipientFormScreenState
    extends ConsumerState<CareRecipientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _relationship;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.recipient?.name ?? '');
    _relationship = TextEditingController(
      text: widget.recipient?.relationship ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(careRecipientRepositoryProvider)
          .save(
            CareRecipient(
              id: widget.recipient?.id,
              name: _name.text,
              relationship: _relationship.text,
              createdAtUtc: widget.recipient?.createdAtUtc,
            ),
          );
      if (mounted) {
        final relationship = _relationship.text.trim();
        Navigator.of(context).pop(
          CareRecipient(
            id: id,
            name: _name.text.trim(),
            relationship: relationship.isEmpty ? null : relationship,
            createdAtUtc: widget.recipient?.createdAtUtc,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).settingsSaveError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.pageBackground(brightness),
      appBar: AppBar(
        title: Text(l10n.careRecipientCreateTitle),
        backgroundColor: AppColors.pageBackground(brightness),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                l10n.careRecipientCreateTitle,
                style: textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                maxLength: 80,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.measurementRecipientName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? l10n.invalidMedicationName
                            : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _relationship,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.careRecipientRelationship,
                  prefixIcon: const Icon(Icons.diversity_1_outlined),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon:
                    _saving
                        ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check_rounded),
                label: Text(l10n.done),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
