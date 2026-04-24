import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  List<WeeklyCategory> _categories = [];
  List<DailyTask> _tasks = [];
  bool _isDarkMode = false;
  String _userName = ""; 

   int currentStreak = 0; 
  int maxGlobalStreak = 0; 
  DateTime lastSuccessDate = DateTime(2000); 

  List<WeeklyCategory> get categories => _categories;
  List<DailyTask> get tasks => _tasks; 
  bool get isDarkMode => _isDarkMode;
  String get userName => _userName;

  TaskProvider() { loadData(); }

   void updateGlobalStreak() {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    DateTime lastDate = DateTime(
      lastSuccessDate.year, 
      lastSuccessDate.month, 
      lastSuccessDate.day
    );

     if (today.isAfter(lastDate)) {
      int difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        currentStreak++; 
      } else {
        currentStreak = 1; 
      }
      
      lastSuccessDate = today; 
    } 
     else if (currentStreak == 0) {
      currentStreak = 1;
      lastSuccessDate = today;
    }

    if (currentStreak > maxGlobalStreak) {
      maxGlobalStreak = currentStreak;
    }
    
    saveData(); 
    notifyListeners(); 
  }

  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  void setUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    NotificationService().scheduleDaily8AM(100, name);
    notifyListeners();
  }

  void addCategory(String title, String type, int days, int target, {DateTime? deadline}) {
    DateTime start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    
    _categories.add(WeeklyCategory(
      id: "cat_${DateTime.now().microsecondsSinceEpoch}",
      title: title,
      durationType: type,
      startDate: start,
      endDate: start.add(Duration(days: days)),
      targetAmount: target,
      progress: 0.0,
      dailyDeadline: type == 'day' ? deadline : null,
    ));
    
    saveData();
    notifyListeners();
  }

  bool isPlanFinished(WeeklyCategory cat) {
    return cat.progress >= 1.0;
  }

  bool isDeadlineMissed(WeeklyCategory cat) {
    if (cat.dailyDeadline == null || cat.progress >= 1.0) return false;
    return DateTime.now().isAfter(cat.dailyDeadline!);
  }

  int getRemainingTasks(String categoryId) {
    try {
      final cat = _categories.firstWhere((c) => c.id == categoryId);
      final completed = _tasks.where((t) => t.categoryId == categoryId && t.isCompleted).length;
      return (cat.targetAmount - completed).clamp(0, 999);
    } catch (e) { return 0; }
  }

   bool PlanFinished(WeeklyCategory cat) {
    return cat.progress >= 1.0;
  }

  void deleteCategory(String id) {
    NotificationService().cancelPlanReminders(id.hashCode);
    _categories.removeWhere((c) => c.id == id);
    saveData();
    notifyListeners();
  }

  void updateCategory(String id, String newTitle) {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      _categories[index].title = newTitle;
      saveData();
      notifyListeners();
    }
  }

  void addTask(String title, DateTime date, String categoryId) {
    _tasks.add(DailyTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      categoryId: categoryId,
      title: title,
      date: DateTime(date.year, date.month, date.day),
      isCompleted: false,
    ));

    final cat = _categories.firstWhere((c) => c.id == categoryId);
    NotificationService().schedulePlanReminders(
      planId: categoryId.hashCode,
      userName: _userName.isEmpty ? "User" : _userName,
      planName: cat.title,
      planEndTime: cat.endDate,
    );

    _updateCategoryProgress(categoryId);
    saveData();
    notifyListeners();
  }

  void toggleTaskStatus(String taskId) {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      bool wasCompleted = _tasks[index].isCompleted;
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      
      _updateCategoryProgress(_tasks[index].categoryId);
      
       if (!wasCompleted && _tasks[index].isCompleted) {
        updateGlobalStreak();
      }
      
      saveData();
      notifyListeners();
    }
  }

  void _updateCategoryProgress(String categoryId) {
    final catIndex = _categories.indexWhere((c) => c.id == categoryId);
    if (catIndex != -1) {
      final completed = _tasks.where((t) => t.categoryId == categoryId && t.isCompleted).length;
      double newProgress = (completed / _categories[catIndex].targetAmount).clamp(0.0, 1.0);
      
      if (newProgress >= 1.0 && _categories[catIndex].progress < 1.0) {
        NotificationService().cancelPlanReminders(categoryId.hashCode);

        NotificationService().showInstantNotification(
          "Plan Completed!",
          "Great job $userName! Your plan '${_categories[catIndex].title}' is done 🔥"
        );
      }

      _categories[catIndex].progress = newProgress;
    }
  }

   int getCurrentStreak() {
    if (_tasks.isEmpty) return 0;
    final completedDates = _tasks
        .where((t) => t.isCompleted)
        .map((t) => DateFormat('yyyy-MM-dd').format(t.date))
        .toSet();
    int streak = 0;
    DateTime checkDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    while (completedDates.contains(DateFormat('yyyy-MM-dd').format(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Color getStreakColor(DateTime date) {
    int count = _tasks.where((t) => t.isCompleted && DateUtils.isSameDay(t.date, date)).length;
    if (count == 0) return _isDarkMode ? const Color(0xFF161B22) : const Color(0xFFEBEDF0);
    if (count == 1) return const Color(0xFF9BE9A8);
    if (count == 2) return const Color(0xFF40C463);
    if (count == 3) return const Color(0xFF30A14E);
    return const Color(0xFF216E39);
  }

  Color getInternalStreakColor(DateTime date, String categoryId) {
    int count = _tasks.where((t) => 
      t.categoryId == categoryId && 
      t.isCompleted && 
      DateUtils.isSameDay(t.date, date)
    ).length;

    if (count == 0) return _isDarkMode ? const Color(0xFF161B22) : const Color(0xFFEBEDF0);
    if (count == 1) return const Color(0xFF9BE9A8);
    if (count == 2) return const Color(0xFF40C463);
    return const Color(0xFF216E39);
  }

  int getTotalAddedTasks(String categoryId) {
    return _tasks.where((t) => t.categoryId == categoryId).length;
  }

  List<DailyTask> getTasksForCategory(String categoryId) => 
      _tasks.where((t) => t.categoryId == categoryId).toList();

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('categories', jsonEncode(_categories.map((c) => c.toMap()).toList()));
    await prefs.setString('tasks', jsonEncode(_tasks.map((t) => t.toMap()).toList()));
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setString('userName', _userName);
    await prefs.setInt('currentStreak', currentStreak); 
    await prefs.setInt('maxGlobalStreak', maxGlobalStreak); 
    await prefs.setString('lastSuccessDate', lastSuccessDate.toIso8601String());
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _userName = prefs.getString('userName') ?? "";
    currentStreak = prefs.getInt('currentStreak') ?? 0;
    maxGlobalStreak = prefs.getInt('maxGlobalStreak') ?? 0;
    String? lastDateStr = prefs.getString('lastSuccessDate');
    if (lastDateStr != null) {
      lastSuccessDate = DateTime.parse(lastDateStr);
    }

    String? cats = prefs.getString('categories');
    String? tsks = prefs.getString('tasks');
    if (cats != null) _categories = (jsonDecode(cats) as List).map((i) => WeeklyCategory.fromMap(i)).toList();
    if (tsks != null) _tasks = (jsonDecode(tsks) as List).map((i) => DailyTask.fromMap(i)).toList();
    notifyListeners();
  }
}