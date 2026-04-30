import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Added ScreenUtil
import '../theme/app_colors.dart';
import '../data/habit_manager.dart';

// --- PURE HELPER FUNCTIONS ---
String _dateToString(int year, int month, int day) {
  return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
}

int _getDaysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;

int _getFirstWeekdayOfMonth(DateTime date) {
  final firstDay = DateTime(date.year, date.month, 1);
  return firstDay.weekday == 7 ? 0 : firstDay.weekday; // 0 = Sunday, 1 = Monday...
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

// --- MAIN WIDGET ---
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  final manager = HabitManager();

  void _changeMonth(int offset) {
    HapticFeedback.lightImpact();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset);
    });
  }

  /// Pre-calculates the habit colors for the current month.
  /// Prevents iterating through the entire habit history 31 times per frame.
  Map<String, List<Color>> _getMonthlyDotsMap() {
    final Map<String, List<Color>> dotsPerDay = {};
    final monthPrefix = "${_focusedMonth.year}-${_focusedMonth.month.toString().padLeft(2, '0')}";

    for (var habit in manager.habits) {
      final color = Color(habit.colorValue);
      // Only process dates that match the currently focused month
      final currentMonthDates = habit.completedDates.where((d) => d.startsWith(monthPrefix));
      
      for (var dateStr in currentMonthDates) {
        dotsPerDay.putIfAbsent(dateStr, () => []).add(color);
      }
    }
    return dotsPerDay;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        final int daysInMonth = _getDaysInMonth(_focusedMonth);
        final int firstWeekday = _getFirstWeekdayOfMonth(_focusedMonth);
        
        // Pre-calculate data for O(1) lookup inside the builder
        final monthlyDots = _getMonthlyDotsMap(); 
        final now = DateTime.now();

        return Container(
          color: AppColors.background,
          child: SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _buildHeader(isDark),
                _buildDaysOfWeek(isDark),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 8.h,
                      crossAxisSpacing: 8.w,
                    ),
                    itemCount: daysInMonth + firstWeekday,
                    itemBuilder: (context, index) {
                      if (index < firstWeekday) return const SizedBox.shrink();

                      final int day = index - firstWeekday + 1;
                      final String dateStr = _dateToString(_focusedMonth.year, _focusedMonth.month, day);
                      
                      final isToday = day == now.day && 
                                      _focusedMonth.month == now.month && 
                                      _focusedMonth.year == now.year;

                      return _CalendarDayCell(
                        day: day,
                        isToday: isToday,
                        isDark: isDark,
                        dotColors: monthlyDots[dateStr] ?? const [],
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

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? AppColors.primary : Colors.black87;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 28.sp),
          ),
          Text(
            '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 28.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek(bool isDark) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days.map((d) => SizedBox(
          width: 30.w,
          child: Text(
            d,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        )).toList(),
      ),
    );
  }
}

// --- EXTRACTED DAY CELL WIDGET ---
class _CalendarDayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isDark;
  final List<Color> dotColors;

  const _CalendarDayCell({
    required this.day,
    required this.isToday,
    required this.isDark,
    required this.dotColors,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.surface : Colors.white;
    final textColor = isToday 
        ? AppColors.primary 
        : (isDark ? Colors.grey[300] : Colors.black87);

    // Limit to 6 dots to prevent layout overflow in small cells
    final displayDots = dotColors.take(6).toList();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: isToday
            ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 2.w)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: TextStyle(
              fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 6.h),
          if (displayDots.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 3.w,
                runSpacing: 3.h,
                children: displayDots.map((color) => Container(
                  // Use .w for both width and height to ensure a perfect circle
                  width: 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}