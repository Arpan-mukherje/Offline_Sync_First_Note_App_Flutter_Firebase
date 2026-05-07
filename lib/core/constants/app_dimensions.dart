import 'package:flutter/material.dart';

/// Spacing, sizing, and layout constants.
class AppDimensions {
  AppDimensions._();

  // ── Border radius values ──────────────────────────────────────────────────
  static const double r8 = 8;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r20 = 20;

  static final BorderRadius br8 = BorderRadius.circular(r8);
  static final BorderRadius br10 = BorderRadius.circular(r10);
  static final BorderRadius br12 = BorderRadius.circular(r12);
  static final BorderRadius br14 = BorderRadius.circular(r14);
  static final BorderRadius br16 = BorderRadius.circular(r16);
  static final BorderRadius br20 = BorderRadius.circular(r20);

  // ── Padding ───────────────────────────────────────────────────────────────
  static const EdgeInsets paddingCard = EdgeInsets.all(16);
  static const EdgeInsets paddingScreen = EdgeInsets.all(20);
  static const EdgeInsets paddingListView = EdgeInsets.fromLTRB(16, 16, 16, 96);
  static const EdgeInsets paddingStatRow = EdgeInsets.fromLTRB(16, 16, 16, 8);
  static const EdgeInsets paddingLogList = EdgeInsets.fromLTRB(16, 4, 16, 24);
  static const EdgeInsets paddingSection = EdgeInsets.fromLTRB(16, 8, 16, 6);

  // ── Icon sizes ────────────────────────────────────────────────────────────
  static const double iconXS = 11;
  static const double iconSM = 12;
  static const double iconMD = 17;
  static const double iconLG = 20;
  static const double iconXL = 26;
  static const double iconEmptyState = 80;
  static const double iconEmptyLogs = 56;

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const double buttonHeight = 52;
  static const double cardBorderWidth = 1.2;
  static const double logBorderWidth = 3;
}
