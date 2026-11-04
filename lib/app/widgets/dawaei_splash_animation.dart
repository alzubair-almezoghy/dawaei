import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

const _logoAsset = 'assets/brand/dawaei_logo.png';
const _logoSourceSize = 1254.0;
const _teal = Color(0xFF00E5D4);

enum _LogoFragment { frame, capsule, clock, hand, ringing }

/// Choreographed, five-second assembly using clipped regions of the original
/// logo. The final crossfade returns to the unmodified source image.
class DawaeiSplashAnimation extends StatefulWidget {
  const DawaeiSplashAnimation({required this.duration, super.key});

  final Duration duration;

  @override
  State<DawaeiSplashAnimation> createState() => _DawaeiSplashAnimationState();
}

class _DawaeiSplashAnimationState extends State<DawaeiSplashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _frameDraw;
  late final Animation<double> _outlineOpacity;
  late final Animation<double> _frameOpacity;
  late final Animation<double> _capsuleProgress;
  late final Animation<double> _clockProgress;
  late final Animation<double> _handProgress;
  late final Animation<double> _ringingProgress;
  late final Animation<double> _finalReveal;
  late final Animation<double> _overallScale;
  late final Animation<Offset> _capsuleOffset;
  late final Animation<double> _capsuleScale;
  late final Animation<Offset> _clockOffset;
  late final Animation<double> _clockScale;
  late final Animation<double> _clockRotation;
  late final Animation<Offset> _handOffset;
  late final Animation<double> _handScale;
  late final Animation<Offset> _ringingOffset;
  late final Animation<double> _ringingScale;
  bool _reduceMotion = false;
  bool _precacheStarted = false;
  bool _imageReady = false;

  static const _logoProvider = AssetImage(_logoAsset);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _safeDuration(widget.duration),
    );
    _frameDraw = _phase(0, .28, Curves.easeInOutCubic);
    _outlineOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: const Cubic(.4, 0, .7, 1))),
        weight: 40,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, .36)),
    );
    _frameOpacity = _phase(.12, .30, _settleCurve);
    _capsuleProgress = _phase(.18, .48, _settleCurve);
    _clockProgress = _phase(.36, .66, _settleCurve);
    _handProgress = _phase(.54, .84, _settleCurve);
    _ringingProgress = _phase(.54, .84, _settleCurve);
    _finalReveal = _phase(.84, .99, _settleCurve);
    _overallScale = Tween<double>(
      begin: .97,
      end: 1,
    ).animate(_phase(0, .35, Curves.easeOutCubic));
    _capsuleOffset = Tween<Offset>(
      begin: const Offset(-.12, .13),
      end: Offset.zero,
    ).animate(_capsuleProgress);
    _capsuleScale = Tween<double>(begin: .94, end: 1).animate(_capsuleProgress);
    _clockOffset = Tween<Offset>(
      begin: const Offset(.015, -.075),
      end: Offset.zero,
    ).animate(_clockProgress);
    _clockScale = Tween<double>(begin: .92, end: 1).animate(_clockProgress);
    _clockRotation = Tween<double>(
      begin: -.045,
      end: 0,
    ).animate(_clockProgress);
    _handOffset = Tween<Offset>(
      begin: const Offset(0, .11),
      end: Offset.zero,
    ).animate(_handProgress);
    _handScale = Tween<double>(begin: .96, end: 1).animate(_handProgress);
    _ringingOffset = Tween<Offset>(
      begin: const Offset(0, .025),
      end: Offset.zero,
    ).animate(_ringingProgress);
    _ringingScale = Tween<double>(begin: .96, end: 1).animate(_ringingProgress);
  }

  static const Curve _settleCurve = Cubic(.18, .72, .22, 1);

  static Duration _safeDuration(Duration value) =>
      value <= Duration.zero ? const Duration(milliseconds: 1) : value;

  Animation<double> _phase(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _controller,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      if (reduceMotion) {
        _controller.value = 1;
      } else if (_imageReady) {
        _controller.forward(from: 0);
      }
    }
    if (!_precacheStarted) {
      _precacheStarted = true;
      unawaited(_prepareLogo());
    }
  }

  Future<void> _prepareLogo() async {
    try {
      await precacheImage(_logoProvider, context);
    } catch (_) {
      // Image.asset keeps its error placeholder behavior if decoding fails.
    }
    if (!mounted) return;
    _imageReady = true;
    if (!_reduceMotion) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DawaeiSplashAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration == widget.duration) return;
    final remaining = _safeDuration(widget.duration);
    final progress = _controller.value.clamp(0.0, .999999);
    final fractionLeft = 1 - progress;
    _controller.duration = Duration(
      microseconds: (remaining.inMicroseconds / fractionLeft).round(),
    );
    if (_reduceMotion) {
      _controller.value = 1;
    } else if (_imageReady) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final logoSize = math.min(
        250.0,
        math.min(constraints.maxWidth, constraints.maxHeight) * .66,
      );
      return Center(
        child: ScaleTransition(
          key: const ValueKey('splash-logo-scale'),
          scale: _overallScale,
          child: RepaintBoundary(
            child: SizedBox.square(
              dimension: logoSize,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(.02, -.08),
                        radius: .72,
                        colors: [Color(0x1A00E5D4), Color(0x0000E5D4)],
                        stops: [0, 1],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DawaeiFramePainter(
                        draw: _frameDraw,
                        opacity: _outlineOpacity,
                      ),
                    ),
                  ),
                  _fragment(
                    key: const ValueKey('splash-fragment-frame'),
                    fragment: _LogoFragment.frame,
                    progress: _frameOpacity,
                  ),
                  _fragment(
                    key: const ValueKey('splash-fragment-clock'),
                    fragment: _LogoFragment.clock,
                    progress: _clockProgress,
                    offset: _clockOffset,
                    scale: _clockScale,
                    rotation: _clockRotation,
                    rotationAlignment: const Alignment(.02, -.14),
                  ),
                  _fragment(
                    key: const ValueKey('splash-fragment-capsule'),
                    fragment: _LogoFragment.capsule,
                    progress: _capsuleProgress,
                    offset: _capsuleOffset,
                    scale: _capsuleScale,
                  ),
                  _fragment(
                    key: const ValueKey('splash-fragment-hand'),
                    fragment: _LogoFragment.hand,
                    progress: _handProgress,
                    offset: _handOffset,
                    scale: _handScale,
                  ),
                  _fragment(
                    key: const ValueKey('splash-fragment-ringing'),
                    fragment: _LogoFragment.ringing,
                    progress: _ringingProgress,
                    offset: _ringingOffset,
                    scale: _ringingScale,
                  ),
                  FadeTransition(
                    key: const ValueKey('splash-final-logo'),
                    opacity: _finalReveal,
                    child: Image(
                      image: _logoProvider,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _fragment({
    required Key key,
    required _LogoFragment fragment,
    required Animation<double> progress,
    Animation<Offset>? offset,
    Animation<double>? scale,
    Animation<double>? rotation,
    Alignment rotationAlignment = Alignment.center,
  }) => Positioned.fill(
    child: AnimatedBuilder(
      animation: _controller,
      child: RepaintBoundary(
        child: ClipPath(
          clipper: _LogoFragmentClipper(fragment),
          child: Image(
            image: _logoProvider,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
      builder: (context, child) {
        final alpha = progress.value * (1 - _finalReveal.value).clamp(0.0, 1.0);
        Widget moving = Transform.scale(scale: scale?.value ?? 1, child: child);
        if (rotation != null) {
          moving = Transform.rotate(
            angle: rotation.value,
            alignment: rotationAlignment,
            child: moving,
          );
        }
        if (offset != null) {
          moving = SlideTransition(position: offset, child: moving);
        }
        return Opacity(key: key, opacity: alpha.clamp(0.0, 1.0), child: moving);
      },
    ),
  );
}

class _DawaeiFramePainter extends CustomPainter {
  _DawaeiFramePainter({required this.draw, required this.opacity})
    : super(repaint: Listenable.merge([draw, opacity]));

  final Animation<double> draw;
  final Animation<double> opacity;

  static final List<PathMetric> _metrics = [
    ..._frameOuterPath(1).computeMetrics(),
    ..._frameInnerPath(1).computeMetrics(),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final progress = draw.value;
    if (progress <= 0 || opacity.value <= 0) return;
    canvas.save();
    canvas.scale(size.width / _logoSourceSize);
    final glowPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 28
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = _teal.withValues(alpha: .12 * opacity.value);
    final linePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = _teal.withValues(alpha: .78 * opacity.value);
    for (final metric in _metrics) {
      final partial = metric.extractPath(0, metric.length * progress);
      canvas
        ..drawPath(partial, glowPaint)
        ..drawPath(partial, linePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DawaeiFramePainter oldDelegate) => false;
}

class _LogoFragmentClipper extends CustomClipper<Path> {
  const _LogoFragmentClipper(this.fragment);

  final _LogoFragment fragment;

  @override
  Path getClip(Size size) {
    final unit = size.width / _logoSourceSize;
    return switch (fragment) {
      _LogoFragment.frame => _frameMask(unit),
      _LogoFragment.capsule => _capsulePath(unit),
      _LogoFragment.clock => _clockPath(unit),
      _LogoFragment.hand => _handPath(unit),
      _LogoFragment.ringing => _ringingPath(unit),
    };
  }

  @override
  bool shouldReclip(covariant _LogoFragmentClipper oldClipper) =>
      oldClipper.fragment != fragment;
}

Path _frameOuterPath(double unit) =>
    Path()
      ..moveTo(272 * unit, 192 * unit)
      ..cubicTo(
        367 * unit,
        177 * unit,
        499 * unit,
        143 * unit,
        574 * unit,
        130 * unit,
      )
      ..cubicTo(
        728 * unit,
        102 * unit,
        895 * unit,
        146 * unit,
        990 * unit,
        227 * unit,
      )
      ..cubicTo(
        1057 * unit,
        284 * unit,
        1082 * unit,
        362 * unit,
        1080 * unit,
        476 * unit,
      )
      ..lineTo(1074 * unit, 803 * unit)
      ..cubicTo(
        1072 * unit,
        938 * unit,
        1003 * unit,
        1031 * unit,
        889 * unit,
        1067 * unit,
      )
      ..cubicTo(
        840 * unit,
        1082 * unit,
        788 * unit,
        1086 * unit,
        710 * unit,
        1084 * unit,
      )
      ..lineTo(269 * unit, 1077 * unit)
      ..cubicTo(
        211 * unit,
        1075 * unit,
        179 * unit,
        1041 * unit,
        173 * unit,
        991 * unit,
      )
      ..cubicTo(
        164 * unit,
        908 * unit,
        178 * unit,
        809 * unit,
        182 * unit,
        697 * unit,
      )
      ..lineTo(192 * unit, 301 * unit)
      ..cubicTo(
        194 * unit,
        244 * unit,
        220 * unit,
        205 * unit,
        272 * unit,
        192 * unit,
      )
      ..close();

Path _frameInnerPath(double unit) =>
    Path()
      ..moveTo(202 * unit, 519 * unit)
      ..cubicTo(
        235 * unit,
        421 * unit,
        305 * unit,
        360 * unit,
        397 * unit,
        340 * unit,
      )
      ..cubicTo(
        523 * unit,
        312 * unit,
        732 * unit,
        317 * unit,
        849 * unit,
        330 * unit,
      )
      ..cubicTo(
        946 * unit,
        341 * unit,
        997 * unit,
        399 * unit,
        1008 * unit,
        478 * unit,
      )
      ..cubicTo(
        1024 * unit,
        587 * unit,
        1010 * unit,
        735 * unit,
        966 * unit,
        844 * unit,
      )
      ..cubicTo(
        925 * unit,
        941 * unit,
        851 * unit,
        973 * unit,
        725 * unit,
        1001 * unit,
      )
      ..cubicTo(
        583 * unit,
        1033 * unit,
        376 * unit,
        1036 * unit,
        273 * unit,
        999 * unit,
      )
      ..cubicTo(
        211 * unit,
        977 * unit,
        180 * unit,
        922 * unit,
        181 * unit,
        824 * unit,
      )
      ..lineTo(202 * unit, 519 * unit)
      ..close();

Path _frameMask(double unit) =>
    Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(_frameOuterPath(unit), Offset.zero)
      ..addPath(_frameInnerPath(unit), Offset.zero);

Path _capsulePath(double unit) =>
    Path()
      ..moveTo(383 * unit, 775 * unit)
      ..cubicTo(
        344 * unit,
        748 * unit,
        342 * unit,
        703 * unit,
        374 * unit,
        665 * unit,
      )
      ..lineTo(489 * unit, 531 * unit)
      ..cubicTo(
        526 * unit,
        489 * unit,
        584 * unit,
        492 * unit,
        617 * unit,
        526 * unit,
      )
      ..cubicTo(
        650 * unit,
        561 * unit,
        644 * unit,
        607 * unit,
        610 * unit,
        648 * unit,
      )
      ..lineTo(497 * unit, 777 * unit)
      ..cubicTo(
        463 * unit,
        817 * unit,
        415 * unit,
        805 * unit,
        383 * unit,
        775 * unit,
      )
      ..close();

Path _clockPath(double unit) {
  final path = Path()..fillType = PathFillType.evenOdd;
  path
    ..addOval(Rect.fromLTRB(501 * unit, 407 * unit, 807 * unit, 713 * unit))
    ..addOval(Rect.fromLTRB(536 * unit, 442 * unit, 772 * unit, 678 * unit));
  _addRoundLine(
    path,
    Offset(652 * unit, 551 * unit),
    Offset(657 * unit, 463 * unit),
    9 * unit,
  );
  _addRoundLine(
    path,
    Offset(652 * unit, 551 * unit),
    Offset(709 * unit, 591 * unit),
    10 * unit,
  );
  path
    ..addOval(
      Rect.fromCircle(
        center: Offset(652 * unit, 551 * unit),
        radius: 18 * unit,
      ),
    )
    ..addPath(_capsulePath(unit), Offset.zero);
  return path;
}

void _addRoundLine(Path path, Offset from, Offset to, double radius) {
  final direction = to - from;
  final length = direction.distance;
  final normal = Offset(-direction.dy / length, direction.dx / length) * radius;
  path
    ..moveTo(from.dx + normal.dx, from.dy + normal.dy)
    ..lineTo(to.dx + normal.dx, to.dy + normal.dy)
    ..lineTo(to.dx - normal.dx, to.dy - normal.dy)
    ..lineTo(from.dx - normal.dx, from.dy - normal.dy)
    ..close()
    ..addOval(Rect.fromCircle(center: from, radius: radius))
    ..addOval(Rect.fromCircle(center: to, radius: radius));
}

Path _handPath(double unit) =>
    Path()
      ..moveTo(176 * unit, 1011 * unit)
      ..cubicTo(
        194 * unit,
        883 * unit,
        244 * unit,
        809 * unit,
        315 * unit,
        790 * unit,
      )
      ..cubicTo(
        369 * unit,
        777 * unit,
        417 * unit,
        799 * unit,
        467 * unit,
        816 * unit,
      )
      ..cubicTo(
        532 * unit,
        839 * unit,
        604 * unit,
        844 * unit,
        657 * unit,
        799 * unit,
      )
      ..cubicTo(
        700 * unit,
        763 * unit,
        728 * unit,
        704 * unit,
        773 * unit,
        695 * unit,
      )
      ..cubicTo(
        796 * unit,
        690 * unit,
        813 * unit,
        703 * unit,
        807 * unit,
        724 * unit,
      )
      ..cubicTo(
        782 * unit,
        812 * unit,
        738 * unit,
        867 * unit,
        674 * unit,
        915 * unit,
      )
      ..cubicTo(
        596 * unit,
        974 * unit,
        469 * unit,
        1007 * unit,
        337 * unit,
        1045 * unit,
      )
      ..cubicTo(
        264 * unit,
        1066 * unit,
        202 * unit,
        1061 * unit,
        176 * unit,
        1032 * unit,
      )
      ..close();

Path _ringingPath(double unit) {
  final path = Path()..fillType = PathFillType.evenOdd;
  path
    ..moveTo(548 * unit, 430 * unit)
    ..cubicTo(
      536 * unit,
      401 * unit,
      558 * unit,
      374 * unit,
      589 * unit,
      381 * unit,
    )
    ..cubicTo(
      617 * unit,
      386 * unit,
      641 * unit,
      408 * unit,
      650 * unit,
      430 * unit,
    )
    ..cubicTo(
      655 * unit,
      443 * unit,
      647 * unit,
      455 * unit,
      635 * unit,
      461 * unit,
    )
    ..cubicTo(
      608 * unit,
      443 * unit,
      579 * unit,
      447 * unit,
      562 * unit,
      464 * unit,
    )
    ..close()
    ..moveTo(704 * unit, 418 * unit)
    ..cubicTo(
      727 * unit,
      391 * unit,
      759 * unit,
      402 * unit,
      779 * unit,
      427 * unit,
    )
    ..cubicTo(
      795 * unit,
      448 * unit,
      795 * unit,
      475 * unit,
      779 * unit,
      491 * unit,
    )
    ..cubicTo(
      758 * unit,
      473 * unit,
      733 * unit,
      462 * unit,
      712 * unit,
      463 * unit,
    )
    ..cubicTo(
      697 * unit,
      451 * unit,
      694 * unit,
      433 * unit,
      704 * unit,
      418 * unit,
    )
    ..close()
    ..moveTo(469 * unit, 415 * unit)
    ..cubicTo(
      430 * unit,
      443 * unit,
      421 * unit,
      483 * unit,
      440 * unit,
      522 * unit,
    )
    ..cubicTo(
      447 * unit,
      537 * unit,
      465 * unit,
      532 * unit,
      462 * unit,
      516 * unit,
    )
    ..cubicTo(
      450 * unit,
      484 * unit,
      461 * unit,
      456 * unit,
      488 * unit,
      438 * unit,
    )
    ..cubicTo(
      503 * unit,
      427 * unit,
      485 * unit,
      405 * unit,
      469 * unit,
      415 * unit,
    )
    ..close()
    ..moveTo(493 * unit, 448 * unit)
    ..cubicTo(
      468 * unit,
      466 * unit,
      465 * unit,
      490 * unit,
      478 * unit,
      512 * unit,
    )
    ..cubicTo(
      485 * unit,
      524 * unit,
      499 * unit,
      516 * unit,
      495 * unit,
      504 * unit,
    )
    ..cubicTo(
      488 * unit,
      488 * unit,
      492 * unit,
      474 * unit,
      507 * unit,
      462 * unit,
    )
    ..cubicTo(
      520 * unit,
      452 * unit,
      505 * unit,
      439 * unit,
      493 * unit,
      448 * unit,
    )
    ..close()
    ..moveTo(806 * unit, 479 * unit)
    ..cubicTo(
      827 * unit,
      510 * unit,
      827 * unit,
      550 * unit,
      807 * unit,
      591 * unit,
    )
    ..cubicTo(
      799 * unit,
      607 * unit,
      816 * unit,
      617 * unit,
      828 * unit,
      602 * unit,
    )
    ..cubicTo(
      856 * unit,
      561 * unit,
      851 * unit,
      507 * unit,
      826 * unit,
      474 * unit,
    )
    ..cubicTo(
      814 * unit,
      458 * unit,
      798 * unit,
      466 * unit,
      806 * unit,
      479 * unit,
    )
    ..close()
    ..moveTo(790 * unit, 498 * unit)
    ..cubicTo(
      802 * unit,
      522 * unit,
      801 * unit,
      548 * unit,
      788 * unit,
      570 * unit,
    )
    ..cubicTo(
      780 * unit,
      584 * unit,
      796 * unit,
      594 * unit,
      806 * unit,
      580 * unit,
    )
    ..cubicTo(
      824 * unit,
      552 * unit,
      824 * unit,
      516 * unit,
      806 * unit,
      489 * unit,
    )
    ..cubicTo(
      795 * unit,
      474 * unit,
      782 * unit,
      485 * unit,
      790 * unit,
      498 * unit,
    )
    ..close();
  return path;
}
