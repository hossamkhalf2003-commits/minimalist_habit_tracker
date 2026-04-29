import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../data/habit_manager.dart';
import '../models/habit.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navBarColor = isDark ? AppColors.darkSurface : Colors.white;
    final selectedItemColor =
        isDark ? AppColors.darkPrimary : AppColors.primary;
    final unselectedItemColor =
        isDark ? AppColors.darkSecondary : AppColors.secondary;
    final fabBackgroundColor =
        isDark ? AppColors.darkPrimary : AppColors.primary;
    final fabContentColor = isDark ? AppColors.darkBackground : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: navBarColor,
          elevation: 0,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(index, context),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
          ],
        ),
      ),
      floatingActionButton: _calculateSelectedIndex(context) == 0
          ? FloatingActionButton.extended(
              onPressed: () => showHabitDialog(context),
              backgroundColor: fabBackgroundColor,
              elevation: 4,
              icon: Icon(Icons.add_rounded, color: fabContentColor),
              label: Text(
                "New Habit",
                style: TextStyle(
                  color: fabContentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/calendar')) return 1;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/calendar');
        break;
    }
  }

  static void showHabitDialog(BuildContext context, {Habit? habitToEdit}) {
    final TextEditingController controller =
        TextEditingController(text: habitToEdit?.name ?? '');
    TimeOfDay? selectedTime;
    List<int> selectedDays = habitToEdit?.frequency ?? [1, 2, 3, 4, 5, 6, 7];
    HabitCategory selectedCategory =
        habitToEdit?.category ?? HabitCategory.personal;

    if (habitToEdit?.reminderTime != null) {
      try {
        final parts = habitToEdit!.reminderTime!.split(':');
        selectedTime =
            TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        // ignore error
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final dialogBg = isDark ? AppColors.darkSurface : Colors.white;
          final textColor = isDark ? AppColors.darkPrimary : AppColors.primary;
          final inputFill =
              isDark ? AppColors.darkBackground : AppColors.background;
          final hintColor = isDark ? AppColors.darkSecondary : Colors.grey;
          final primaryColor =
              isDark ? AppColors.darkPrimary : AppColors.primary;

          return AlertDialog(
            backgroundColor: dialogBg,
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              habitToEdit == null ? 'New Commitment' : 'Edit Habit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: textColor,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'e.g., Meditate...',
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: inputFill,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Frequency Selector
                  Text(
                    "Frequency",
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkSecondary
                          : AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                        .asMap()
                        .entries
                        .map((entry) {
                      final dayIndex = entry.key + 1;
                      final isSelected = selectedDays.contains(dayIndex);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              if (selectedDays.length > 1)
                                selectedDays.remove(dayIndex);
                            } else {
                              selectedDays.add(dayIndex);
                            }
                          });
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : inputFill,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              // Fix: Ensure text is readable on selected BG
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.darkBackground
                                      : Colors.white)
                                  : hintColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Category Selector
                  Text(
                    "Category",
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkSecondary
                          : AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: HabitCategory.values
                        .where((c) => c != HabitCategory.all)
                        .map((cat) {
                      final isSelected = selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(
                          cat.name[0].toUpperCase() + cat.name.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            // FIX: If selected in Dark Mode (BG is light), Text must be Dark
                            color: isSelected
                                ? (isDark
                                    ? AppColors.darkBackground
                                    : Colors.white)
                                : textColor,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: inputFill,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        onSelected: (selected) {
                          if (selected) setState(() => selectedCategory = cat);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Reminder Selector
                  Text(
                    "Reminder (Optional)",
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkSecondary
                          : AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime ?? TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: isDark ? ThemeData.dark() : ThemeData.light(),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications_outlined,
                              color: selectedTime != null
                                  ? AppColors.palette[0]
                                  : hintColor,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            selectedTime != null
                                ? selectedTime!.format(context)
                                : "Set a time",
                            style: TextStyle(
                              color:
                                  selectedTime != null ? textColor : hintColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (selectedTime != null) ...[
                            const Spacer(),
                            InkWell(
                              onTap: () => setState(() => selectedTime = null),
                              child:
                                  Icon(Icons.close, size: 16, color: hintColor),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    if (habitToEdit == null) {
                      HabitManager().addHabit(controller.text.trim(),
                          selectedTime, selectedDays, selectedCategory);
                    } else {
                      HabitManager().editHabit(
                          habitToEdit.id,
                          controller.text.trim(),
                          selectedTime,
                          selectedDays,
                          selectedCategory);
                    }
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.darkPrimary : AppColors.primary,
                  foregroundColor:
                      isDark ? AppColors.darkBackground : Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child:
                    Text(habitToEdit == null ? 'Start Habit' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
