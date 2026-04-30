import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:fl_chart/fl_chart.dart'; // New Charting Package
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../theme/theme_manager.dart';
import '../data/habit_manager.dart';
import 'scaffold_with_navbar.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final manager = HabitManager();
  final themeManager = ThemeManager();
  HabitCategory _selectedCategory = HabitCategory.all;

  @override
  void initState() {
    super.initState();
    manager.loadHabits();
  }

  List<DateTime> _getLast5Days() {
    final days = <DateTime>[];
    for (int i = 4; i >= 0; i--) {
      days.add(DateTime.now().subtract(Duration(days: i)));
    }
    return days;
  }

  String _dateToString(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  int _calculateStreak(List<String> completedDates) {
    int streak = 0;
    final today = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateStr = _dateToString(checkDate);
      if (completedDates.contains(dateStr)) {
        streak++;
      } else {
        if (i == 0) continue;
        break;
      }
    }
    return streak;
  }

  void _showStats(BuildContext context, Habit habit, bool isDark) {
    final completedCount = habit.completedDates.length;
    final streak = _calculateStreak(habit.completedDates);
    final color = Color(habit.colorValue);
    final bg = isDark ? AppColors.surface : Colors.white;
    final textMain = isDark ? AppColors.primary : AppColors.primary;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_rounded, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                habit.name,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textMain),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  habit.category.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.grey : Colors.grey[600],
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              if (habit.reminderTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm, size: 14, color: isDark ? Colors.grey : Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "Daily at ${habit.reminderTime}",
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              
              // --- NEW CHART SECTION ---
              SizedBox(
                height: 150,
                width: double.infinity,
                child: _buildWeeklyChart(habit, color, isDark),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Streak", "$streak", "days", textMain),
                  _buildStatItem("Total", "$completedCount", "times", textMain),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldWithNavBar.showHabitDialog(context, habitToEdit: habit);
                    },
                    icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                    label: Text("Edit", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- NEW CHART BUILDER ---
  Widget _buildWeeklyChart(Habit habit, Color color, bool isDark) {
    // Generate data for the last 7 days
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    
    // Iterate 6 days back to today (0 to 6)
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = _dateToString(date);
      final isCompleted = habit.completedDates.contains(dateStr);
      
      // x is the index (0-6), y is 1 if completed, 0.1 (tiny bar) if not
      barGroups.add(
        BarChartGroupData(
          x: 6 - i, 
          barRods: [
            BarChartRodData(
              toY: isCompleted ? 1 : 0.1,
              color: isCompleted ? color : (isDark ? Colors.grey[800] : Colors.grey[200]),
              width: 12,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 1,
                color: isDark ? Colors.grey[850] : Colors.grey[100],
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: 1,
        minY: 0,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Map index 0-6 to Day Names
                final index = value.toInt();
                final date = now.subtract(Duration(days: 6 - index));
                final dayName = ['M','T','W','T','F','S','S'][date.weekday - 1];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    dayName,
                    style: TextStyle(
                      color: isDark ? Colors.grey : Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit, Color textColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)),
        Text("$unit $label", style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _deleteHabitWithUndo(Habit habit, int index, bool isDark) {
    manager.deleteHabit(habit.id);
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isDark ? AppColors.surface : AppColors.primary,
        content: Text(
          'Deleted "${habit.name}"',
          style: TextStyle(color: isDark ? AppColors.primary : Colors.white),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: AppColors.palette[0], // Emerald color
          onPressed: () {
            manager.restoreHabit(habit, index);
          },
        ),
        duration: const Duration(seconds: 3), // Reduced to 3 seconds
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getLast5Days();
    final todayStr = _dateToString(DateTime.now());

    return AnimatedBuilder(
      animation: Listenable.merge([manager, themeManager]),
      builder: (context, child) {
        // Filter habits based on selection
        final habits = _selectedCategory == HabitCategory.all 
            ? manager.habits 
            : manager.habits.where((h) => h.category == _selectedCategory).toList();
            
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          color: isDark ? AppColors.background : AppColors.background,
          child: Column(
            children: [
              _buildModernHeader(isDark),
              _buildCategoryFilters(isDark),
              Expanded(
                child: habits.isEmpty
                    ? _buildEmptyState(isDark)
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: habits.length,
                        onReorder: (oldIndex, newIndex) {
                          // Only reorder if showing ALL, otherwise it's confusing
                          if (_selectedCategory == HabitCategory.all) {
                             manager.reorderHabits(oldIndex, newIndex);
                          }
                        },
                        proxyDecorator: (child, index, animation) {
                          return Material(
                            elevation: 8,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withOpacity(0.2),
                            child: child,
                          );
                        },
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          return _buildModernHabitCard(
                            key: ValueKey(habit.id),
                            habit: habit, 
                            days: days, 
                            todayStr: todayStr, 
                            isDark: isDark,
                            index: index,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilters(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: HabitCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = HabitCategory.values[index];
          final isSelected = _selectedCategory == cat;
          final primaryColor = isDark ? AppColors.primary : AppColors.primary;
          
          return ChoiceChip(
            label: Text(
              cat.name[0].toUpperCase() + cat.name.substring(1),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? (isDark ? AppColors.background : Colors.white) : (isDark ? Colors.grey : Colors.grey[600]),
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _selectedCategory = cat);
            },
            selectedColor: primaryColor,
            backgroundColor: isDark ? AppColors.surface : Colors.white,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello there,',
                style: TextStyle(
                    fontSize: 16,
                    color: isDark ? AppColors.secondary : AppColors.secondary,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Your Habits',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.primary : AppColors.primary,
                    letterSpacing: -0.5),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => themeManager.toggleTheme(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  size: 20,
                  color: isDark ? AppColors.primary : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHabitCard({
    required Key key,
    required Habit habit,
    required List<DateTime> days,
    required String todayStr,
    required bool isDark,
    required int index,
  }) {
    final streak = _calculateStreak(habit.completedDates);
    final color = Color(habit.colorValue);
    final cardColor = isDark ? AppColors.surface : Colors.white;
    final primaryTextColor = isDark ? AppColors.primary : AppColors.primary;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _showStats(context, habit, isDark),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.spa_rounded, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(habit.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: primaryTextColor)),
                        const SizedBox(height: 4),
                        Text(
                            streak > 0
                                ? '$streak day streak 🔥'
                                : 'Start your streak',
                            style: TextStyle(
                                fontSize: 12,
                                color: streak > 0
                                    ? Colors.orange
                                    : (isDark
                                        ? AppColors.secondary
                                        : AppColors.secondary),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  // Edit Button
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: isDark ? Colors.grey[600] : Colors.grey.shade400, size: 20),
                    onPressed: () => ScaffoldWithNavBar.showHabitDialog(context, habitToEdit: habit),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16), // Space between buttons
                  // Delete Button
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: isDark ? Colors.grey[600] : Colors.grey.shade400, size: 20),
                    onPressed: () => _deleteHabitWithUndo(habit, index, isDark),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Days Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: days.map((day) {
                  final dateStr = _dateToString(day);
                  final isCompleted = habit.completedDates.contains(dateStr);
                  final isToday = dateStr == todayStr;
                  final weekDay = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
                  final isScheduled = habit.frequency.contains(day.weekday);
    
                  // If not scheduled for this day, render a "Rest Day" dot
                  if (!isScheduled) {
                     return Column(
                      children: [
                        Text(weekDay,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[800] : Colors.grey[300])),
                        const SizedBox(height: 8),
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact(); 
                      manager.toggleDay(habit.id, day);
                    },
                    child: Column(
                      children: [
                        Text(weekDay,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isToday
                                    ? color
                                    : (isDark
                                        ? Colors.grey[600]
                                        : Colors.grey.shade400))),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutBack,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isCompleted ? color : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: isCompleted
                                    ? color
                                    : (isToday
                                        ? color
                                        : (isDark
                                            ? Colors.grey[800]!
                                            : Colors.grey.shade200)),
                                width: 2),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome,
              size: 48, color: isDark ? Colors.grey[700] : Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No habits found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: (isDark ? AppColors.primary : AppColors.primary)
                      .withOpacity(0.5))),
          const SizedBox(height: 8),
          Text('Tap "New Habit" to start',
              style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400])),
        ],
      ),
    );
  }
}