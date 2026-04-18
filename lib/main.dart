import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'providers/app_settings_provider.dart';
import 'providers/collaboration_provider.dart';
import 'providers/notification_provider.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/about/about_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/project/new_project_screen.dart';
import 'screens/project/join_project_screen.dart';
import 'screens/project/project_detail_screen.dart';
import 'screens/project/create_task_screen.dart';
import 'screens/meeting/meeting_room_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/ml/ml_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MentoraApp());
}

class MentoraApp extends StatelessWidget {
  const MentoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettingsProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProxyProvider<NotificationProvider, CollaborationProvider>(
          create: (_) => CollaborationProvider(),
          update: (_, notif, collab) {
            collab!.notifProvider = notif;
            return collab;
          },
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Mentora',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
              Locale('ar'),
            ],
            locale: Locale(settings.languageCode),
            initialRoute: AppRoutes.splash,
            routes: {
              AppRoutes.splash: (_) => const SplashScreen(),
              AppRoutes.about: (_) => const AboutScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.register: (_) => const RegisterScreen(),
              AppRoutes.home: (_) => const HomeScreen(),
              AppRoutes.newProject: (_) => const NewProjectScreen(),
              AppRoutes.joinProject: (_) => const JoinProjectScreen(),
              AppRoutes.projectDetail: (_) => const ProjectDetailScreen(),
              AppRoutes.createTask: (_) => const CreateTaskScreen(),
              AppRoutes.meetingRoom: (_) => const MeetingRoomScreen(),
              AppRoutes.profile: (_) => const ProfileScreen(),
              AppRoutes.mlHistory: (_) => const MlHistoryScreen(),
            },
          );
        },
      ),
    );
  }
}
