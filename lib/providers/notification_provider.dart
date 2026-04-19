import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  bool isRead;
  final String? projectId;
  final String? type;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.projectId,
    this.type,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: d['title'] ?? '',
      message: d['message'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: d['isRead'] ?? false,
      projectId: d['projectId'],
      type: d['type'],
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'message': message,
        'date': Timestamp.fromDate(date),
        'isRead': isRead,
        if (projectId != null) 'projectId': projectId,
        if (type != null) 'type': type,
      };
}

class NotificationProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications.take(5).toList());

  int get unreadCount =>
      _notifications.take(5).where((n) => !n.isRead).length;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('notifications');

  void listenToNotifications() {
    if (_uid.isEmpty) return;
    _col
        .orderBy('date', descending: true)
        .limit(5)
        .snapshots()
        .listen((snap) {
      _notifications
        ..clear()
        ..addAll(snap.docs.map((d) => AppNotification.fromDoc(d)));
      notifyListeners();
    });
  }

  Future<void> add({required String title, required String message}) async {
    if (_uid.isEmpty) return;
    final now = DateTime.now();
    final ref = _col.doc();
    final notif = AppNotification(
      id: ref.id,
      title: title,
      message: message,
      date: now,
    );
    await ref.set(notif.toMap());

    final allDocs = await _col
        .orderBy('date', descending: true)
        .get();
    if (allDocs.docs.length > 5) {
      for (final doc in allDocs.docs.skip(5)) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> markRead(String id) async {
    if (_uid.isEmpty) return;
    await _col.doc(id).update({'isRead': true});
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (_uid.isEmpty) return;
    final batch = _db.batch();
    for (final n in _notifications.where((n) => !n.isRead)) {
      batch.update(_col.doc(n.id), {'isRead': true});
      n.isRead = true;
    }
    await batch.commit();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    if (_uid.isEmpty) return;
    await _col.doc(id).delete();
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
