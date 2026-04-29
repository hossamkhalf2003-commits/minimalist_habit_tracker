enum HabitCategory {
  all,
  health,
  work,
  personal,
  fitness,
  mindfulness,
}

class Habit {
  final int id;
  final String name;
  final int colorValue;
  final List<String> completedDates;
  final String? reminderTime;
  final List<int> frequency;
  final HabitCategory category; // New Field

  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.completedDates,
    this.reminderTime,
    this.frequency = const [1, 2, 3, 4, 5, 6, 7],
    this.category = HabitCategory.personal, // Default
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'completedDates': completedDates,
        'reminderTime': reminderTime,
        'frequency': frequency,
        'category': category.index, // Save as index
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        colorValue: json['colorValue'],
        completedDates: List<String>.from(json['completedDates']),
        reminderTime: json['reminderTime'],
        frequency: json['frequency'] != null 
            ? List<int>.from(json['frequency']) 
            : [1, 2, 3, 4, 5, 6, 7],
        category: json['category'] != null
            ? HabitCategory.values[json['category']]
            : HabitCategory.personal,
      );
}