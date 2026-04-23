
class WeeklyCategory {
  final String id;
  String title;

  final String durationType; // 'day', 'week', 'month'
  final DateTime startDate;
  final DateTime endDate;
  final int targetAmount;
  double progress;
  
  // 👇 التعديل الجديد: الديدلاين لليومي فقط
  final DateTime? dailyDeadline; 

  WeeklyCategory({
    required this.id,
    required this.title,
    required this.durationType,
    required this.startDate,
    required this.endDate,
    required this.targetAmount,
    required this.progress,
    this.dailyDeadline, // اختياري
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'durationType': durationType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'targetAmount': targetAmount,
      'progress': progress,
      // 👇 حفظ الديدلاين في الماب
      'dailyDeadline': dailyDeadline?.toIso8601String(),
    };
  }

  factory WeeklyCategory.fromMap(Map<String, dynamic> map) {
    return WeeklyCategory(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      durationType: map['durationType'] ?? 'day',
      startDate: DateTime.parse(map['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(map['endDate'] ?? DateTime.now().toIso8601String()),
      targetAmount: map['targetAmount'] ?? 1,
      progress: (map['progress'] ?? 0.0).toDouble(),
      // 👇 استعادة الديدلاين من الماب
      dailyDeadline: map['dailyDeadline'] != null ? DateTime.parse(map['dailyDeadline']) : null,
    );
  }
}

// كلاس الـ DailyTask بيفضل زي ما هو لأنك ضايف فيه الـ deadline فعلاً
class DailyTask {
  final String id;
  final String categoryId;
  final String title;
  final DateTime date;
  final DateTime? deadline; 
  bool isCompleted;

  DailyTask({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.date,
    this.deadline,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'title': title,
      'date': date.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory DailyTask.fromMap(Map<String, dynamic> map) {
    return DailyTask(
      id: map['id'] ?? '',
      categoryId: map['categoryId'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}