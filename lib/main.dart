import 'package:flutter/material.dart';
import 'package:flutter_application_memorita_final_project/main_navigation.dart';
import 'routes/app_routes.dart';
import 'core/constants/themes.dart';
import 'core/services/storage_service.dart';
import 'core/services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();

  runApp(const LifeArchiveApp());
}

class LifeArchiveApp extends StatelessWidget {
  const LifeArchiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeMode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Memorita - Life Archive',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const MainNavigation(),
          routes: AppRoutes.routes,
        );
      },
    );
  }

  
}