import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import 'day_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserIdentity();
  }
  
  void _checkUserIdentity() {
    Future.microtask(() async {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      if (provider.userName.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
      if (provider.userName.isEmpty && mounted) {
        _showNameDialog(context, provider);
      }
    });
  }

  void _showDateToast(String date) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(date, textAlign: TextAlign.center),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        width: 200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Flow State", style: TextStyle(fontWeight: FontWeight.bold)),
            if (provider.userName.isNotEmpty)
              Text('Hello ${provider.userName}', 
                style: const TextStyle(fontSize: 18, color: Colors.teal)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(provider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => provider.toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Activity Map", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${provider.currentStreak} Current Streak🔥", 
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            _buildGlobalStreak(provider),
            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: provider.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  "${provider.maxGlobalStreak} Days in a row 🔥", 
                  style: const TextStyle(
                    color: Colors.orange, 
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            
            ElevatedButton(
              onPressed: () => _showAddGoalDialog(context, provider),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: const Color(0xFF216E39),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Create New Plan +", 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 25),
            _buildGrid(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStreak(TaskProvider provider) {
    DateTime now = DateTime.now();
    int shift = (now.weekday + 1) % 7;
    DateTime startDate = now.subtract(Duration(days: 28 + shift));
    List<DateTime> days = List.generate(35, (i) => startDate.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: provider.isDarkMode ? const Color(0xFF0D1117) : Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5),
        itemCount: days.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () => _showDateToast(DateFormat('MMM d, yyyy').format(days[i])),
            child: Container(
              decoration: BoxDecoration(
                color: provider.getStreakColor(days[i]),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(TaskProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.9),
      itemCount: provider.categories.length,
      itemBuilder: (context, index) {
        final cat = provider.categories[index];
        bool finished = provider.isPlanFinished(cat);
        bool missed = provider.isDeadlineMissed(cat); 

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (context) => DayDetailScreen(category: cat))),
          onLongPress: () => _showDeleteDialog(context, provider, cat.id),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: provider.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: finished ? Colors.orange : (missed ? Colors.red : Colors.transparent), 
                width: 2
              ),
            ),
            child: Column(
              children: [
                Text(cat.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), 
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const Spacer(),
                CircularPercentIndicator(
                  radius: 35.0, lineWidth: 6.0, percent: cat.progress,
                  center: finished 
                    ? const Icon(Icons.check, color: Colors.orange) 
                    : (missed ? const Icon(Icons.close, color: Colors.red) : Text("${(cat.progress * 100).toInt()}%")),
                  progressColor: finished ? Colors.orange : (missed ? Colors.red : const Color(0xFF30A14E)),
                  backgroundColor: provider.isDarkMode ? Colors.white10 : Colors.black12,
                ),
                const Spacer(),
                if (cat.dailyDeadline != null && !finished)
                   Padding(
                     padding: const EdgeInsets.only(bottom: 4),
                     child: Text("⏰ ${DateFormat.jm().format(cat.dailyDeadline!)}", 
                        style: TextStyle(
                          fontSize: 9, 
                          color: missed ? Colors.red : Colors.grey, 
                          fontWeight: FontWeight.bold
                        )),
                   ),
                Text(
                  finished 
                    ? "Finished 🔥" 
                    : (missed ? "Deadline Missed ❌" : cat.durationType.toUpperCase()), 
                  style: TextStyle(
                    fontSize: 10, 
                    color: finished ? Colors.orange : (missed ? Colors.red : Colors.grey),
                    fontWeight: missed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context, TaskProvider provider) {
    final formKey = GlobalKey<FormState>();
    String title = "";
    String type = 'day';
    int days = 1;
    int target = 1;
    
    bool hasDeadline = false;
    TimeOfDay selectedTime = const TimeOfDay(hour: 22, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: const Text("New Plan Details"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Plan Name", hintText: "e.g. Solve Problems"),
                   
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), 
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return "Name is required";
                      
                      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return "English letters only (No numbers)";
                      return null;
                    },
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text("Daily Plan (1 Day)")),
                      DropdownMenuItem(value: 'week', child: Text("Weekly (2-7 Days)")),
                      DropdownMenuItem(value: 'month', child: Text("Monthly (8-30 Days)")),
                    ],
                    onChanged: (v) => setLocalState(() {
                      type = v!;
                      days = (type == 'day' ? 1 : (type == 'week' ? 2 : 8));
                    }),
                  ),
                  
                  if (type == 'day') ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Set Deadline?", style: TextStyle(fontSize: 13)),
                        Switch(
                          value: hasDeadline,
                          activeThumbColor: const Color(0xFF216E39),
                          onChanged: (val) => setLocalState(() => hasDeadline = val),
                        ),
                      ],
                    ),
                    if (hasDeadline)
                      TextButton.icon(
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text("Time: ${selectedTime.format(context)}"),
                        onPressed: () async {
                          final time = await showTimePicker(context: context, initialTime: selectedTime);
                          if (time != null) setLocalState(() => selectedTime = time);
                        },
                      ),
                  ],

                  if (type != 'day')
                    TextFormField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(labelText: "Duration (Days)", hintText: type == 'week' ? "2 to 7" : "8 to 30"),
                      validator: (value) {
                        int? val = int.tryParse(value ?? "");
                        if (val == null) return "Enter a number";
                        if (type == 'week' && (val < 2 || val > 7)) return "Must be 2-7";
                        if (type == 'month' && (val < 8 || val > 30)) return "Must be 8-30";
                        return null;
                      },
                      onChanged: (v) => days = int.tryParse(v) ?? 0,
                    ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: "Target Tasks"),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Target is required";
                      if (int.tryParse(value) == null) return "Numbers only!";
                      return null;
                    },
                    onChanged: (v) => target = int.tryParse(v) ?? 1,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  DateTime? deadlineDate;
                  if (type == 'day' && hasDeadline) {
                    final now = DateTime.now();
                    deadlineDate = DateTime(now.year, now.month, now.day, selectedTime.hour, selectedTime.minute);
                  }

                  provider.addCategory(
                    title.trim(), 
                    type, 
                    days, 
                    target, 
                    deadline: deadlineDate
                  );
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF216E39)),
              child: const Text("Create", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TaskProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Plan?"),
        content: const Text("Warning: All progress and tasks will be permanently removed."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(onPressed: () { 
            provider.deleteCategory(id); 
            Navigator.pop(ctx); 
          }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showNameDialog(BuildContext context, TaskProvider p) {
    String name = "";
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      title: const Text("Welcome! Enter Your Name"),
      content: TextField(
        onChanged: (v) => name = v, 
        decoration: const InputDecoration(hintText: "Your name here...")
      ),
      actions: [
        ElevatedButton(onPressed: () { 
          if (name.isNotEmpty) { 
            p.setUserName(name); 
            Navigator.pop(ctx); 
          } 
        }, child: const Text("Let's Start"))
      ],
    ));
  }
}