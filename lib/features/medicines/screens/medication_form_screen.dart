import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../features/doses/providers/doses_provider.dart';
import '../../../features/medicines/models/medication.dart';
import '../../../core/notifications/notification_scheduler.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/medications_provider.dart';
import '../widgets/medication_image_preview.dart';

class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({
    this.medication,
    this.recipientId,
    this.recipientName,
    this.indication,
    this.initialScheduleCount,
    this.allowNoSchedule = false,
    this.onboardingMode = false,
    super.key,
  });
  final Medication? medication;
  final int? recipientId;
  final String? recipientName;
  final String? indication;
  final int? initialScheduleCount;
  final bool allowNoSchedule;
  final bool onboardingMode;

  @override
  ConsumerState<MedicationFormScreen> createState() =>
      _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _amount;
  late final TextEditingController _customUnit;
  late final TextEditingController _customForm;
  late final TextEditingController _notes;
  late String _unit;
  late String _form;
  late DateTime _start;
  DateTime? _end;
  int? _color;
  bool _saving = false;
  bool _photoBusy = false;
  XFile? _pendingPhoto;
  bool _removeSavedPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
  late final bool _allowNoSchedule;
  late List<_ScheduleDraft> _schedules;

  static const _colors = [
    0xff009688,
    0xff5470c6,
    0xffe28b43,
    0xff9565a8,
    0xffcf6474,
  ];
  static const _units = ['mg', 'ml', 'tablet', 'capsule', 'drops', 'custom'];
  static const _forms = [
    'tablet',
    'capsule',
    'syrup',
    'injection',
    'drops',
    'cream',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _name = TextEditingController(text: med?.name ?? '');
    _amount = TextEditingController(text: med?.dosageAmount ?? '');
    _notes = TextEditingController(text: med?.notes ?? '');
    _unit =
        med != null && _units.contains(med.dosageUnit) ? med.dosageUnit : 'mg';
    _customUnit = TextEditingController(
      text: _unit == 'custom' ? med?.dosageUnit : '',
    );
    _form =
        med?.form == null
            ? ''
            : (_forms.contains(med!.form) ? med.form! : 'other');
    _customForm = TextEditingController(
      text: _form == 'other' ? med?.form : '',
    );
    _start = med?.startDate ?? DateUtils.dateOnly(DateTime.now());
    _end = med?.endDate;
    _color = med?.colorValue;
    _allowNoSchedule =
        widget.allowNoSchedule || (med != null && med.schedules.isEmpty);
    if (med != null) {
      _schedules = med.schedules.map(_ScheduleDraft.fromSchedule).toList();
    } else {
      final count = widget.initialScheduleCount ?? 1;
      _schedules = List.generate(
        count,
        (index) => _ScheduleDraft(
          time: TimeOfDay(hour: index == 1 ? 20 : 8, minute: 0),
        ),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _customUnit.dispose();
    _customForm.dispose();
    _notes.dispose();
    for (final row in _schedules) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: AppColors.pageBackground(brightness),
      appBar: AppBar(
        title: Text(
          widget.medication == null ? l10n.addMedication : l10n.editMedication,
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.pageGradientFor(brightness),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                if (widget.onboardingMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Chip(
                        avatar: const Icon(Icons.person_outline_rounded),
                        label: Text(
                          widget.recipientName ?? l10n.measurementSelf,
                        ),
                        backgroundColor:
                            brightness == Brightness.dark
                                ? const Color(0xFF123B45)
                                : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                        side: BorderSide(
                          color:
                              brightness == Brightness.dark
                                  ? Colors.white.withValues(alpha: .10)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                  ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section(
                          context,
                          l10n.medicineDetails,
                          Icons.medication_outlined,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _decoration(context, l10n.medicationName),
                          validator:
                              (v) =>
                                  (v?.trim().isEmpty ?? true)
                                      ? l10n.invalidMedicationName
                                      : null,
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: _decoration(
                                context,
                                l10n.dosageAmount,
                              ),
                              validator: (v) {
                                final value =
                                    MedicationValidator.normalizeAmount(
                                      v ?? '',
                                    );
                                return RegExp(
                                          r'^\d+(?:[.,]\d{1,3})?$',
                                        ).hasMatch(value) &&
                                        (double.tryParse(
                                                  value.replaceAll(',', '.'),
                                                ) ??
                                                0) >
                                            0
                                    ? null
                                    : l10n.invalidDosageAmount;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: _unit,
                              decoration: _decoration(context, l10n.dosageUnit),
                              items:
                                  _units
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(_unitLabel(l10n, u)),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (v) => setState(() => _unit = v ?? _unit),
                            ),
                          ],
                        ),
                        if (_unit == 'custom') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _customUnit,
                            decoration: _decoration(context, l10n.customUnit),
                            validator:
                                (v) =>
                                    _unit == 'custom' &&
                                            (v?.trim().isEmpty ?? true)
                                        ? l10n.invalidDosageUnit
                                        : null,
                          ),
                        ],
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _form.isEmpty ? null : _form,
                          decoration: _decoration(context, l10n.medicationForm),
                          hint: Text(l10n.chooseMedicationForm),
                          items:
                              _forms
                                  .map(
                                    (f) => DropdownMenuItem(
                                      value: f,
                                      child: Text(_formLabel(l10n, f)),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => _form = v ?? ''),
                        ),
                        if (_form == 'other') ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _customForm,
                            decoration: _decoration(context, l10n.customForm),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section(
                          context,
                          l10n.medicationPhotoTitle,
                          Icons.add_a_photo_outlined,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.medicationPhotoDescription,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 14),
                        MedicationImagePreview(
                          path:
                              _pendingPhoto?.path ??
                              (_removeSavedPhoto
                                  ? null
                                  : widget.medication?.imagePath),
                          temporary: _pendingPhoto != null,
                          height: 164,
                          placeholder: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.medication_outlined,
                                  size: 36,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.chooseMedicationPhoto,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed:
                                    _saving || _photoBusy ? null : _selectPhoto,
                                icon: Icon(
                                  _hasPhoto
                                      ? Icons.refresh_rounded
                                      : Icons.add_photo_alternate_outlined,
                                ),
                                label: Text(
                                  _hasPhoto
                                      ? l10n.replaceMedicationPhoto
                                      : l10n.chooseMedicationPhoto,
                                ),
                              ),
                            ),
                            if (_hasPhoto)
                              IconButton(
                                tooltip: l10n.removeMedicationPhoto,
                                onPressed:
                                    _saving || _photoBusy
                                        ? null
                                        : () => setState(() {
                                          _pendingPhoto = null;
                                          _removeSavedPhoto = true;
                                        }),
                                icon: const Icon(Icons.delete_outline_rounded),
                              ),
                          ],
                        ),
                        if (_photoBusy) const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _section(
                          context,
                          l10n.startDate,
                          Icons.date_range_outlined,
                        ),
                        const SizedBox(height: 16),
                        _dateTile(
                          context,
                          l10n.startDate,
                          _start,
                          (d) => setState(() {
                            _start = d;
                            if (_end != null && _end!.isBefore(d)) _end = null;
                          }),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.endDate),
                          value: _end != null,
                          onChanged:
                              (enabled) => setState(
                                () =>
                                    _end =
                                        enabled
                                            ? (_start.isAfter(
                                                  DateUtils.dateOnly(
                                                    DateTime.now(),
                                                  ),
                                                )
                                                ? _start
                                                : DateUtils.dateOnly(
                                                  DateTime.now(),
                                                ))
                                            : null,
                              ),
                        ),
                        if (_end != null)
                          _dateTile(
                            context,
                            l10n.endDate,
                            _end!,
                            (d) => setState(() => _end = d),
                          ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _notes,
                          maxLines: 3,
                          maxLength: 1000,
                          decoration: _decoration(
                            context,
                            l10n.notes,
                            icon: Icons.notes_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _section(
                  context,
                  l10n.reminderSchedule,
                  Icons.notifications_active_outlined,
                ),
                const SizedBox(height: 12),
                if (_schedules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'لن يتم ضبط تذكير بوقت محدد لهذا الدواء.'
                          : 'No scheduled reminder will be set for this medication.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ..._schedules.asMap().entries.map(
                  (entry) => _scheduleCard(context, entry.key, entry.value),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed:
                        () => setState(() => _schedules.add(_ScheduleDraft())),
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(l10n.addReminderTime),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.medicationColor,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.noColor),
                      selected: _color == null,
                      onSelected: (_) => setState(() => _color = null),
                    ),
                    ..._colors.map(
                      (color) => ChoiceChip(
                        label: const SizedBox(width: 18, height: 18),
                        avatar: CircleAvatar(backgroundColor: Color(color)),
                        selected: _color == color,
                        onSelected: (_) => setState(() => _color = color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon:
                      _saving
                          ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.check_rounded),
                  label: Text(l10n.saveMedication),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasPhoto =>
      _pendingPhoto != null ||
      (!_removeSavedPhoto && widget.medication?.imagePath != null);

  Future<void> _selectPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: Text(l10n.takeMedicationPhoto),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.choosePhotoFromGallery),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
    if (source == null || !mounted) return;
    setState(() => _photoBusy = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 84,
      );
      if (image != null && mounted) {
        setState(() {
          _pendingPhoto = image;
          _removeSavedPhoto = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.medicationPhotoError)));
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Widget _scheduleCard(BuildContext context, int index, _ScheduleDraft draft) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.scheduleTime} ${index + 1}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_schedules.length > 1 || _allowNoSchedule)
                  IconButton(
                    tooltip: l10n.removeReminderTime,
                    onPressed:
                        () => setState(() {
                          _schedules.removeAt(index).dispose();
                        }),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final chosen = await showTimePicker(
                  context: context,
                  initialTime: draft.time,
                );
                if (chosen != null && mounted) {
                  setState(() => draft.time = chosen);
                }
              },
              icon: const Icon(Icons.schedule_rounded),
              label: Text(draft.time.format(context)),
            ),
            const SizedBox(height: 8),
            SegmentedButton<MedicationScheduleType>(
              segments: [
                ButtonSegment(
                  value: MedicationScheduleType.daily,
                  label: Text(l10n.everyDay),
                ),
                ButtonSegment(
                  value: MedicationScheduleType.specificDays,
                  label: Text(l10n.specificDays),
                ),
              ],
              selected: {draft.type},
              onSelectionChanged:
                  (value) => setState(() {
                    draft.type = value.first;
                    if (draft.type == MedicationScheduleType.daily) {
                      draft.days.clear();
                    }
                  }),
            ),
            if (draft.type == MedicationScheduleType.specificDays) ...[
              const SizedBox(height: 10),
              Text(l10n.selectDays),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final selected = draft.days.contains(day);
                  return FilterChip(
                    label: Text(_dayLabel(l10n, day)),
                    selected: selected,
                    onSelected:
                        (yes) => setState(() {
                          yes ? draft.days.add(day) : draft.days.remove(day);
                        }),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    final schedules =
        _schedules
            .map(
              (row) => MedicationSchedule(
                type: row.type,
                timeOfDay:
                    '${row.time.hour.toString().padLeft(2, '0')}:${row.time.minute.toString().padLeft(2, '0')}',
                weekdays: row.days,
              ),
            )
            .toList();
    String? newImagePath;
    final oldImagePath = widget.medication?.imagePath;
    try {
      var imagePath = oldImagePath;
      if (_removeSavedPhoto) imagePath = null;
      if (_pendingPhoto != null) {
        newImagePath = await ref
            .read(medicationImageStorageProvider)
            .savePickedImage(_pendingPhoto!);
        imagePath = newImagePath;
      }
      final medication = Medication(
        id: widget.medication?.id,
        name: _name.text.trim(),
        dosageAmount: _amount.text.trim(),
        dosageUnit: _unit == 'custom' ? _customUnit.text.trim() : _unit,
        form:
            _form.isEmpty
                ? null
                : (_form == 'other' ? _customForm.text.trim() : _form),
        startDate: _start,
        endDate: _end,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        indication: widget.medication?.indication ?? widget.indication,
        imagePath: imagePath,
        colorValue: _color,
        recipientId: widget.medication?.recipientId ?? widget.recipientId,
        isActive: widget.medication?.isActive ?? true,
        schedules: schedules,
      );
      await ref.read(medicationsProvider.notifier).save(medication);
      if (oldImagePath != imagePath) {
        try {
          await ref
              .read(medicationImageStorageProvider)
              .deleteIfUnreferenced(oldImagePath);
        } catch (_) {
          // An unused private image can be cleaned up later; don't undo a save.
        }
      }
      final now = DateTime.now();
      ref.invalidate(
        dosesForDateProvider(DateTime(now.year, now.month, now.day)),
      );
      if (!mounted) return;
      var notificationsAllowed = true;
      var exactAlarmsAllowed = true;
      try {
        final notifications = ref.read(notificationServiceProvider);
        if (!await notifications.notificationsEnabled()) {
          await notifications.requestNotificationsPermission();
        }
        notificationsAllowed = await notifications.notificationsEnabled();
        if (notificationsAllowed && !await notifications.canScheduleExact()) {
          await notifications.requestExactAlarmPermission();
        }
        await ref.read(notificationSchedulerProvider).reconcile();
        exactAlarmsAllowed = await notifications.canScheduleExact();
      } catch (_) {
        notificationsAllowed = false;
      }
      if (!mounted) return;
      final permissionAction = !notificationsAllowed || !exactAlarmsAllowed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !notificationsAllowed
                ? l10n.notificationsBlocked
                : !exactAlarmsAllowed
                ? l10n.exactAlarmsBlocked
                : widget.medication == null
                ? l10n.medicationSaved
                : l10n.medicationUpdated,
          ),
          action:
              permissionAction && !widget.onboardingMode
                  ? SnackBarAction(
                    label:
                        notificationsAllowed
                            ? l10n.openExactAlarmSettings
                            : l10n.allowNotifications,
                    onPressed: () => context.go('/settings'),
                  )
                  : null,
        ),
      );
      if (widget.onboardingMode) {
        Navigator.of(context).pop(true);
      } else {
        context.pop();
      }
    } on MedicationValidationException catch (e) {
      if (newImagePath != null) {
        try {
          await ref
              .read(medicationImageStorageProvider)
              .deleteIfUnreferenced(newImagePath);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_validationMessage(l10n, e.messageKey))),
        );
      }
    } catch (_) {
      if (newImagePath != null) {
        try {
          await ref
              .read(medicationImageStorageProvider)
              .deleteIfUnreferenced(newImagePath);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _pendingPhoto != null || _removeSavedPhoto
                  ? l10n.medicationPhotoError
                  : l10n.medicationLoadError,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _validationMessage(AppLocalizations l, String key) => switch (key) {
    'invalidMedicationName' => l.invalidMedicationName,
    'invalidDosageAmount' => l.invalidDosageAmount,
    'invalidDosageUnit' => l.invalidDosageUnit,
    'invalidMedicationDates' => l.invalidMedicationDates,
    'notesTooLong' => l.notesTooLong,
    'atLeastOneReminder' => l.atLeastOneReminder,
    'invalidOrDuplicateTime' => l.invalidOrDuplicateTime,
    'invalidDailyDays' => l.invalidDailyDays,
    'selectAtLeastOneDay' => l.selectAtLeastOneDay,
    _ => l.invalidOrDuplicateTime,
  };

  Widget _dateTile(
    BuildContext context,
    String title,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(
      DateFormat.yMMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(value),
    ),
    trailing: const Icon(Icons.calendar_month_outlined),
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: value,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) onChanged(DateUtils.dateOnly(date));
    },
  );
  InputDecoration _decoration(
    BuildContext context,
    String label, {
    IconData? icon,
  }) => InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon),
  );
  Widget _section(BuildContext context, String title, IconData icon) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
    ],
  );
  String _unitLabel(AppLocalizations l, String value) => switch (value) {
    'mg' => 'mg',
    'ml' => 'ml',
    'tablet' => l.formTablet,
    'capsule' => l.formCapsule,
    'drops' => l.formDrops,
    _ => l.customUnit,
  };
  String _formLabel(AppLocalizations l, String value) => switch (value) {
    'tablet' => l.formTablet,
    'capsule' => l.formCapsule,
    'syrup' => l.formSyrup,
    'injection' => l.formInjection,
    'drops' => l.formDrops,
    'cream' => l.formCream,
    _ => l.formOther,
  };
  String _dayLabel(AppLocalizations l, int day) => switch (day) {
    1 => l.monday,
    2 => l.tuesday,
    3 => l.wednesday,
    4 => l.thursday,
    5 => l.friday,
    6 => l.saturday,
    _ => l.sunday,
  };
}

class _ScheduleDraft {
  _ScheduleDraft({
    this.type = MedicationScheduleType.daily,
    TimeOfDay? time,
    Set<int>? days,
  }) : time = time ?? const TimeOfDay(hour: 8, minute: 0),
       days = {...?days};
  factory _ScheduleDraft.fromSchedule(MedicationSchedule schedule) =>
      _ScheduleDraft(
        type: schedule.type,
        time: TimeOfDay(
          hour: int.parse(schedule.timeOfDay.substring(0, 2)),
          minute: int.parse(schedule.timeOfDay.substring(3)),
        ),
        days: schedule.weekdays,
      );
  MedicationScheduleType type;
  TimeOfDay time;
  final Set<int> days;
  void dispose() {}
}
