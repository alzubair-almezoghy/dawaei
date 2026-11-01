import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'measurements_setup_screen.dart';

/// The permanent home for the same measurement records created during onboarding.
class MeasurementsDashboardScreen extends StatefulWidget {
  const MeasurementsDashboardScreen({super.key});

  @override
  State<MeasurementsDashboardScreen> createState() =>
      _MeasurementsDashboardScreenState();
}

class _MeasurementsDashboardScreenState
    extends State<MeasurementsDashboardScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await SharedPreferencesAsync().getStringList(
        measurementsStorageKey,
      );
      final records = <Map<String, dynamic>>[];
      for (final raw in saved ?? const <String>[]) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            records.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // Ignore malformed legacy entries without affecting valid readings.
        }
      }
      records.sort((a, b) => _date(b).compareTo(_date(a)));
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
        _loadError = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  DateTime _date(Map<String, dynamic> record) =>
      DateTime.tryParse('${record['savedAt'] ?? ''}') ?? DateTime(1970);

  Future<void> _add() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const MeasurementsSetupScreen()),
    );
    if (mounted) _load();
  }

  String _name(BuildContext context, Map<String, dynamic> record) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final stored = record[ar ? 'nameAr' : 'nameEn'];
    if (stored is String && stored.trim().isNotEmpty) return stored;
    return _typeLabel(context, '${record['type'] ?? ''}');
  }

  String _typeLabel(BuildContext context, String type) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return switch (type) {
      'bloodPressure' => ar ? 'ضغط الدم' : 'Blood pressure',
      'glucoseBeforeMeal' =>
        ar ? 'سكر الدم قبل الوجبة' : 'Glucose · before meal',
      'glucoseAfterMeal' => ar ? 'سكر الدم بعد الوجبة' : 'Glucose · after meal',
      'bloodSugar' => ar ? 'سكر الدم' : 'Blood glucose',
      'restingHeartRate' ||
      'heartRate' => ar ? 'معدل ضربات القلب' : 'Heart rate',
      'weight' => ar ? 'الوزن' : 'Weight',
      'bodyTemperature' => ar ? 'درجة الحرارة' : 'Temperature',
      _ => type.isEmpty ? (ar ? 'قياس صحي' : 'Health measurement') : type,
    };
  }

  IconData _icon(String type) => switch (type) {
    'bloodPressure' => Icons.monitor_heart_outlined,
    'glucoseBeforeMeal' ||
    'glucoseAfterMeal' ||
    'bloodSugar' => Icons.water_drop_outlined,
    'restingHeartRate' || 'heartRate' => Icons.favorite_border_rounded,
    'weight' => Icons.monitor_weight_outlined,
    'bodyTemperature' => Icons.device_thermostat_rounded,
    _ => Icons.health_and_safety_outlined,
  };

  List<Map<String, dynamic>> _latestByType() {
    final seen = <String>{};
    return _records.where((r) => seen.add('${r['type'] ?? ''}')).toList();
  }

  String? _trendFor(Map<String, dynamic> current) {
    final matching =
        _records
            .where((r) => '${r['type'] ?? ''}' == '${current['type'] ?? ''}')
            .toList();
    if (matching.length < 2) return null;
    double? number(Map<String, dynamic> item) =>
        double.tryParse('${item['value'] ?? ''}'.split('/').first);
    final newest = number(matching[0]);
    final previous = number(matching[1]);
    if (newest == null || previous == null) return null;
    final delta = newest - previous;
    if (delta == 0) return '• 0';
    return '${delta > 0 ? '↑' : '↓'} ${delta.abs().toStringAsFixed(delta.abs() % 1 == 0 ? 0 : 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final colors = Theme.of(context).colorScheme;
    final latest = _latestByType();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'قياساتك الصحية' : 'Your health measurements',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAr
                            ? 'تابع قراءاتك وسجّل قياسًا جديدًا في أي وقت.'
                            : 'Review your readings and add a new one whenever you need.',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      _PulseBanner(isAr: isAr, count: _records.length),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isAr ? 'أحدث القراءات' : 'Recent readings',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (_records.isNotEmpty)
                            Text(
                              '${_records.length} ${isAr ? 'قراءة' : 'readings'}',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_loadError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isAr
                              ? 'تعذر تحميل القياسات'
                              : 'Could not load measurements',
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _loading = true);
                            _load();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(isAr ? 'إعادة المحاولة' : 'Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (latest.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyMeasurements(isAr: isAr, onAdd: _add),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  sliver: SliverList.separated(
                    itemCount: latest.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = latest[index];
                      return _ReadingTile(
                        title: _name(context, item),
                        value: '${item['value'] ?? '—'}',
                        unit: '${item['unit'] ?? ''}',
                        icon: _icon('${item['type'] ?? ''}'),
                        date: _date(item),
                        isAr: isAr,
                        trend: _trendFor(item),
                        onTap: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder:
                                  (_) => MeasurementDetailsScreen(
                                    type: '${item['type'] ?? ''}',
                                    title: _name(context, item),
                                    icon: _icon('${item['type'] ?? ''}'),
                                  ),
                            ),
                          );
                          if (mounted) _load();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.measurementAdd),
      ),
    );
  }
}

class _PulseBanner extends StatelessWidget {
  const _PulseBanner({required this.isAr, required this.count});
  final bool isAr;
  final int count;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final mint = AppColors.accentFor(brightness);
    return Container(
      height: 132,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: AppColors.pageGradientFor(brightness),
        border: Border.all(color: mint.withValues(alpha: .24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isAr ? 'نبض عنايتك' : 'Your care pulse',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryText(brightness),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  count == 0
                      ? (isAr
                          ? 'ابدأ بتسجيل أول قياس لك'
                          : 'Record your first reading')
                      : (isAr
                          ? 'لديك $count قراءة محفوظة'
                          : '$count saved readings'),
                  style: TextStyle(color: AppColors.mutedText(brightness)),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            height: 72,
            child: CustomPaint(painter: _PulsePainter(mint)),
          ),
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..moveTo(0, size.height * .55);
    path
      ..lineTo(size.width * .22, size.height * .55)
      ..lineTo(size.width * .34, size.height * .39)
      ..lineTo(size.width * .45, size.height * .73)
      ..lineTo(size.width * .58, size.height * .12)
      ..lineTo(size.width * .71, size.height * .67)
      ..lineTo(size.width * .82, size.height * .48)
      ..lineTo(size.width, size.height * .48);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ReadingTile extends StatelessWidget {
  const _ReadingTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.date,
    required this.isAr,
    required this.trend,
    required this.onTap,
  });
  final String title, value, unit;
  final IconData icon;
  final DateTime date;
  final bool isAr;
  final String? trend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final time =
        '${material.formatShortDate(date)} · ${material.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.accentFor(
                    Theme.of(context).brightness,
                  ).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.accentFor(Theme.of(context).brightness),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        if (trend != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            trend!,
                            style: TextStyle(
                              color: AppColors.accentFor(
                                Theme.of(context).brightness,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                child: Text(
                  value,
                  key: ValueKey(value),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(width: 3),
              Icon(
                isAr ? Icons.chevron_left : Icons.chevron_right,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMeasurements extends StatelessWidget {
  const _EmptyMeasurements({required this.isAr, required this.onAdd});
  final bool isAr;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentFor(
                Theme.of(context).brightness,
              ).withValues(alpha: .12),
            ),
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 38,
              color: AppColors.accentFor(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isAr ? 'لا توجد قراءات بعد' : 'No readings yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'سجّل أول قياس لتبدأ متابعة سجلّك الصحي.'
                : 'Add your first measurement to start your personal history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(isAr ? 'إضافة قياس' : 'Add a measurement'),
          ),
        ],
      ),
    ),
  );
}

class MeasurementDetailsScreen extends StatefulWidget {
  const MeasurementDetailsScreen({
    required this.type,
    required this.title,
    required this.icon,
    super.key,
  });
  final String type, title;
  final IconData icon;
  @override
  State<MeasurementDetailsScreen> createState() =>
      _MeasurementDetailsScreenState();
}

class _MeasurementDetailsScreenState extends State<MeasurementDetailsScreen> {
  int _days = 30;
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  bool _loadError = false;
  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values =
          await SharedPreferencesAsync().getStringList(
            measurementsStorageKey,
          ) ??
          [];
      final records = <Map<String, dynamic>>[];
      for (final value in values) {
        try {
          final item = jsonDecode(value);
          if (item is Map && '${item['type']}' == widget.type) {
            records.add(Map<String, dynamic>.from(item));
          }
        } catch (_) {}
      }
      records.sort(
        (a, b) => (DateTime.tryParse('${b['savedAt']}') ?? DateTime(1970))
            .compareTo(DateTime.tryParse('${a['savedAt']}') ?? DateTime(1970)),
      );
      if (mounted) {
        setState(() {
          _records = records;
          _loading = false;
          _loadError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = true;
        });
      }
    }
  }

  DateTime _date(Map<String, dynamic> item) =>
      DateTime.tryParse('${item['savedAt']}') ?? DateTime(1970);
  double? _numeric(Map<String, dynamic> item) {
    final value = '${item['value'] ?? ''}';
    final first = value.split('/').first;
    return double.tryParse(first);
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _records
            .where((r) => DateTime.now().difference(_date(r)).inDays <= _days)
            .toList()
            .reversed
            .toList();
    final values = filtered.map(_numeric).whereType<double>().toList();
    final latest = _records.isEmpty ? null : _records.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: _isAr ? 'إضافة قراءة' : 'Add reading',
            onPressed: () async {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const MeasurementsSetupScreen(),
                ),
              );
              if (mounted) _load();
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _loadError
                ? Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      _isAr
                          ? '�?�?�?�?�? �?�?�?�?�?�?�?'
                          : 'Could not load · retry',
                    ),
                  ),
                )
                : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
                  children: [
                    if (latest != null)
                      _DetailHero(
                        title: widget.title,
                        icon: widget.icon,
                        value: '${latest['value'] ?? '—'}',
                        unit: '${latest['unit'] ?? ''}',
                        date: _date(latest),
                        isAr: _isAr,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _isAr ? 'السجل والاتجاه' : 'History & trend',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment(
                          value: 7,
                          label: Text(_isAr ? '٧ أيام' : '7 days'),
                        ),
                        ButtonSegment(
                          value: 30,
                          label: Text(_isAr ? '٣٠ يومًا' : '30 days'),
                        ),
                        ButtonSegment(
                          value: 90,
                          label: Text(_isAr ? '٩٠ يومًا' : '90 days'),
                        ),
                      ],
                      selected: {_days},
                      onSelectionChanged:
                          (value) => setState(() => _days = value.first),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 190,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child:
                          values.length < 2
                              ? Center(
                                child: Text(
                                  _isAr
                                      ? 'أضف قراءة أخرى لعرض الاتجاه.'
                                      : 'Add another reading to see a trend.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                              : CustomPaint(
                                painter: _ChartPainter(
                                  values,
                                  AppColors.accentFor(
                                    Theme.of(context).brightness,
                                  ),
                                ),
                                child: const SizedBox.expand(),
                              ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _isAr ? 'القراءات السابقة' : 'Previous readings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _isAr
                              ? 'لا توجد قراءات في هذه الفترة.'
                              : 'No readings in this period.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...filtered.reversed.map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            widget.icon,
                            color: AppColors.accentFor(
                              Theme.of(context).brightness,
                            ),
                          ),
                          title: Text(
                            '${r['value'] ?? '—'} ${r['unit'] ?? ''}',
                          ),
                          subtitle: Text(
                            '${MaterialLocalizations.of(context).formatFullDate(_date(r))} · '
                            '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_date(r)))}',
                          ),
                          trailing:
                              r['recipient'] == null
                                  ? null
                                  : Text('${r['recipient']}'),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.title,
    required this.icon,
    required this.value,
    required this.unit,
    required this.date,
    required this.isAr,
  });
  final String title, value, unit;
  final IconData icon;
  final DateTime date;
  final bool isAr;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: AppColors.pageGradientFor(Theme.of(context).brightness),
      borderRadius: BorderRadius.circular(26),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.accentFor(Theme.of(context).brightness),
          size: 28,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText(
              Theme.of(context).brightness,
            ).withValues(alpha: .8),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryText(Theme.of(context).brightness),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 7),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                unit,
                style: TextStyle(
                  color: AppColors.mutedText(Theme.of(context).brightness),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${isAr ? 'آخر تحديث' : 'Last updated'} · '
          '${MaterialLocalizations.of(context).formatFullDate(date)} · '
          '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(date))}',
          style: TextStyle(
            color: AppColors.mutedText(Theme.of(context).brightness),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.values, this.color);
  final List<double> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final span = maxValue - minValue == 0 ? 1.0 : maxValue - minValue;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y =
          size.height -
          ((values[i] - minValue) / span * (size.height - 18)) -
          9;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y =
          size.height -
          ((values[i] - minValue) / span * (size.height - 18)) -
          9;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}
