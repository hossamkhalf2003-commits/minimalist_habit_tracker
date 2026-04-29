import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/habit_manager.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedMonth = DateTime.now();
  final manager = HabitManager();

  int _getDaysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  int _getFirstWeekdayOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    return firstDay.weekday == 7 ? 0 : firstDay.weekday;
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + offset,
      );
    });
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _dateToString(int year, int month, int day) {
    return "$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        final habits = manager.habits;
        final int daysInMonth = _getDaysInMonth(_focusedMonth);
        final int firstWeekday = _getFirstWeekdayOfMonth(_focusedMonth);

        return Column(
          children: [
            _buildHeader(),
            _buildDaysOfWeek(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: daysInMonth + firstWeekday,
                itemBuilder: (context, index) {
                  if (index < firstWeekday) return const SizedBox();

                  final int day = index - firstWeekday + 1;
                  final String dateStr = _dateToString(
                    _focusedMonth.year,
                    _focusedMonth.month,
                    day,
                  );

                  final completedHabits = habits
                      .where((h) => h.completedDates.contains(dateStr))
                      .toList();

                  final isToday =
                      day == DateTime.now().day &&
                      _focusedMonth.month == DateTime.now().month &&
                      _focusedMonth.year == DateTime.now().year;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday
                          ? Border.all(color: AppColors.primary, width: 2)
                          : Border.all(color: Colors.transparent),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isToday
                                ? AppColors.primary
                                : AppColors.secondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (completedHabits.isNotEmpty)
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 2,
                            runSpacing: 2,
                            children: completedHabits
                                .map(
                                  (habit) => Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Color(habit.colorValue),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left, color: AppColors.primary),
          ),
          Text(
            '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.surface,
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeek() {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map(
              (d) => SizedBox(
                width: 30,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
