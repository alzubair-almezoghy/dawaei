import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'medication_form_screen.dart';

class MedicationReasonScreen extends StatefulWidget {
  const MedicationReasonScreen({
    required this.recipientId,
    required this.recipientName,
    required this.initialScheduleCount,
    required this.allowNoSchedule,
    super.key,
  });

  final int? recipientId;
  final String? recipientName;
  final int initialScheduleCount;
  final bool allowNoSchedule;

  @override
  State<MedicationReasonScreen> createState() => _MedicationReasonScreenState();
}

class _MedicationReasonScreenState extends State<MedicationReasonScreen> {
  String? _indication;
  bool _opening = false;
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _chooseIndication() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _IndicationSearchScreen()),
    );
    if (value != null && mounted) setState(() => _indication = value);
  }

  Future<void> _continue({bool skip = false}) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder:
              (_) => MedicationFormScreen(
                onboardingMode: true,
                recipientId: widget.recipientId,
                recipientName: widget.recipientName,
                initialScheduleCount: widget.initialScheduleCount,
                allowNoSchedule: widget.allowNoSchedule,
                indication: skip ? null : _indication,
              ),
        ),
      );
      if (saved == true && mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark
        ? AppColors.success(Brightness.dark)
        : AppColors.brand;
    final primaryText = dark ? Colors.white : const Color(0xFF18333F);
    final secondaryText = dark
        ? AppColors.secondaryText
        : const Color(0xFF617681);
    final surface = dark ? const Color(0xFF10384B) : const Color(0xFFF4F8FA);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: dark ? AppColors.darkBackground : Colors.white,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [
                    Color(0xFF071F2D),
                    Color(0xFF0B3448),
                    Color(0xFF071F2D),
                  ]
                : const [Colors.white, Color(0xFFF1F8FB), Colors.white],
            stops: [0, .52, 1],
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: 115,
              end: -92,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand.withValues(alpha: dark ? .08 : .06),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 16, top: 4),
                child: TextButton.icon(
                  onPressed: () => _continue(skip: true),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(_ar ? '\u062a\u062e\u0637\u064a' : 'Skip'),
                  style: TextButton.styleFrom(
                    foregroundColor: secondaryText,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: dark
                                ? const [Color(0xFF1D7691), Color(0xFF10445B)]
                                : const [Color(0xFFDDF2F6), Color(0xFFBFE4EC)],
                          ),
                          border: Border.all(
                            color: accent.withValues(alpha: dark ? .35 : .22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: .18),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.medical_information_outlined,
                          color: accent,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _ar ? '\u062f\u0648\u0627\u0621 \u062c\u062f\u064a\u062f' : 'NEW MEDICATION',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: _ar ? 0 : 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _ar
                          ? '\u0644\u0645\u0627\u0630\u0627 \u062a\u0623\u062e\u0630 \u0647\u0630\u0627\u061f'
                          : 'Why are you taking this?',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _ar
                          ? '\u0633\u062a\u0633\u0627\u0639\u062f\u0646\u0627 \u0647\u0630\u0647 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062a \u0641\u064a \u0645\u0633\u0627\u0639\u062f\u062a\u0643 \u0628\u0634\u0643\u0644 \u0623\u0641\u0636\u0644.'
                          : 'This information helps us support you better.',
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: secondaryText,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 26),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _indication == null
                              ? (dark
                                  ? Colors.white.withValues(alpha: .09)
                                  : const Color(0xFFD4E3E8))
                              : accent.withValues(alpha: .72),
                          width: _indication == null ? 1 : 1.4,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _chooseIndication,
                          borderRadius: BorderRadius.circular(22),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              18, 18, 18, 18,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: .14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _indication == null
                                        ? Icons.add_rounded
                                        : Icons.check_rounded,
                                    color: accent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _ar
                                            ? '\u0627\u0644\u062d\u0627\u0644\u0629 \u0627\u0644\u0645\u0631\u0636\u064a\u0629'
                                            : 'Medical condition',
                                        textAlign: TextAlign.end,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                    color: primaryText,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _indication ??
                                            (_ar
                                                ? '\u0627\u062e\u062a\u0631 \u0623\u0648 \u0627\u0628\u062d\u062b \u0639\u0646 \u062d\u0627\u0644\u062a\u0643'
                                                : 'Choose or search for a condition'),
                                        textAlign: TextAlign.end,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color: _indication == null
                                              ? secondaryText
                                              : accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Icon(
                                  Icons.medical_information_outlined,
                                  color: accent,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      onPressed: _indication == null || _opening ? null : _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: dark
                            ? const Color(0xFFF7FBFA)
                            : AppColors.brand,
                        foregroundColor: dark
                            ? const Color(0xFF0E5660)
                            : Colors.white,
                        disabledBackgroundColor: dark
                            ? const Color(0xFF374249)
                            : const Color(0xFFE3EAED),
                        disabledForegroundColor: dark
                            ? Colors.white38
                            : const Color(0xFF8A9BA2),
                        shape: const StadiumBorder(),
                        elevation: _indication == null ? 0 : 2,
                      ),
                      child: _opening
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _ar ? '\u0625\u0636\u0627\u0641\u0629' : 'Add',
                              style: const TextStyle(fontSize: 17),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: .72,
                      minHeight: 4,
                      backgroundColor: dark
                          ? Colors.white12
                          : const Color(0xFFDCE9ED),
                      valueColor: AlwaysStoppedAnimation(
                        dark ? const Color(0xFF8AF0CB) : AppColors.brand,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_opening) Text(l10n.onboardingNext),
                ],
              ),
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndicationSearchScreen extends StatefulWidget {
  const _IndicationSearchScreen();

  @override
  State<_IndicationSearchScreen> createState() => _IndicationSearchScreenState();
}

class _IndicationSearchScreenState extends State<_IndicationSearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';

  List<_Condition> get _conditions => const [
    _Condition('السكري من النوع الأول', 'Type 1 diabetes', 'التمثيل الغذائي', 'Metabolic'),
    _Condition('السكري من النوع الثاني', 'Type 2 diabetes', 'التمثيل الغذائي', 'Metabolic'),
    _Condition('ارتفاع ضغط الدم', 'High blood pressure', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('ارتفاع الكوليسترول والدهون', 'High cholesterol and lipids', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('أمراض القلب التاجية', 'Coronary artery disease', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('قصور القلب', 'Heart failure', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('اضطراب نظم القلب', 'Heart rhythm disorder', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('الرجفان الأذيني', 'Atrial fibrillation', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('الذبحة الصدرية', 'Angina', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('السكتة الدماغية', 'Stroke', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('جلطات الأوردة العميقة', 'Deep vein thrombosis', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('الدوالي', 'Varicose veins', 'القلب والدورة الدموية', 'Heart and circulation'),
    _Condition('الربو', 'Asthma', 'التنفس والحساسية', 'Breathing and allergies'),
    _Condition('مرض الانسداد الرئوي المزمن', 'Chronic obstructive pulmonary disease', 'التنفس والحساسية', 'Breathing and allergies'),
    _Condition('حساسية الأنف', 'Allergic rhinitis', 'التنفس والحساسية', 'Breathing and allergies'),
    _Condition('التهاب الجيوب الأنفية', 'Sinusitis', 'التنفس والحساسية', 'Breathing and allergies'),
    _Condition('انقطاع النفس أثناء النوم', 'Sleep apnea', 'التنفس والحساسية', 'Breathing and allergies'),
    _Condition('الارتجاع المعدي المريئي', 'Gastroesophageal reflux disease', 'الجهاز الهضمي والكبد', 'Digestive system and liver'),
    _Condition('قرحة المعدة', 'Stomach ulcer', 'الجهاز الهضمي والكبد', 'Digestive system and liver'),
    _Condition('القولون العصبي', 'Irritable bowel syndrome', 'الجهاز الهضمي والكبد', 'Digestive system and liver'),
    _Condition('داء كرون', 'Crohn disease', 'الجهاز الهضمي والكبد', 'Digestive system and liver'),
    _Condition('التهاب القولون التقرحي', 'Ulcerative colitis', 'الجهاز الهضمي والكبد', 'Digestive system and liver'),
    _Condition('الكبد الدهني', 'Fatty liver disease', 'الجهاز الهضمي والكبد', 'Digestive system and liver'),
    _Condition('التهاب الكبد', 'Hepatitis', 'الجهاز الهضمي والكبد', 'Digestive system and liver'),
    _Condition('أمراض الكلى المزمنة', 'Chronic kidney disease', 'الكلى والمسالك البولية', 'Kidneys and urinary tract'),
    _Condition('حصى الكلى', 'Kidney stones', 'الكلى والمسالك البولية', 'Kidneys and urinary tract'),
    _Condition('التهاب المسالك البولية المتكرر', 'Recurrent urinary tract infection', 'الكلى والمسالك البولية', 'Kidneys and urinary tract'),
    _Condition('تضخم البروستاتا الحميد', 'Benign prostate enlargement', 'الكلى والمسالك البولية', 'Kidneys and urinary tract'),
    _Condition('قصور الغدة الدرقية', 'Hypothyroidism', 'الغدد والهرمونات', 'Hormones and glands'),
    _Condition('فرط نشاط الغدة الدرقية', 'Hyperthyroidism', 'الغدد والهرمونات', 'Hormones and glands'),
    _Condition('تكيس المبايض', 'Polycystic ovary syndrome', 'الغدد والهرمونات', 'Hormones and glands'),
    _Condition('بطانة الرحم المهاجرة', 'Endometriosis', 'الغدد والهرمونات', 'Hormones and glands'),
    _Condition('النقرس', 'Gout', 'العظام والمفاصل', 'Bones and joints'),
    _Condition('هشاشة العظام', 'Osteoporosis', 'العظام والمفاصل', 'Bones and joints'),
    _Condition('خشونة المفاصل', 'Osteoarthritis', 'العظام والمفاصل', 'Bones and joints'),
    _Condition('التهاب المفاصل الروماتويدي', 'Rheumatoid arthritis', 'العظام والمفاصل', 'Bones and joints'),
    _Condition('آلام الظهر المزمنة', 'Chronic back pain', 'العظام والمفاصل', 'Bones and joints'),
    _Condition('الألم العضلي الليفي', 'Fibromyalgia', 'العظام والمفاصل', 'Bones and joints'),
    _Condition('الصداع النصفي', 'Migraine', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('الصرع', 'Epilepsy', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('مرض باركنسون', 'Parkinson disease', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('التصلب المتعدد', 'Multiple sclerosis', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('الاعتلال العصبي', 'Neuropathy', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('الاكتئاب', 'Depression', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('اضطراب القلق', 'Anxiety disorder', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('اضطراب فرط الحركة وتشتت الانتباه', 'ADHD', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('الأرق المزمن', 'Chronic insomnia', 'الأعصاب والصحة النفسية', 'Neurology and mental health'),
    _Condition('فقر الدم', 'Anemia', 'الدم والمناعة', 'Blood and immune system'),
    _Condition('نقص الحديد', 'Iron deficiency', 'الدم والمناعة', 'Blood and immune system'),
    _Condition('اضطرابات تخثر الدم', 'Blood clotting disorder', 'الدم والمناعة', 'Blood and immune system'),
    _Condition('الذئبة الحمراء', 'Lupus', 'الدم والمناعة', 'Blood and immune system'),
    _Condition('الصدفية', 'Psoriasis', 'الجلد', 'Skin'),
    _Condition('الأكزيما', 'Eczema', 'الجلد', 'Skin'),
    _Condition('حب الشباب', 'Acne', 'الجلد', 'Skin'),
    _Condition('قرحة الساق', 'Leg ulcer', 'الجلد', 'Skin'),
    _Condition('الساركويد', 'Sarcoidosis', 'الجلد', 'Skin'),
    _Condition('السكري الحملي', 'Gestational diabetes', 'الحمل وصحة المرأة', 'Pregnancy and women’s health'),
    _Condition('ارتفاع ضغط الدم أثناء الحمل', 'High blood pressure during pregnancy', 'الحمل وصحة المرأة', 'Pregnancy and women’s health'),
    _Condition('تضخم البروستاتا', 'Enlarged prostate', 'صحة الرجل', 'Men’s health'),
    _Condition('ضعف الانتصاب', 'Erectile dysfunction', 'صحة الرجل', 'Men’s health'),
    _Condition('السل', 'Tuberculosis', 'العدوى', 'Infections'),
    _Condition('السل الجلدي', 'Cutaneous tuberculosis', 'العدوى', 'Infections'),
    _Condition('فيروس نقص المناعة البشرية', 'HIV', 'العدوى', 'Infections'),
    _Condition('السيلان', 'Gonorrhea', 'العدوى', 'Infections'),
    _Condition('الزهري', 'Syphilis', 'العدوى', 'Infections'),
    _Condition('الهربس', 'Herpes', 'العدوى', 'Infections'),
    _Condition('العدوى الفطرية المتكررة', 'Recurrent fungal infection', 'العدوى', 'Infections'),
    _Condition('السرطان', 'Cancer', 'حالات أخرى', 'Other conditions'),
    _Condition('السمنة', 'Obesity', 'حالات أخرى', 'Other conditions'),
    _Condition('نقص فيتامين د', 'Vitamin D deficiency', 'حالات أخرى', 'Other conditions'),
    _Condition('الحساسية الموسمية', 'Seasonal allergy', 'حالات أخرى', 'Other conditions'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark
        ? AppColors.success(Brightness.dark)
        : AppColors.brand;
    final primaryText = dark ? Colors.white : const Color(0xFF18333F);
    final query = _controller.text.trim().toLowerCase();
    final matches = _conditions
        .where((condition) =>
            '${condition.arabic} ${condition.english}'.toLowerCase().contains(query))
        .toList();
    final custom = _controller.text.trim();
    final isKnownCondition = matches.any(
      (condition) =>
          condition.arabic.toLowerCase() == custom.toLowerCase() ||
          condition.english.toLowerCase() == custom.toLowerCase(),
    );
    return Scaffold(
      backgroundColor: dark ? AppColors.darkBackground : Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryText,
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: dark
                ? AppColors.appBarGradient
                : const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.white, Color(0xFFF1F8FB)],
                  ),
          ),
        ),
        toolbarHeight: 66,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          style: IconButton.styleFrom(
            backgroundColor: dark
                ? Colors.white.withValues(alpha: .08)
                : AppColors.brand.withValues(alpha: .08),
          ),
          icon: Icon(Icons.close_rounded, color: primaryText),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          textInputAction: TextInputAction.search,
          cursorColor: accent,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: primaryText,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.of(context).pop(value.trim());
          },
          decoration: InputDecoration(
            hintText: _ar
                ? '\u0627\u0644\u0628\u062d\u062b'
                : 'Search conditions',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              if (custom.isNotEmpty) Navigator.of(context).pop(custom);
            },
            style: IconButton.styleFrom(
            backgroundColor: dark
                ? Colors.white.withValues(alpha: .08)
                : AppColors.brand.withValues(alpha: .08),
            ),
            icon: Icon(
              Icons.arrow_forward_rounded,
            color: accent,
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF071F2D), Color(0xFF0A2D40)]
                : const [Colors.white, Color(0xFFF5FAFC)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsetsDirectional.only(top: 12, bottom: 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
          if (custom.isNotEmpty && !isKnownCondition)
            _conditionTile(
              context,
              custom,
              _ar
                  ? '\u0627\u0646\u0642\u0631 \u0647\u0646\u0627 \u0644\u0644\u0625\u0646\u0634\u0627\u0621 \u0628\u0627\u0633\u0645 \u0645\u062e\u0635\u0635'
                  : 'Use custom condition',
            ),
          if (matches.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 4),
              child: Text(
                _ar
                    ? '\u0627\u0644\u0623\u0645\u0631\u0627\u0636 \u0627\u0644\u0645\u0632\u0645\u0646\u0629 \u0648\u0627\u0644\u0634\u0627\u0626\u0639\u0629'
                    : 'CHRONIC AND COMMON CONDITIONS',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: dark ? Colors.white60 : const Color(0xFF617681),
                ),
              ),
            ),
            ...matches.map((condition) => _conditionTile(
                  context,
                  _ar ? condition.arabic : condition.english,
                  _ar ? condition.categoryArabic : condition.categoryEnglish,
                )),
          ],
        ),
      ),
    );
  }

  Widget _conditionTile(BuildContext context, String value, String? subtitle) =>
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 5, 16, 5),
        child: Material(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF10384B)
              : Colors.white,
          elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 1,
          shadowColor: AppColors.brand.withValues(alpha: .08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: .07)
                  : const Color(0xFFDCE9ED),
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).pop(value),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 13, 16, 13),
              child: Row(
                children: [
                  Icon(
                    Icons.chevron_left_rounded,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.success(Brightness.dark)
                        : AppColors.brand,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF18333F),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.secondaryText
                                      : const Color(0xFF617681),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.brand.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? .17
                            : .09,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 18,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.success(Brightness.dark)
                          : AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Condition {
  const _Condition(
    this.arabic,
    this.english,
    this.categoryArabic,
    this.categoryEnglish,
  );

  final String arabic;
  final String english;
  final String categoryArabic;
  final String categoryEnglish;
}
