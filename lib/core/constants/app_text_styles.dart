import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── App bar ───────────────────────────────────────────────────────────────
  static const TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );
  static const TextStyle appBarSubtitle = TextStyle(
    fontWeight: FontWeight.bold,
  );

  // ── Note card ─────────────────────────────────────────────────────────────
  static const TextStyle noteTitle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    height: 1.3,
  );
  static const TextStyle noteContent = TextStyle(fontSize: 14, height: 1.5);
  static const TextStyle noteTimestamp = TextStyle(fontSize: 11);

  // ── Badges ────────────────────────────────────────────────────────────────
  static const TextStyle pendingBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle badgeCount = TextStyle(
    color: Colors.white,
    fontSize: 9,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle connectivityLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ── Stats & logs ──────────────────────────────────────────────────────────
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
  static const TextStyle statValue = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    height: 1,
  );
  static const TextStyle statLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle logMessage = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  static const TextStyle logTimestamp = TextStyle(fontSize: 11);

  // ── Empty / placeholder ───────────────────────────────────────────────────
  static const TextStyle emptyTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle emptySubtitle = TextStyle(fontSize: 14, height: 1.5);
  static const TextStyle emptyActivityText = TextStyle(fontSize: 15);

  // ── Status banner ─────────────────────────────────────────────────────────
  static const TextStyle statusBannerText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  // ── Forms ─────────────────────────────────────────────────────────────────
  static const TextStyle formInput = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}
