import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Connectivity status ────────────────────────────────────────────────────
  static const Color online = Colors.green;
  static const Color offline = Colors.red;

  // ── Sync state ────────────────────────────────────────────────────────────
  static const Color pending = Colors.orange;
  static const Color synced = Colors.green;
  static const Color failed = Colors.red;

  // ── Log level colors ──────────────────────────────────────────────────────
  static const Color logSuccess = Color(0xFF2E7D32);
  static const Color logError = Color(0xFFC62828);
  static const Color logWarning = Color(0xFFE65100);
  static const Color logInfo = Color(0xFF1565C0);

  // ── Note action buttons ───────────────────────────────────────────────────
  static const Color like = Colors.red;
  static const Color bookmark = Colors.blue;
  static const Color delete = Colors.red;

  // ── Pending badge ─────────────────────────────────────────────────────────
  static const Color pendingBadgeBg = Color(0xFFFFF3E0);
  static const Color pendingBadgeBorder = Color(0xFFFFB74D);
  static const Color pendingBadgeText = Color(0xFFE65100);

  // ── Status banners ─────────────────────────────────────────────────────────
  static const Color warningBanner = Color(0xFFFFA000);
  static const Color errorBanner = Color(0xFFE53935);
}
