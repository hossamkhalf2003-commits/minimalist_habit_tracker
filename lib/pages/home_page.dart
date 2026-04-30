import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Added ScreenUtil
import 'package:fl_chart/fl_chart.dart';
import '../models/habit.dart';
import '../theme/app_colors.dart';
import '../theme/theme_manager.dart';
import '../data/habit_manager.dart';
import 'scaffold_with_navbar.dart';

// --- HELPER FUNCTIONS ---
String _dateToString(DateTime date) {
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

int _calculateStreak(List<String> completedDates) {
  int streak = 0;
  final today = DateTime.now();
  for (int i = 0; i < 365; i++) {
    final dateStr = _dateToString(today.subtract(Duration(days: i)));
    if (completedDates.contains(dateStr)) {
      streak++;
    } else if (i > 0) {
      break;
    }
  }
  return streak;
}

List<DateTime> _getLast5Days() {
  return List.generate(5, (i) => DateTime.now().subtract(Duration(days: 4 - i)));
}

// --- MAIN PAGE ---
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

  void _deleteHabitWithUndo(Habit habit, int index, bool isDark) {
    manager.deleteHabit(habit.id);
    
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isDark ? AppColors.surface : AppColors.primary,
          content: Text(
            'Deleted "${habit.name}"',
            style: TextStyle(color: isDark ? AppColors.primary : Colors.white),
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.palette[0],
            onPressed: () => manager.restoreHabit(habit, index),
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
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
        final habits = _selectedCategory == HabitCategory.all 
            ? manager.habits 
            : manager.habits.where((h) => h.category == _selectedCategory).toList();
            
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          color: AppColors.background,
          // SafeArea added here to protect the header from the notch/status bar
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _buildModernHeader(isDark),
                _buildCategoryFilters(isDark),
                Expanded(
                  child: habits.isEmpty
                      ? _buildEmptyState(isDark)
                      : ReorderableListView.builder(
                          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
                          itemCount: habits.length,
                          onReorder: (oldIndex, newIndex) {
                            if (_selectedCategory == HabitCategory.all) {
                               manager.reorderHabits(oldIndex, newIndex);
                            }
                          },
                          proxyDecorator: (child, index, animation) => Material(
                            elevation: 8,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withOpacity(0.2),
                            child: child,
                          ),
                          itemBuilder: (context, index) {
                            final habit = habits[index];
                            return _HabitCard(
                              key: ValueKey(habit.id),
                              habit: habit,
                              days: days,
                              todayStr: todayStr,
                              isDark: isDark,
                              onEdit: () => ScaffoldWithNavBar.showHabitDialog(context, habitToEdit: habit),
                              onDelete: () => _deleteHabitWithUndo(habit, index, isDark),
                              onToggleDay: (day) {
                                HapticFeedback.heavyImpact(); 
                                manager.toggleDay(habit.id, day);
                              },
                              onShowStats: () => showDialog(
                                context: context,
                                builder: (_) => _HabitStatsDialog(habit: habit, isDark: isDark),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                'Hello there,',
                style: TextStyle(fontSize: 16.sp, color: AppColors.secondary, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4.h),
               Text(
                'Your Habits',
                style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: -0.5),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => themeManager.toggleTheme(),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surface : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10.r, offset: Offset(0, 4.h))
                ],
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20.sp,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(bool isDark) {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        scrollDirection: Axis.horizontal,
        itemCount: HabitCategory.values.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final cat = HabitCategory.values[index];
          final isSelected = _selectedCategory == cat;
          
          return ChoiceChip(
            label: Text(
              cat.name[0].toUpperCase() + cat.name.substring(1),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? (isDark ? AppColors.background : Colors.white) 
                    : (isDark ? Colors.grey : Colors.grey[600]),
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _selectedCategory = cat);
            },
            selectedColor: AppColors.primary,
            backgroundColor: isDark ? AppColors.surface : Colors.white,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 48.sp, color: isDark ? Colors.grey[700] : Colors.grey.shade300),
          SizedBox(height: 16.h),
          Text(
            'No habits found',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: AppColors.primary.withOpacity(0.5)),
          ),
          SizedBox(height: 8.h),
          Text('Tap "New Habit" to start', style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400], fontSize: 14.sp)),
        ],
      ),
    );
  }
}

// --- EXTRACTED WIDGETS ---

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final List<DateTime> days;
  final String todayStr;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowStats;
  final Function(DateTime) onToggleDay;

  const _HabitCard({
    super.key,
    required this.habit,
    required this.days,
    required this.todayStr,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onShowStats,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    final streak = _calculateStreak(habit.completedDates);
    final color = Color(habit.colorValue);
    final cardColor = isDark ? AppColors.surface : Colors.white;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 20.r, offset: Offset(0, 8.h))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onShowStats,
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(streak, color),
              SizedBox(height: 24.h),
              _buildDaysGrid(color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int streak, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14.r)),
          child: Icon(Icons.spa_rounded, color: color, size: 20.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(habit.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.primary)),
              SizedBox(height: 4.h),
              Text(
                streak > 0 ? '$streak day streak 🔥' : 'Start your streak',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: streak > 0 ? Colors.orange : AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit_outlined, color: isDark ? Colors.grey[600] : Colors.grey.shade400, size: 20.sp),
          onPressed: onEdit,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        SizedBox(width: 16.w),
        IconButton(
          icon: Icon(Icons.delete_outline, color: isDark ? Colors.grey[600] : Colors.grey.shade400, size: 20.sp),
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildDaysGrid(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((day) {
        final dateStr = _dateToString(day);
        final isCompleted = habit.completedDates.contains(dateStr);
        final isToday = dateStr == todayStr;
        final weekDay = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][day.weekday - 1];
        final isScheduled = habit.frequency.contains(day.weekday);

        if (!isScheduled) {
          return Column(
            children: [
              Text(weekDay, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[800] : Colors.grey[300])),
              SizedBox(height: 8.h),
              Container(
                // Use .w for both width and height to maintain a perfect circle
                width: 36.w,
                height: 36.w,
                alignment: Alignment.center,
                child: Container(
                  width: 4.w, height: 4.w,
                  decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[300], shape: BoxShape.circle),
                ),
              ),
            ],
          );
        }

        return GestureDetector(
          onTap: () => onToggleDay(day),
          child: Column(
            children: [
              Text(
                weekDay,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: isToday ? color : (isDark ? Colors.grey[600] : Colors.grey.shade400),
                ),
              ),
              SizedBox(height: 8.h),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: isCompleted ? color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? color : (isToday ? color : (isDark ? Colors.grey[800]! : Colors.grey.shade200)),
                    width: 2.w,
                  ),
                ),
                child: isCompleted ? Icon(Icons.check, size: 18.sp, color: Colors.white) : null,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _HabitStatsDialog extends StatelessWidget {
  final Habit habit;
  final bool isDark;

  const _HabitStatsDialog({required this.habit, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final streak = _calculateStreak(habit.completedDates);
    final color = Color(habit.colorValue);
    final bg = isDark ? AppColors.surface : Colors.white;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.emoji_events_rounded, color: color, size: 32.sp),
            ),
            SizedBox(height: 16.h),
            Text(habit.name, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.primary)),
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Text(
                habit.category.name.toUpperCase(),
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.grey : Colors.grey[600], letterSpacing: 1.0),
              ),
            ),
            if (habit.reminderTime != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm, size: 14.sp, color: isDark ? Colors.grey : Colors.grey[600]),
                    SizedBox(width: 4.w),
                    Text("Daily at ${habit.reminderTime}", style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.grey : Colors.grey[600])),
                  ],
                ),
              ),
            SizedBox(height: 24.h),
            SizedBox(
              height: 150.h,
              width: double.infinity,
              child: _buildWeeklyChart(color),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("Streak", "$streak", "days"),
                _buildStatItem("Total", "${habit.completedDates.length}", "times"),
              ],
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldWithNavBar.showHabitDialog(context, habitToEdit: habit);
                  },
                  icon: Icon(Icons.edit_outlined, size: 18.sp, color: Colors.grey),
                  label: Text("Edit", style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
                ),
                SizedBox(width: 8.w),
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(fontSize: 14.sp))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: AppColors.primary)),
        Text("$unit $label", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
      ],
    );
  }

  Widget _buildWeeklyChart(Color color) {
    final now = DateTime.now();
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final isCompleted = habit.completedDates.contains(_dateToString(date));
      
      barGroups.add(
        BarChartGroupData(
          x: 6 - i, 
          barRods: [
            BarChartRodData(
              toY: isCompleted ? 1 : 0.1,
              color: isCompleted ? color : (isDark ? Colors.grey[800] : Colors.grey[200]),
              width: 12.w,
              borderRadius: BorderRadius.circular(4.r),
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
                final index = value.toInt();
                final date = now.subtract(Duration(days: 6 - index));
                final dayName = ['M','T','W','T','F','S','S'][date.weekday - 1];
                return Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    dayName,
                    style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600], fontSize: 10.sp, fontWeight: FontWeight.bold),
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
}