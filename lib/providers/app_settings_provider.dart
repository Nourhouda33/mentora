import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  bool _darkMode = true;
  String _languageCode = 'fr';
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = true;

  bool get darkMode => _darkMode;
  String get languageCode => _languageCode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get soundEnabled => _soundEnabled;

  AppSettingsProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? true;
    _languageCode = prefs.getString('languageCode') ?? 'fr';
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    _vibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibrationEnabled', value);
    notifyListeners();
  }

  Future<void> setSound(bool value) async {
    _soundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', value);
    notifyListeners();
  }

  /// Translation helper
  String t(String key) {
    final map = _languageCode == 'ar' ? _ar : (_languageCode == 'en' ? _en : _fr);
    return map[key] ?? key;
  }

  // ── French ────────────────────────────────────────────────────────────────
  static const Map<String, String> _fr = {
    'app_name': 'Mentora',
    'splash_subtitle': 'Votre coéquipier de projet IA',
    'hello': 'Bonjour',
    'new_project_btn': 'Nouveau',
    'about': 'À propos',
    'create_project': 'Créer un projet',
    'join_project': 'Rejoindre un projet',
    'already_account': 'Vous avez déjà un compte ?',
    'sign_in': 'Se connecter',
    'login': 'Connexion',
    'register': 'Inscription',
    'email': 'Email',
    'password': 'Mot de passe',
    'confirm_password': 'Confirmer le mot de passe',
    'full_name': 'Nom complet',
    'forgot_password': 'Mot de passe oublié ?',
    'no_account': 'Pas encore de compte ?',
    'sign_up': "S'inscrire",
    'home': 'Accueil',
    'projects': 'Projets',
    'my_projects': 'Mes projets',
    'new_project': 'Nouveau projet',
    'project_name': 'Nom du projet',
    'project_description': 'Description',
    'create': 'Créer',
    'join': 'Rejoindre',
    'cancel': 'Annuler',
    'save': 'Enregistrer',
    'delete': 'Supprimer',
    'edit': 'Modifier',
    'send': 'Envoyer',
    'chat': 'Chat',
    'tasks': 'Tâches',
    'files': 'Fichiers',
    'meetings': 'Réunions',
    'members': 'Membres',
    'add_task': 'Ajouter une tâche',
    'task_title': 'Titre de la tâche',
    'task_description': 'Description de la tâche',
    'assigned_to': 'Assigné à',
    'due_date': 'Date limite',
    'priority': 'Priorité',
    'status': 'Statut',
    'todo': 'À faire',
    'in_progress': 'En cours',
    'done': 'Terminé',
    'high': 'Haute',
    'medium': 'Moyenne',
    'low': 'Basse',
    'profile': 'Profil',
    'settings': 'Paramètres',
    'logout': 'Déconnexion',
    'dark_mode': 'Mode sombre',
    'language': 'Langue',
    'notifications': 'Notifications',
    'vibration': 'Vibration',
    'sound': 'Son',
    'ml_history': 'Historique ML',
    'scan_qr': 'Scanner QR',
    'scan_text': 'Reconnaître texte',
    'meeting_room': 'Salle de réunion',
    'join_meeting': 'Rejoindre la réunion',
    'start_meeting': 'Démarrer la réunion',
    'invite_code': 'Code d\'invitation',
    'copy_code': 'Copier le code',
    'about_title': 'À propos de Mentora',
    'about_desc': 'Application de gestion de projets collaboratifs avec IA.',
    'version': 'Version',
    'no_projects': 'Aucun projet pour l\'instant',
    'type_message': 'Tapez un message...',
    'attach_file': 'Joindre un fichier',
    'no_tasks': 'Aucune tâche',
    'no_files': 'Aucun fichier',
    'no_meetings': 'Aucune réunion',
    'upload_file': 'Téléverser un fichier',
    'schedule_meeting': 'Planifier une réunion',
    'meeting_title': 'Titre de la réunion',
    'meeting_date': 'Date de la réunion',
    'meeting_link': 'Lien de la réunion',
  };

  // ── English ───────────────────────────────────────────────────────────────
  static const Map<String, String> _en = {
    'app_name': 'Mentora',
    'splash_subtitle': 'Your AI-powered project teammate',
    'hello': 'Hello',
    'new_project_btn': 'New',
    'about': 'About',
    'create_project': 'Create a Project',
    'join_project': 'Join a Project',
    'already_account': 'Already have an account?',
    'sign_in': 'Sign in',
    'login': 'Login',
    'register': 'Register',
    'email': 'Email',
    'password': 'Password',
    'confirm_password': 'Confirm password',
    'full_name': 'Full name',
    'forgot_password': 'Forgot password?',
    'no_account': 'Don\'t have an account?',
    'sign_up': 'Sign up',
    'home': 'Home',
    'projects': 'Projects',
    'my_projects': 'My Projects',
    'new_project': 'New Project',
    'project_name': 'Project name',
    'project_description': 'Description',
    'create': 'Create',
    'join': 'Join',
    'cancel': 'Cancel',
    'save': 'Save',
    'delete': 'Delete',
    'edit': 'Edit',
    'send': 'Send',
    'chat': 'Chat',
    'tasks': 'Tasks',
    'files': 'Files',
    'meetings': 'Meetings',
    'members': 'Members',
    'add_task': 'Add Task',
    'task_title': 'Task title',
    'task_description': 'Task description',
    'assigned_to': 'Assigned to',
    'due_date': 'Due date',
    'priority': 'Priority',
    'status': 'Status',
    'todo': 'To Do',
    'in_progress': 'In Progress',
    'done': 'Done',
    'high': 'High',
    'medium': 'Medium',
    'low': 'Low',
    'profile': 'Profile',
    'settings': 'Settings',
    'logout': 'Logout',
    'dark_mode': 'Dark mode',
    'language': 'Language',
    'notifications': 'Notifications',
    'vibration': 'Vibration',
    'sound': 'Sound',
    'ml_history': 'ML History',
    'scan_qr': 'Scan QR',
    'scan_text': 'Recognize Text',
    'meeting_room': 'Meeting Room',
    'join_meeting': 'Join Meeting',
    'start_meeting': 'Start Meeting',
    'invite_code': 'Invite Code',
    'copy_code': 'Copy Code',
    'about_title': 'About Mentora',
    'about_desc': 'AI-powered collaborative project management app.',
    'version': 'Version',
    'no_projects': 'No projects yet',
    'type_message': 'Type a message...',
    'attach_file': 'Attach file',
    'no_tasks': 'No tasks',
    'no_files': 'No files',
    'no_meetings': 'No meetings',
    'upload_file': 'Upload File',
    'schedule_meeting': 'Schedule Meeting',
    'meeting_title': 'Meeting title',
    'meeting_date': 'Meeting date',
    'meeting_link': 'Meeting link',
  };

  // ── Arabic ────────────────────────────────────────────────────────────────
  static const Map<String, String> _ar = {
    'app_name': 'Mentora',
    'splash_subtitle': 'رفيقك الذكي في إدارة المشاريع',
    'hello': 'مرحباً',
    'new_project_btn': 'جديد',
    'about': 'حول',
    'create_project': 'إنشاء مشروع',
    'join_project': 'الانضمام لمشروع',
    'already_account': 'لديك حساب بالفعل؟',
    'sign_in': 'تسجيل الدخول',
    'login': 'تسجيل الدخول',
    'register': 'إنشاء حساب',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'confirm_password': 'تأكيد كلمة المرور',
    'full_name': 'الاسم الكامل',
    'forgot_password': 'نسيت كلمة المرور؟',
    'no_account': 'ليس لديك حساب؟',
    'sign_up': 'إنشاء حساب',
    'home': 'الرئيسية',
    'projects': 'المشاريع',
    'my_projects': 'مشاريعي',
    'new_project': 'مشروع جديد',
    'project_name': 'اسم المشروع',
    'project_description': 'الوصف',
    'create': 'إنشاء',
    'join': 'انضمام',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'delete': 'حذف',
    'edit': 'تعديل',
    'send': 'إرسال',
    'chat': 'المحادثة',
    'tasks': 'المهام',
    'files': 'الملفات',
    'meetings': 'الاجتماعات',
    'members': 'الأعضاء',
    'add_task': 'إضافة مهمة',
    'task_title': 'عنوان المهمة',
    'task_description': 'وصف المهمة',
    'assigned_to': 'مسند إلى',
    'due_date': 'تاريخ الاستحقاق',
    'priority': 'الأولوية',
    'status': 'الحالة',
    'todo': 'للتنفيذ',
    'in_progress': 'قيد التنفيذ',
    'done': 'منجز',
    'high': 'عالية',
    'medium': 'متوسطة',
    'low': 'منخفضة',
    'profile': 'الملف الشخصي',
    'settings': 'الإعدادات',
    'logout': 'تسجيل الخروج',
    'dark_mode': 'الوضع الداكن',
    'language': 'اللغة',
    'notifications': 'الإشعارات',
    'vibration': 'الاهتزاز',
    'sound': 'الصوت',
    'ml_history': 'سجل الذكاء الاصطناعي',
    'scan_qr': 'مسح QR',
    'scan_text': 'التعرف على النص',
    'meeting_room': 'غرفة الاجتماع',
    'join_meeting': 'الانضمام للاجتماع',
    'start_meeting': 'بدء الاجتماع',
    'invite_code': 'رمز الدعوة',
    'copy_code': 'نسخ الرمز',
    'about_title': 'حول Mentora',
    'about_desc': 'تطبيق إدارة المشاريع التعاونية بالذكاء الاصطناعي.',
    'version': 'الإصدار',
    'no_projects': 'لا توجد مشاريع بعد',
    'type_message': 'اكتب رسالة...',
    'attach_file': 'إرفاق ملف',
    'no_tasks': 'لا توجد مهام',
    'no_files': 'لا توجد ملفات',
    'no_meetings': 'لا توجد اجتماعات',
    'upload_file': 'رفع ملف',
    'schedule_meeting': 'جدولة اجتماع',
    'meeting_title': 'عنوان الاجتماع',
    'meeting_date': 'تاريخ الاجتماع',
    'meeting_link': 'رابط الاجتماع',
  };
}
