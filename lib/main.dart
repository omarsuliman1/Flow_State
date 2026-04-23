import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/task_provider.dart';
import './services/notification_service.dart';
import './screens/dashboard_screen.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized();

   final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const FlowStateApp(),
    ),
  );
}

class FlowStateApp extends StatelessWidget {
  const FlowStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);

    return MaterialApp(
      title: 'Flow State',
      debugShowCheckedModeBanner: false,
       themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
        ),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF30A14E),
          secondary: Colors.orange,
        ),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: Colors.black,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF216E39),
          secondary: Colors.orange,
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
