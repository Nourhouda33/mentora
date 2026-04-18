import 'package:flutter/material.dart';

// ── Model ─────────────────────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────
class NotificationProvider extends ChangeNotifier {
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

  /// Ajoute une notification (appelé depuis CollaborationProvider)
  void add({required String title, required String message}) {
    _notifications.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        date: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Marque une notification comme lue
  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  /// Marque toutes comme lues
  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  /// Supprime une notification
  void remove(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
