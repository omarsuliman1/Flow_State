import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../providers/task_provider.dart';
import 'focus_timer_screen.dart';

class DayDetailScreen extends StatelessWidget {
  final WeeklyCategory category;
  const DayDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final tasks = provider.getTasksForCategory(category.id);

    // الحساب الدقيق لعدد الأيام بدون زيادات
    int totalDays = category.endDate.difference(category.startDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, provider),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. المربعات تظهر فقط لو الخطة أسبوعية أو شهرية (أكبر من يوم)
          if (totalDays > 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 5),
              decoration: BoxDecoration(
                color: provider.isDarkMode ? const Color(0xFF0D1117) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Plan Activity",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey)),
                      Text("$totalDays Days Plan",
                          style: const TextStyle(
                              fontSize: 11, color: Colors.blueGrey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      double spacing = 4.0;
                      double availableWidth = constraints.maxWidth;
                      // تقسيم المساحة بالظبط على عدد الأيام المختار
                      double boxSize = ((availableWidth - (totalDays * spacing)) /
                              totalDays)
                          .clamp(12.0, 30.0);

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.center,
                        children: List.generate(totalDays, (index) {
                          DateTime dayDate =
                              category.startDate.add(Duration(days: index));
                          return Container(
                            width: boxSize,
                            height: boxSize,
                            decoration: BoxDecoration(
                              color: provider.getInternalStreakColor(
                                  dayDate, category.id),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),

          // 2. شريط المهام المتبقية
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Remaining Goals",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${provider.getRemainingTasks(category.id)} Left",
                    style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // 3. قائمة المهام
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final task = tasks[i];
                return Card(
                  elevation: 0,
                  color: provider.isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[50],
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(task.title,
                        style: TextStyle(
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.isCompleted ? Colors.grey : null)),
                    trailing: Checkbox(
                      value: task.isCompleted,
                      activeColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      onChanged: task.isCompleted
                          ? null
                          : (v) {
                              provider.toggleTaskStatus(task.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Step Closer to Success! 🔥"),
                                    duration: Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating),
                              );
                            },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 👇 التعديل الجديد: زرارين عائمين (التايمر + الإضافة) 👇
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30), // لضمان عدم تداخل الأزرار مع الـ UI
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 🚀 زرار الفوكس تايمر (أزرق)
            FloatingActionButton(
              heroTag: "btn_timer_details", // تاج فريد عشان الإيرور
              onPressed: () => _showFocusTimerDialog(context),
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.timer_outlined, color: Colors.white),
            ),
            
            const SizedBox(width: 15),

            // ➕ زرار إضافة التاسك (الأصلي بتاعك بنفس المنطق)
            FloatingActionButton(
              heroTag: "btn_add_details", // تاج فريد
              onPressed: () {
                int addedTasks = provider.getTotalAddedTasks(category.id);
                if (addedTasks < category.targetAmount) {
                  _showAddTaskDialog(context, provider);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          "Target Reached! You can't add more than ${category.targetAmount} tasks."),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              backgroundColor: const Color(0xFF00FF41), // لون النيون بتاعك
              child: const Icon(Icons.add, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // --- Functions ---

  void _showEditDialog(BuildContext context, TaskProvider p) {
    String newTitle = category.title;
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Edit Plan Name"),
              content: TextField(
                onChanged: (v) => newTitle = v,
                decoration: InputDecoration(hintText: category.title),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () {
                      p.updateCategory(category.id, newTitle);
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text("Save")),
              ],
            ));
  }

  void _showAddTaskDialog(BuildContext context, TaskProvider p) {
    String title = "";
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("New Task"),
              content: TextField(onChanged: (v) => title = v, autofocus: true),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () {
                      if (title.isNotEmpty) {
                        p.addTask(title, DateTime.now(), category.id);
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Add")),
              ],
            ));
  }

  void _showFocusTimerDialog(BuildContext context) {
    int selectedMinutes = 25;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text("Set Focus Timer ⏱️"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("$selectedMinutes Minutes",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              Slider(
                value: selectedMinutes.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                onChanged: (v) =>
                    setLocalState(() => selectedMinutes = v.toInt()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _startFocusSession(context, selectedMinutes);
              },
              child: const Text("Start Session"),
            ),
          ],
        ),
      ),
    );
  }

  void _startFocusSession(BuildContext context, int minutes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusTimerScreen(durationInMinutes: minutes),
      ),
    );
  }
}