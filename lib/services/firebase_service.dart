import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Accès centralisé aux instances Firebase
class FB {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get db => FirebaseFirestore.instance;

  // Collections
  static CollectionReference get users => db.collection('users');
  static CollectionReference get projects => db.collection('projects');

  static CollectionReference messages(String projectId) =>
      db.collection('projects').doc(projectId).collection('messages');

  static CollectionReference tasks(String projectId) =>
      db.collection('projects').doc(projectId).collection('tasks');

  static CollectionReference files(String projectId) =>
      db.collection('projects').doc(projectId).collection('files');

  static CollectionReference meetings(String projectId) =>
      db.collection('projects').doc(projectId).collection('meetings');

  // Current user helpers
  static User? get currentUser => auth.currentUser;
  static String get uid => auth.currentUser?.uid ?? '';
  static String get displayName =>
      auth.currentUser?.displayName ?? auth.currentUser?.email?.split('@').first ?? 'User';
  static String get email => auth.currentUser?.email ?? '';
}
