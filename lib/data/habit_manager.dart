import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import 'notification_manager.dart';

class HabitManager extends ChangeNotifier {
  static final HabitManager _instance = HabitManager._internal();
  factory HabitManager() => _instance;
  HabitManager._internal();

  List<Habit> _habits = [];
  List<Habit> get habits => _habits;
  final NotificationManager _notificationManager = NotificationManager();

  Future<void> loadHabits() async {
    try {
      await _notificationManager.init();
      await _notificationManager.requestPermissions();
    } catch (e) {
      debugPrint("Notification init error: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    final String? habitsJson = prefs.getString('habit-tracker-v1');

    if (habitsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(habitsJson);
        _habits = decoded.map((e) => Habit.fromJson(e)).toList();
      } catch (e) {
        debugPrint("Error loading habits: $e");
      }
    } else {
      _habits = [
        Habit(id: 1, name: 'Read 20 mins', colorValue: AppColors.palette[0].value, completedDates: [], category: HabitCategory.personal),
        Habit(id: 2, name: 'Drink 2L Water', colorValue: AppColors.palette[4].value, completedDates: [], category: HabitCategory.health),
      ];
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_habits.map((h) => h.toJson()).toList());
    await prefs.setString('habit-tracker-v1', encoded);
  }

  void _scheduleSafe(int id, String name, TimeOfDay? time) {
    if (time == null) return;
    try {
      _notificationManager.scheduleDailyNotification(
        id: id,
        title: name,
        hour: time.hour,
        minute: time.minute,
      );
    } catch (e) {
      debugPrint("Failed to schedule notification: $e");
    }
  }

  void addHabit(String name, TimeOfDay? reminderTime, List<int> frequency, HabitCategory category) {
    int colorIndex = _habits.length % AppColors.palette.length;
    final int id = DateTime.now().millisecondsSinceEpoch;
    
    String? timeString;
    if (reminderTime != null) {
      final hour = reminderTime.hour.toString().padLeft(2, '0');
      final minute = reminderTime.minute.toString().padLeft(2, '0');
      timeString = "$hour:$minute";
      _scheduleSafe(id, name, reminderTime);
    }

    final newHabit = Habit(
      id: id,
      name: name,
      colorValue: AppColors.palette[colorIndex].value,
      completedDates: [],
      reminderTime: timeString,
      frequency: frequency,
      category: category,
    );
    
    _habits.add(newHabit);
    notifyListeners();
    _save();
  }

  void editHabit(int id, String newName, TimeOfDay? newReminderTime, List<int> newFrequency, HabitCategory newCategory) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;

    try {
      _notificationManager.cancelNotification(id);
    } catch (e) {
      debugPrint("Error canceling notification: $e");
    }

    String? timeString;
    if (newReminderTime != null) {
      final hour = newReminderTime.hour.toString().padLeft(2, '0');
      final minute = newReminderTime.minute.toString().padLeft(2, '0');
      timeString = "$hour:$minute";
      _scheduleSafe(id, newName, newReminderTime);
    }

    _habits[index] = Habit(
      id: id,
      name: newName,
      colorValue: _habits[index].colorValue,
      completedDates: _habits[index].completedDates,
      reminderTime: timeString,
      frequency: newFrequency,
      category: newCategory,
    );
    
    notifyListeners();
    _save();
  }

  void deleteHabit(int id) {
    try {
      _notificationManager.cancelNotification(id);
    } catch (e) {
      debugPrint("Error canceling notification: $e");
    }
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
    _save();
  }

  void restoreHabit(Habit habit, int index) {
    if (index < 0 || index > _habits.length) {
      _habits.add(habit);
    } else {
      _habits.insert(index, habit);
    }

    if (habit.reminderTime != null) {
      try {
        final parts = habit.reminderTime!.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final time = TimeOfDay(hour: hour, minute: minute);
        _scheduleSafe(habit.id, habit.name, time);
      } catch (e) {
        debugPrint("Error rescheduling notification: $e");
      }
    }

    notifyListeners();
    _save();
  }

  void reorderHabits(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final Habit item = _habits.removeAt(oldIndex);
    _habits.insert(newIndex, item);
    notifyListeners();
    _save();
  }

  void toggleDay(int habitId, DateTime date) {
    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final index = _habits.indexWhere((h) => h.id == habitId);
    
    if (index != -1) {
      final habit = _habits[index];
      
      if (!habit.frequency.contains(date.weekday)) return;

      final List<String> newDates = List.from(habit.completedDates);

      if (newDates.contains(dateStr)) {
        newDates.remove(dateStr);
      } else {
        newDates.add(dateStr);
      }

      _habits[index] = Habit(
        id: habit.id,
        name: habit.name,
        colorValue: habit.colorValue,
        completedDates: newDates,
        reminderTime: habit.reminderTime,
        frequency: habit.frequency,
        category: habit.category,
      );
      notifyListeners();
      _save();
    }
  }
}