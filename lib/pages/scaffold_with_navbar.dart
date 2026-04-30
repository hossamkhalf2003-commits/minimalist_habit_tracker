import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    final navBarColor = isDark ? AppColors.surface : Colors.white;
    final fabContentColor = isDark ? AppColors.background : Colors.white;
    final currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      // Wrap body in SafeArea, explicitly protecting the top (status bar/notch)
      // We set bottom: false because the BottomNavigationBar handles its own safe area.
      body: SafeArea(
        top: true,
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBarColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20.r,
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: navBarColor,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.secondary,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(index, context),
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.grid_view_rounded, size: 24.sp),
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Icon(Icons.calendar_month_rounded, size: 24.sp),
              ),
              label: 'Calendar',
            ),
          ],
        ),
      ),
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => showHabitDialog(context),
              backgroundColor: AppColors.primary,
              elevation: 4,
              icon: Icon(Icons.add_rounded, color: fabContentColor, size: 22.sp),
              label: Text(
                "New Habit",
                style: TextStyle(
                  color: fabContentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            )
          : null,
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    return location.startsWith('/calendar') ? 1 : 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(index == 0 ? '/home' : '/calendar');
  }

  static void showHabitDialog(BuildContext context, {Habit? habitToEdit}) {
    showDialog(
      context: context,
      builder: (context) => _HabitDialog(habitToEdit: habitToEdit),
    );
  }
}

class _HabitDialog extends StatefulWidget {
  final Habit? habitToEdit;

  const _HabitDialog({this.habitToEdit});

  @override
  State<_HabitDialog> createState() => _HabitDialogState();
}

class _HabitDialogState extends State<_HabitDialog> {
  late final TextEditingController _controller;
  TimeOfDay? _selectedTime;
  late List<int> _selectedDays;
  late HabitCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    final habit = widget.habitToEdit;
    
    _controller = TextEditingController(text: habit?.name ?? '');
    _selectedDays = List.from(habit?.frequency ?? [1, 2, 3, 4, 5, 6, 7]);
    _selectedCategory = habit?.category ?? HabitCategory.personal;

    if (habit?.reminderTime != null) {
      try {
        final parts = habit!.reminderTime!.split(':');
        _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {
        // Fallback to null on parse error
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDay(int dayIndex) {
    setState(() {
      if (_selectedDays.contains(dayIndex)) {
        if (_selectedDays.length > 1) _selectedDays.remove(dayIndex);
      } else {
        _selectedDays.add(dayIndex);
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveHabit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final manager = HabitManager();
    if (widget.habitToEdit == null) {
      manager.addHabit(text, _selectedTime, _selectedDays, _selectedCategory);
    } else {
      manager.editHabit(widget.habitToEdit!.id, text, _selectedTime, _selectedDays, _selectedCategory);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.surface : Colors.white;
    final primaryColor = AppColors.primary;
    final hintColor = isDark ? AppColors.secondary : Colors.grey;

    return AlertDialog(
      backgroundColor: dialogBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      title: Text(
        widget.habitToEdit == null ? 'New Commitment' : 'Edit Habit',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp, color: primaryColor),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              style: TextStyle(color: primaryColor, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'e.g., Meditate...',
                hintStyle: TextStyle(color: hintColor, fontSize: 16.sp),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            _buildSectionLabel("Frequency"),
            _buildFrequencySelector(isDark, hintColor),
            SizedBox(height: 16.h),
            _buildSectionLabel("Category"),
            _buildCategorySelector(isDark, primaryColor),
            SizedBox(height: 16.h),
            _buildSectionLabel("Reminder (Optional)"),
            _buildReminderSelector(hintColor),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 14.sp)),
        ),
        ElevatedButton(
          onPressed: _saveHabit,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: isDark ? AppColors.background : Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
          child: Text(
            widget.habitToEdit == null ? 'Start Habit' : 'Save Changes',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.secondary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFrequencySelector(bool isDark, Color hintColor) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.asMap().entries.map((entry) {
        final dayIndex = entry.key + 1;
        final isSelected = _selectedDays.contains(dayIndex);

        return InkWell(
          onTap: () => _toggleDay(dayIndex),
          borderRadius: BorderRadius.circular(30.r),
          child: Container(
            // Use .w for both width and height to ensure a perfect circle regardless of aspect ratio
            width: 32.w,
            height: 32.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Text(
              entry.value,
              style: TextStyle(
                color: isSelected 
                    ? (isDark ? AppColors.background : Colors.white) 
                    : hintColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector(bool isDark, Color primaryColor) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: HabitCategory.values.where((c) => c != HabitCategory.all).map((cat) {
        final isSelected = _selectedCategory == cat;
        return ChoiceChip(
          label: Text(
            cat.name[0].toUpperCase() + cat.name.substring(1),
            style: TextStyle(
              fontSize: 12.sp,
              color: isSelected ? (isDark ? AppColors.background : Colors.white) : primaryColor,
            ),
          ),
          selected: isSelected,
          selectedColor: primaryColor,
          backgroundColor: AppColors.background,
          side: BorderSide.none,
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          onSelected: (selected) {
            if (selected) setState(() => _selectedCategory = cat);
          },
        );
      }).toList(),
    );
  }

  Widget _buildReminderSelector(Color hintColor) {
    return InkWell(
      onTap: _pickTime,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.notifications_outlined,
              color: _selectedTime != null ? AppColors.palette[0] : hintColor,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              _selectedTime != null ? _selectedTime!.format(context) : "Set a time",
              style: TextStyle(
                color: _selectedTime != null ? AppColors.primary : hintColor,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            if (_selectedTime != null) ...[
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _selectedTime = null),
                child: Icon(Icons.close, size: 18.sp, color: hintColor),
              )
            ]
          ],
        ),
      ),
    );
  }
}