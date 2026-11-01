import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

const measurementsStorageKey = 'dawaei.health.measurements.v1';
const _recipientsStorageKey = 'dawaei.health.recipients.v1';

class _MeasurementOption {
  const _MeasurementOption(this.id, this.en, this.ar, this.unit);
  final String id;
  final String en;
  final String ar;
  final String unit;

  String label(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;
  String get searchable => '$en $ar'.toLowerCase();
}

const _commonMeasurements = <_MeasurementOption>[
  _MeasurementOption('bloodPressure', 'Blood Pressure', 'ضغط الدم', 'mmHg'),
  _MeasurementOption(
    'restingHeartRate',
    'Resting Heart Rate',
    'معدل ضربات القلب عند الراحة',
    'bpm',
  ),
  _MeasurementOption('weight', 'Weight', 'الوزن', 'kg'),
  _MeasurementOption(
    'glucoseBeforeMeal',
    'Blood Glucose (Before Meal)',
    'سكر الدم (قبل الوجبة)',
    'mg/dL',
  ),
  _MeasurementOption(
    'glucoseAfterMeal',
    'Blood Glucose (After Meal)',
    'نسبة السكر في الدم (بعد الوجبة)',
    'mg/dL',
  ),
  _MeasurementOption(
    'bodyTemperature',
    'Body Temperature',
    'درجة الحرارة',
    '°C',
  ),
];

const _otherMeasurements = <_MeasurementOption>[
  _MeasurementOption(
    'apoB',
    'Apolipoprotein B (Apo B)',
    'Apolipoprotein B (Apo B)',
    'mg/dL',
  ),
  _MeasurementOption(
    'asat',
    'Aspartate Aminotransferase (ASAT)',
    'الأسبارتات (ASAT)',
    'U/L',
  ),
  _MeasurementOption(
    'alat',
    'Alanine Aminotransferase (ALAT)',
    'ألانين أمينوترانسفيراز (ALAT)',
    'U/L',
  ),
  _MeasurementOption('height', 'Height', 'الطول', 'cm'),
  _MeasurementOption(
    'bmi',
    'Body Mass Index (BMI)',
    'مؤشر كتلة الجسم',
    'kg/m²',
  ),
  _MeasurementOption(
    'oxygenSaturation',
    'Oxygen Saturation',
    'نسبة الأكسجين في الدم',
    '%',
  ),
  _MeasurementOption(
    'waistCircumference',
    'Waist Circumference',
    'محيط الخصر',
    'cm',
  ),
  _MeasurementOption(
    'cholesterol',
    'Total Cholesterol',
    'الكوليسترول الكلي',
    'mg/dL',
  ),
  _MeasurementOption('sleepDuration', 'Sleep Duration', 'مدة النوم', 'h'),
];

/// Searchable measurement picker. Returns true only after a reading is saved.
class MeasurementsSetupScreen extends StatefulWidget {
  const MeasurementsSetupScreen({super.key});

  @override
  State<MeasurementsSetupScreen> createState() =>
      _MeasurementsSetupScreenState();
}

class _MeasurementsSetupScreenState extends State<MeasurementsSetupScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(
      () => setState(() => _query = _search.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _select(_MeasurementOption item) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _MeasurementRecipientScreen(measurement: item),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  List<_MeasurementOption> _filtered(Iterable<_MeasurementOption> source) =>
      source.where((item) => item.searchable.contains(_query)).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final common = _filtered(_commonMeasurements);
    final other = _filtered(_otherMeasurements);
    final noResults = common.isEmpty && other.isEmpty;
    return Scaffold(
      backgroundColor: AppColors.pageBackground(Theme.of(context).brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.appBarGradientFor(Theme.of(context).brightness),
          ),
        ),
        title: Text(l10n.measurementsTitle),
        leading: BackButton(onPressed: () => Navigator.of(context).pop(false)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.measurementSearch,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          tooltip:
                              MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                          onPressed: _search.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                noResults
                    ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          l10n.measurementNoResults,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                    : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        if (common.isNotEmpty) ...[
                          _SectionLabel(l10n.commonMeasurements),
                          ...common.map(
                            (item) => _MeasurementRow(
                              item: item,
                              onTap: () => _select(item),
                            ),
                          ),
                        ],
                        if (other.isNotEmpty) ...[
                          if (common.isNotEmpty)
                            Divider(
                              height: 28,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF393939)
                                  : Theme.of(context).colorScheme.outlineVariant,
                            ),
                          _SectionLabel(l10n.allMeasurements),
                          ...other.map(
                            (item) => _MeasurementRow(
                              item: item,
                              onTap: () => _select(item),
                            ),
                          ),
                        ],
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      text,
      textAlign: TextAlign.end,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
    ),
  );
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.item, required this.onTap});
  final _MeasurementOption item;
  final VoidCallback onTap;

  IconData get _icon => switch (item.id) {
    'bloodPressure' => Icons.monitor_heart_outlined,
    'restingHeartRate' => Icons.favorite_border_rounded,
    'weight' => Icons.monitor_weight_outlined,
    'glucoseBeforeMeal' || 'glucoseAfterMeal' => Icons.water_drop_outlined,
    'bodyTemperature' => Icons.device_thermostat_rounded,
    _ => Icons.health_and_safety_outlined,
  };

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            _icon,
            color: AppColors.accentFor(Theme.of(context).brightness),
          ),
        ),
        title: Text(
          item.label(context),
          textAlign: TextAlign.end,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          item.unit,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chevron_left_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
      Divider(
        height: 1,
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .3),
      ),
    ],
  );
}

class _MeasurementRecipientScreen extends StatefulWidget {
  const _MeasurementRecipientScreen({required this.measurement});
  final _MeasurementOption measurement;

  @override
  State<_MeasurementRecipientScreen> createState() =>
      _MeasurementRecipientScreenState();
}

class _MeasurementRecipientScreenState
    extends State<_MeasurementRecipientScreen> {
  List<String> _recipients = [];
  String? _selectedRecipient = 'self';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    try {
      final values =
          await SharedPreferencesAsync().getStringList(_recipientsStorageKey) ??
          [];
      if (!mounted) return;
      setState(() {
        _recipients = values;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addRecipient() async {
    final l10n = AppLocalizations.of(context);
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const _MeasurementRecipientFormScreen(),
      ),
    );
    if (name == null || !mounted) return;
    String? existing;
    for (final recipient in _recipients) {
      if (recipient.toLowerCase() == name.toLowerCase()) {
        existing = recipient;
        break;
      }
    }
    final selectedName = existing ?? name;
    final updated =
        existing == null ? [..._recipients, selectedName] : _recipients;
    try {
      if (existing == null) {
        await SharedPreferencesAsync().setStringList(
          _recipientsStorageKey,
          updated,
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.settingsSaveError)));
      return;
    }
    if (!mounted) return;
    setState(() {
      _recipients = updated;
      _selectedRecipient = selectedName;
    });
  }

  Future<void> _continue() async {
    if (_selectedRecipient == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => _MeasurementEntryScreen(
              measurement: widget.measurement,
              recipient: _selectedRecipient!,
            ),
      ),
    );
    if (saved == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBackground(Theme.of(context).brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.appBarGradientFor(Theme.of(context).brightness),
          ),
        ),
        leading: BackButton(onPressed: () => Navigator.of(context).pop(false)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 18, bottom: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                    child: Text(
                      widget.measurement.label(context),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 19,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                    child: Text(
                      l10n.measurementRecipientQuestion,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _RecipientTile(
                    title: l10n.measurementSelf,
                    selected: _selectedRecipient == 'self',
                    leading: const SizedBox.shrink(),
                    onTap: () => setState(() => _selectedRecipient = 'self'),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ..._recipients.map(
                      (name) => _RecipientTile(
                        title: name,
                        selected: _selectedRecipient == name,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.brand.withValues(
                            alpha: .16,
                          ),
                          child: Text(
                            name.isEmpty
                                ? '?'
                                : name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        onTap: () => setState(() => _selectedRecipient = name),
                      ),
                    ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: _addRecipient,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.measurementAddRecipient),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentFor(
                        Theme.of(context).brightness,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: _MeasurementsActionButton(
                label: l10n.measurementContinue,
                onPressed: _selectedRecipient == null ? null : _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementRecipientFormScreen extends StatefulWidget {
  const _MeasurementRecipientFormScreen();

  @override
  State<_MeasurementRecipientFormScreen> createState() =>
      _MeasurementRecipientFormScreenState();
}

class _MeasurementRecipientFormScreenState
    extends State<_MeasurementRecipientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.pageBackground(Theme.of(context).brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.appBarGradientFor(Theme.of(context).brightness),
          ),
        ),
        title: Text(l10n.measurementAddRecipient),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.measurementAddRecipient,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'أنشئ ملفًا لتسجيل القياسات لهذا الشخص.'
                            : 'Create a profile to record measurements for this person.',
                        textAlign: TextAlign.end,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: _name,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        decoration: InputDecoration(
                          labelText: l10n.measurementRecipientName,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          filled: true,
                          fillColor: colors.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: colors.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: AppColors.brand,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty || name.length > 80) {
                            return Localizations.localeOf(
                                      context,
                                    ).languageCode ==
                                    'ar'
                                ? 'أدخل اسمًا صحيحًا.'
                                : 'Enter a valid name.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(onPressed: _save, child: Text(l10n.done)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.title,
    required this.selected,
    required this.leading,
    required this.onTap,
  });
  final String title;
  final bool selected;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              if (leading is! SizedBox) ...[leading, const SizedBox(width: 12)],
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              if (selected)
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.accentFor(
                    Theme.of(context).brightness,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBackground
                        : Colors.white,
                    size: 21,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _MeasurementEntryScreen extends StatefulWidget {
  const _MeasurementEntryScreen({
    required this.measurement,
    required this.recipient,
  });
  final _MeasurementOption measurement;
  final String recipient;

  @override
  State<_MeasurementEntryScreen> createState() =>
      _MeasurementEntryScreenState();
}

class _MeasurementEntryScreenState extends State<_MeasurementEntryScreen> {
  late final TextEditingController _value;
  late final TextEditingController _unit;
  late final TextEditingController _systolic;
  late final TextEditingController _diastolic;
  late final TextEditingController _pulse;
  late final FocusNode _systolicFocus;
  late final FocusNode _diastolicFocus;
  late final FocusNode _pulseFocus;
  bool _saving = false;

  bool get _isBloodPressure => widget.measurement.id == 'bloodPressure';

  @override
  void initState() {
    super.initState();
    _value = TextEditingController();
    _unit = TextEditingController(text: widget.measurement.unit);
    _systolic = TextEditingController();
    _diastolic = TextEditingController();
    _pulse = TextEditingController();
    _systolicFocus = FocusNode(debugLabel: 'blood-pressure-systolic');
    _diastolicFocus = FocusNode(debugLabel: 'blood-pressure-diastolic');
    _pulseFocus = FocusNode(debugLabel: 'blood-pressure-pulse');
  }

  @override
  void dispose() {
    _value.dispose();
    _unit.dispose();
    _systolic.dispose();
    _diastolic.dispose();
    _pulse.dispose();
    _systolicFocus.dispose();
    _diastolicFocus.dispose();
    _pulseFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value =
        _isBloodPressure
            ? '${_systolic.text.trim()}/${_diastolic.text.trim()}'
            : _value.text.trim();
    final unit = _unit.text.trim();
    final entered =
        _isBloodPressure ? [_systolic.text, _diastolic.text] : [_value.text];
    final validNumbers = entered.every((raw) {
      final number = double.tryParse(raw.trim());
      return number != null && number > 0 && number < 100000;
    });
    if (!validNumbers || unit.isEmpty || _saving) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).measurementValue)),
      );
      return;
    }
    final pulse = _pulse.text.trim();
    final pulseNumber = double.tryParse(pulse);
    if (_isBloodPressure &&
        pulse.isNotEmpty &&
        (pulseNumber == null ||
            !pulseNumber.isFinite ||
            pulseNumber <= 0 ||
            pulseNumber >= 100000)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).measurementValue)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final preferences = SharedPreferencesAsync();
      final records =
          await preferences.getStringList(measurementsStorageKey) ?? [];
      final record = <String, dynamic>{
        'type': widget.measurement.id,
        'nameEn': widget.measurement.en,
        'nameAr': widget.measurement.ar,
        'value': value,
        'unit': unit,
        'recipient': widget.recipient,
        'savedAt': DateTime.now().toIso8601String(),
      };
      if (_isBloodPressure && pulse.isNotEmpty) record['pulse'] = pulse;
      records.add(jsonEncode(record));
      await preferences.setStringList(measurementsStorageKey, records);
      if (mounted) Navigator.of(context).pop(true);
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
    return Scaffold(
      backgroundColor: AppColors.pageBackground(Theme.of(context).brightness),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.appBarGradientFor(Theme.of(context).brightness),
          ),
        ),
        leading: BackButton(onPressed: () => Navigator.of(context).pop(false)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.measurement.label(context),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.measurementEntryBody,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_isBloodPressure) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(
                              _systolic,
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'الانقباضي'
                                  : 'Systolic',
                              focusNode: _systolicFocus,
                              textInputAction: TextInputAction.next,
                              onSubmitted:
                                  (_) => _diastolicFocus.requestFocus(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _numberField(
                              _diastolic,
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'الانبساطي'
                                  : 'Diastolic',
                              focusNode: _diastolicFocus,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) => _pulseFocus.requestFocus(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _numberField(
                        _pulse,
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'النبض (اختياري)'
                            : 'Pulse (optional)',
                        focusNode: _pulseFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                    ] else
                      _numberField(_value, l10n.measurementValue),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _unit,
                      textAlign: TextAlign.end,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        labelText: l10n.measurementUnit,
                        filled: true,
                        fillColor:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.brand,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: _MeasurementsActionButton(
                label: _saving ? l10n.loading : l10n.measurementAdd,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) => TextField(
    controller: controller,
    focusNode: focusNode,
    textInputAction: textInputAction,
    onSubmitted: onSubmitted,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textAlign: TextAlign.center,
    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    cursorColor: AppColors.brand,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.brand, width: 2),
      ),
    ),
  );
}

class _MeasurementsActionButton extends StatelessWidget {
  const _MeasurementsActionButton({
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: FilledButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
