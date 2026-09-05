import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'models/plant.dart';
import 'models/task.dart';
import 'models/harvest.dart';
import 'models/garden.dart';
import 'providers/plant_provider.dart';
import 'providers/task_provider.dart';
import 'providers/harvest_provider.dart';
import 'providers/garden_provider.dart';
import 'screens/home_screen.dart';
import 'screens/plants_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/harvests_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/plant_detail_screen.dart';
import 'screens/add_edit_plant_screen.dart';
import 'screens/add_edit_task_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  Hive.registerAdapter(PlantAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(HarvestAdapter());
  Hive.registerAdapter(GardenAdapter());
  
  // Open boxes
  await Hive.openBox<Plant>('plants');
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Harvest>('harvests');
  await Hive.openBox<Garden>('gardens');
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlantProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => HarvestProvider()),
        ChangeNotifierProvider(create: (_) => GardenProvider()),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const JardinApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/plants',
      builder: (context, state) => const PlantsScreen(),
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) => const TasksScreen(),
    ),
    GoRoute(
      path: '/harvests',
      builder: (context, state) => const HarvestsScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/plant/:id',
      builder: (context, state) {
        final id = state.pathParams['id']!;
        return PlantDetailScreen(plantId: id);
      },
    ),
    GoRoute(
      path: '/plant/edit/:id',
      builder: (context, state) {
        final id = state.pathParams['id']!;
        return AddEditPlantScreen(plantId: id);
      },
    ),
    GoRoute(
      path: '/plant/add',
      builder: (context, state) => const AddEditPlantScreen(),
    ),
    GoRoute(
      path: '/task/edit/:id',
      builder: (context, state) {
        final id = state.pathParams['id']!;
        return AddEditTaskScreen(taskId: id);
      },
    ),
    GoRoute(
      path: '/task/add',
      builder: (context, state) => const AddEditTaskScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class JardinApp extends StatelessWidget {
  const JardinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gestion du Jardin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
    );
  }
}
