import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notification_provider.dart';

enum TaskStatus { todo, inProgress, done }
enum TaskPriority { low, medium, high }
enum MessageType { text, image, file, calendar }

// ── Models ────────────────────────────────────────────────────────────────────

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String inviteCode;
  final String joinLink;
  final DateTime? deadline;
  final String ownerId;
  final List<String> members;
  final DateTime? createdAt;

  ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.inviteCode,
    required this.joinLink,
    this.deadline,
    this.ownerId = '',
    this.members = const [],
    this.createdAt,
  });

  factory ProjectModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      inviteCode: d['inviteCode'] ?? '',
      joinLink: d['joinLink'] ?? '',
      deadline: (d['deadline'] as Timestamp?)?.toDate(),
      ownerId: d['ownerId'] ?? '',
      members: List<String>.from(d['members'] ?? []),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'inviteCode': inviteCode,
        'joinLink': joinLink,
        'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
        'ownerId': ownerId,
        'members': members,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class MessageModel {
  final String id;
  final String projectId;
  final String sender;
  final String senderUid;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final String? filePath;
  final String? fileName;

  MessageModel({
    required this.id,
    required this.projectId,
    required this.sender,
    required this.senderUid,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.filePath,
    this.fileName,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc, String projectId) {
    final d = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      projectId: projectId,
      sender: d['sender'] ?? '',
      senderUid: d['senderUid'] ?? '',
      text: d['text'] ?? '',
      timestamp: (d['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
      filePath: d['filePath'],
      fileName: d['fileName'],
    );
  }

  Map<String, dynamic> toMap() => {
        'sender': sender,
        'senderUid': senderUid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type.name,
        if (filePath != null) 'filePath': filePath,
        if (fileName != null) 'fileName': fileName,
      };
}

class TaskModel {
  final String id;
  final String projectId;
  String title;
  String description;
  String assignedTo;
  String assignedToUid;
  DateTime? dueDate;
  TaskPriority priority;
  TaskStatus status;

  TaskModel({
    required this.id,
    required this.projectId,
    required this.title,
    this.description = '',
    this.assignedTo = '',
    this.assignedToUid = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
  });

  factory TaskModel.fromDoc(DocumentSnapshot doc, String projectId) {
    final d = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      projectId: projectId,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      assignedTo: d['assignedTo'] ?? '',
      assignedToUid: d['assignedToUid'] ?? '',
      dueDate: (d['dueDate'] as Timestamp?)?.toDate(),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == (d['priority'] ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'todo'),
        orElse: () => TaskStatus.todo,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'assignedToUid': assignedToUid,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
        'priority': priority.name,
        'status': status.name,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class FileModel {
  final String id;
  final String projectId;
  final String name;
  final String path;
  final DateTime uploadedAt;

  FileModel({
    required this.id,
    required this.projectId,
    required this.name,
    required this.path,
    required this.uploadedAt,
  });

  factory FileModel.fromDoc(DocumentSnapshot doc, String projectId) {
    final d = doc.data() as Map<String, dynamic>;
    return FileModel(
      id: doc.id,
      projectId: projectId,
      name: d['name'] ?? '',
      path: d['path'] ?? '',
      uploadedAt:
          (d['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'path': path,
        'uploadedAt': FieldValue.serverTimestamp(),
      };
}

class MeetingModel {
  final String id;
  final String projectId;
  final String title;
  final DateTime date;
  final String link;
  final int durationMinutes;
  final List<String> participants;

  MeetingModel({
    required this.id,
    required this.projectId,
    required this.title,
    required this.date,
    required this.link,
    this.durationMinutes = 0,
    this.participants = const [],
  });

  factory MeetingModel.fromDoc(DocumentSnapshot doc, String projectId) {
    final d = doc.data() as Map<String, dynamic>;
    return MeetingModel(
      id: doc.id,
      projectId: projectId,
      title: d['title'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      link: d['link'] ?? '',
      durationMinutes: d['durationMinutes'] ?? 0,
      participants: List<String>.from(d['participants'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'date': Timestamp.fromDate(date),
        'link': link,
        'durationMinutes': durationMinutes,
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ── Provider ──────────────────────────────────────────────────────────────────

class CollaborationProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  NotificationProvider? notifProvider;

  // Local cache
  List<ProjectModel> _projects = [];
  final Map<String, List<MessageModel>> _messages = {};
  final Map<String, List<TaskModel>> _tasks = {};
  final Map<String, List<FileModel>> _files = {};
  final Map<String, List<MeetingModel>> _meetings = {};

  List<ProjectModel> get projects => List.unmodifiable(_projects);

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _displayName =>
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email?.split('@').first ??
      'User';

  // ── Load projects for current user ────────────────────────────────────────
  Stream<List<ProjectModel>> projectsStream() {
    List<ProjectModel> _sorted(QuerySnapshot snap) {
      return snap.docs
          .map((d) => ProjectModel.fromDoc(d))
          .toList()
        ..sort((a, b) {
          final at = a.createdAt;
          final bt = b.createdAt;
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return bt.compareTo(at);
        });
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      return _db
          .collection('projects')
          .where('members', arrayContains: uid)
          .snapshots()
          .map((snap) {
        _projects = _sorted(snap);
        notifyListeners();
        return _projects;
      });
    }
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value(<ProjectModel>[]);
      return _db
          .collection('projects')
          .where('members', arrayContains: user.uid)
          .snapshots()
          .map((snap) {
        _projects = _sorted(snap);
        notifyListeners();
        return _projects;
      });
    });
  }

  // ── Messages stream ────────────────────────────────────────────────────────
  Stream<List<MessageModel>> messagesStream(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MessageModel.fromDoc(d, projectId))
          .toList();
      _messages[projectId] = list;
      notifyListeners();
      return list;
    });
  }

  // ── Tasks stream ───────────────────────────────────────────────────────────
  Stream<List<TaskModel>> tasksStream(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => TaskModel.fromDoc(d, projectId))
          .toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      _tasks[projectId] = list;
      notifyListeners();
      return list;
    });
  }

  // ── Files stream ───────────────────────────────────────────────────────────
  Stream<List<FileModel>> filesStream(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => FileModel.fromDoc(d, projectId)).toList();
      _files[projectId] = list;
      notifyListeners();
      return list;
    });
  }

  // ── Meetings stream ────────────────────────────────────────────────────────
  Stream<List<MeetingModel>> meetingsStream(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('meetings')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MeetingModel.fromDoc(d, projectId))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      _meetings[projectId] = list;
      notifyListeners();
      return list;
    });
  }

  // ── Cached getters (for non-stream access) ─────────────────────────────────
  List<MessageModel> messagesForProject(String projectId) =>
      _messages[projectId] ?? [];
  List<TaskModel> tasksForProject(String projectId) =>
      _tasks[projectId] ?? [];
  List<FileModel> filesForProject(String projectId) =>
      _files[projectId] ?? [];
  List<MeetingModel> meetingsForProject(String projectId) =>
      _meetings[projectId] ?? [];

  // ── Create project ─────────────────────────────────────────────────────────
  Future<ProjectModel> createProject({
    required String name,
    required String description,
    DateTime? deadline,
  }) async {
    final code = _generateNumericCode();
    final ref = _db.collection('projects').doc();
    final project = ProjectModel(
      id: ref.id,
      name: name,
      description: description,
      inviteCode: code,
      joinLink: 'mentora://join/${ref.id}',
      deadline: deadline,
      ownerId: _uid,
      members: [_uid],
    );
    await ref.set(project.toMap());
    notifProvider?.add(
      title: '🚀 Project created',
      message: '"$name" is ready. Share code $code with your team.',
    );
    return project;
  }

  // ── Join project ───────────────────────────────────────────────────────────
  Future<ProjectModel?> joinProjectByCode(String input) async {
    final clean = input.trim();
    QuerySnapshot snap;

    if (clean.startsWith('mentora://join/')) {
      final id = clean.replaceFirst('mentora://join/', '');
      final doc = await _db.collection('projects').doc(id).get();
      if (!doc.exists) return null;
      await _db.collection('projects').doc(id).update({
        'members': FieldValue.arrayUnion([_uid]),
      });
      return ProjectModel.fromDoc(doc);
    } else {
      snap = await _db
          .collection('projects')
          .where('inviteCode', isEqualTo: clean)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      await _db.collection('projects').doc(doc.id).update({
        'members': FieldValue.arrayUnion([_uid]),
      });
      return ProjectModel.fromDoc(doc);
    }
  }

  void joinProject(String code) => joinProjectByCode(code);

  // ── Send text message ──────────────────────────────────────────────────────
  Future<void> sendTextMessage({
    required String projectId,
    required String sender,
    required String text,
  }) async {
    final ref = _db
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .doc();
    await ref.set({
      'sender': sender,
      'senderUid': _uid,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Notification
    final projDoc =
        await _db.collection('projects').doc(projectId).get();
    if (projDoc.exists) {
      final name = (projDoc.data() as Map)['name'] ?? '';
      notifProvider?.add(
        title: '💬 New message in $name',
        message:
            '$sender: ${text.length > 60 ? '${text.substring(0, 60)}...' : text}',
      );
    }
  }

  // ── Send file message ──────────────────────────────────────────────────────
  Future<void> sendFileMessage({
    required String projectId,
    required String sender,
    required String fileName,
    required String filePath,
    required MessageType type,
  }) async {
    final batch = _db.batch();

    final msgRef = _db
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'sender': sender,
      'senderUid': _uid,
      'text': fileName,
      'type': type.name,
      'filePath': filePath,
      'fileName': fileName,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final fileRef = _db
        .collection('projects')
        .doc(projectId)
        .collection('files')
        .doc();
    batch.set(fileRef, {
      'name': fileName,
      'path': filePath,
      'uploadedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── Add task ───────────────────────────────────────────────────────────────
  Future<void> addTask(TaskModel task) async {
    final ref = _db
        .collection('projects')
        .doc(task.projectId)
        .collection('tasks')
        .doc();
    await ref.set(task.toMap());

    final projDoc =
        await _db.collection('projects').doc(task.projectId).get();
    if (!projDoc.exists) return;
    final projectName = (projDoc.data() as Map)['name'] ?? '';
    final creatorName = _displayName;

    // Notify current user's bell
    notifProvider?.add(
      title: '✅ Task created in $projectName',
      message: '"${task.title}" assigned to ${task.assignedTo.isEmpty ? 'someone' : task.assignedTo}',
    );

    // If assigned to someone else → write directly to their Firestore notifications
    final assignedUid = task.assignedToUid;
    if (assignedUid.isNotEmpty && assignedUid != _uid) {
      final notifRef = _db
          .collection('users')
          .doc(assignedUid)
          .collection('notifications')
          .doc();
      await notifRef.set({
        'title': '📋 New task assigned to you',
        'message': '"${task.title}" in $projectName — assigned by $creatorName',
        'date': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      // Keep max 5 for that user too
      final allNotifs = await _db
          .collection('users')
          .doc(assignedUid)
          .collection('notifications')
          .orderBy('date', descending: true)
          .get();
      if (allNotifs.docs.length > 5) {
        for (final doc in allNotifs.docs.skip(5)) {
          await doc.reference.delete();
        }
      }
    }
  }

  // ── Add task from AI suggestion ────────────────────────────────────────────
  Future<TaskModel> addTaskFromSuggestion({
    required String projectId,
    required String title,
  }) async {
    final task = TaskModel(
      id: '',
      projectId: projectId,
      title: title,
      assignedTo: _displayName,
      assignedToUid: _uid,
      status: TaskStatus.todo,
    );
    await addTask(task);
    return task;
  }

  // ── Cycle task status ──────────────────────────────────────────────────────
  Future<void> cycleTaskStatus(String taskId, String projectId) async {
    final tasks = _tasks[projectId] ?? [];
    final task = tasks.cast<TaskModel?>().firstWhere(
          (t) => t!.id == taskId,
          orElse: () => null,
        );
    if (task == null) return;
    final next = TaskStatus.values[
        (task.status.index + 1) % TaskStatus.values.length];
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({'status': next.name});
  }

  // ── Delete task ────────────────────────────────────────────────────────────
  Future<void> deleteTask(String taskId, String projectId) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // ── Add file ───────────────────────────────────────────────────────────────
  Future<void> addFile(FileModel file) async {
    await _db
        .collection('projects')
        .doc(file.projectId)
        .collection('files')
        .add(file.toMap());
  }

  // ── Add meeting ────────────────────────────────────────────────────────────
  Future<void> addMeeting(MeetingModel meeting) async {
    await _db
        .collection('projects')
        .doc(meeting.projectId)
        .collection('meetings')
        .add(meeting.toMap());
  }

  // ── Start live meeting (real-time) ─────────────────────────────────────────
  Future<void> startLiveMeeting({
    required String projectId,
    required String hostName,
    required String meetingTitle,
  }) async {
    final projDoc = await _db.collection('projects').doc(projectId).get();
    if (!projDoc.exists) return;
    final data = projDoc.data() as Map<String, dynamic>;
    final members = List<String>.from(data['members'] ?? []);
    final projectName = data['name'] ?? '';

    await _db.collection('projects').doc(projectId).update({
      'liveMeeting': {
        'hostUid': _uid,
        'hostName': hostName,
        'title': meetingTitle,
        'startedAt': FieldValue.serverTimestamp(),
        'active': true,
        'participants': {
          _uid: {
            'name': hostName,
            'joinedAt': FieldValue.serverTimestamp(),
            'micOn': true,
            'camOn': true,
          }
        },
      }
    });

    for (final uid in members) {
      if (uid == _uid) continue;
      final notifRef = _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();
      await notifRef.set({
        'title': '📹 Live meeting started in $projectName',
        'message': '$hostName started "$meetingTitle" — tap to join',
        'date': FieldValue.serverTimestamp(),
        'isRead': false,
        'projectId': projectId,
        'type': 'live_meeting',
      });
      final all = await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('date', descending: true)
          .get();
      if (all.docs.length > 5) {
        for (final doc in all.docs.skip(5)) {
          await doc.reference.delete();
        }
      }
    }
  }

  // ── Join live meeting ──────────────────────────────────────────────────────
  Future<void> joinLiveMeeting({
    required String projectId,
    required String participantName,
    required bool micOn,
    required bool camOn,
  }) async {
    await _db.collection('projects').doc(projectId).update({
      'liveMeeting.participants.$_uid': {
        'name': participantName,
        'joinedAt': FieldValue.serverTimestamp(),
        'micOn': micOn,
        'camOn': camOn,
      }
    });
  }

  // ── Update participant state (mic/cam) ─────────────────────────────────────
  Future<void> updateParticipantState({
    required String projectId,
    required bool micOn,
    required bool camOn,
  }) async {
    await _db.collection('projects').doc(projectId).update({
      'liveMeeting.participants.$_uid.micOn': micOn,
      'liveMeeting.participants.$_uid.camOn': camOn,
    });
  }

  // ── Leave live meeting ─────────────────────────────────────────────────────
  Future<void> leaveLiveMeeting(String projectId) async {
    await _db.collection('projects').doc(projectId).update({
      'liveMeeting.participants.$_uid': FieldValue.delete(),
    });
  }

  // ── End live meeting ───────────────────────────────────────────────────────
  Future<void> endLiveMeeting(String projectId) async {
    final doc = await _db.collection('projects').doc(projectId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final live = data['liveMeeting'] as Map<String, dynamic>?;
    if (live == null) return;

    final participants = (live['participants'] as Map<String, dynamic>? ?? {});
    final startedAt = (live['startedAt'] as Timestamp?)?.toDate();
    final durationMinutes = startedAt != null
        ? DateTime.now().difference(startedAt).inMinutes
        : 0;

    await _db
        .collection('projects')
        .doc(projectId)
        .collection('meetings')
        .add({
      'title': live['title'] ?? 'Live Meeting',
      'date': live['startedAt'] ?? FieldValue.serverTimestamp(),
      'link': '',
      'durationMinutes': durationMinutes,
      'participants': participants.keys.toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('projects').doc(projectId).update({
      'liveMeeting': FieldValue.delete(),
    });
  }

  // ── Stream live meeting state ──────────────────────────────────────────────
  Stream<Map<String, dynamic>?> liveMeetingStream(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final d = doc.data() as Map<String, dynamic>;
      return d['liveMeeting'] as Map<String, dynamic>?;
    });
  }

  // ── Meeting chat stream ────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> meetingChatStream(String projectId) {
    return _db
        .collection('projects')
        .doc(projectId)
        .collection('meetingChat')
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> sendMeetingChatMessage({
    required String projectId,
    required String text,
  }) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('meetingChat')
        .add({
      'senderUid': _uid,
      'senderName': _displayName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> clearMeetingChat(String projectId) async {
    final snap = await _db
        .collection('projects')
        .doc(projectId)
        .collection('meetingChat')
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Send calendar message ──────────────────────────────────────────────────
  Future<void> sendCalendarMessage({
    required String projectId,
    required String sender,
    required String title,
  }) async {
    await _db
        .collection('projects')
        .doc(projectId)
        .collection('messages')
        .add({
      'sender': sender,
      'senderUid': _uid,
      'text': title,
      'type': 'calendar',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String _generateNumericCode() {
    final rand = Random();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }
}
