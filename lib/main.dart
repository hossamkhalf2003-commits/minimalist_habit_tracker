import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_colors.dart';
import 'theme/theme_manager.dart';

void main() {
  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatefulWidget {
  const HabitTrackerApp({super.key});

  @override
  State<HabitTrackerApp> createState() => _HabitTrackerAppState();
}

class _HabitTrackerAppState extends State<HabitTrackerApp> {
  final themeManager = ThemeManager();

  @override
  void initState() {
    super.initState();
    themeManager.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Minimalist Habit Tracker',
          debugShowCheckedModeBanner: false,

          // Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              surface: AppColors.surface,
              brightness: Brightness.light,
            ),
            fontFamily: 'Roboto',
          ),

          // Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              surface: AppColors.surface,
              brightness: Brightness.dark,
            ),
            fontFamily: 'Roboto',
          ),

          themeMode: themeManager.themeMode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
