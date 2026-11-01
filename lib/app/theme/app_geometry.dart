import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const section = 32.0;
  static const page = EdgeInsets.fromLTRB(20, 12, 20, 104);
}

abstract final class AppRadius {
  static final input = BorderRadius.circular(16);
  static final button = BorderRadius.circular(18);
  static final card = BorderRadius.circular(24);
  static final hero = BorderRadius.circular(28);
  static const sheet = BorderRadius.vertical(top: Radius.circular(32));
}
