import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/harvest_provider.dart';
import '../models/task.dart';
import '../models/plant.dart';
import '../models/harvest.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final plantProvider = context.watch<PlantProvider>();
    final harvestProvider = context.watch<HarvestProvider>();

    // Get tasks and harvests for the current month
    final tasks = taskProvider.tasks;
    final harvests = harvestProvider.harvests;
    
    // Group tasks by date
    final tasksByDate = <DateTime, List<Task>>{};
    for (var task in tasks) {
      final date = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      tasksByDate.update(date, (list) => [...list, task], ifAbsent: () => [task]);
    }
    
    // Group harvests by date
    final harvestsByDate = <DateTime, List<Harvest>>{};
    for (var harvest in harvests) {
      final date = DateTime(harvest.harvestDate.year, harvest.harvestDate.month, harvest.harvestDate.day);
      harvestsByDate.update(date, (list) => [...list, harvest], ifAbsent: () => [harvest]);
    }
    
    // Get planting and harvest dates from plants
    final plantingDates = <DateTime, List<Plant>>{};
    final harvestDates = <DateTime, List<Plant>>{};
    for (var plant in plantProvider.plants) {
      if (plant.plantingDate != null) {
        final date = DateTime(plant.plantingDate!.year, plant.plantingDate!.month, plant.plantingDate!.day);
        plantingDates.update(date, (list) => [...list, plant], ifAbsent: () => [plant]);
      }
      if (plant.harvestDate != null) {
        final date = DateTime(plant.harvestDate!.year, plant.harvestDate!.month, plant.harvestDate!.day);
        harvestDates.update(date, (list) => [...list, plant], ifAbsent: () => [plant]);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () => setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // Check if there are any events for this date
                final hasTasks = tasksByDate[date] != null;
                final hasHarvests = harvestsByDate[date] != null;
                final hasPlantings = plantingDates[date] != null;
                final hasPlantHarvests = harvestDates[date] != null;
                
                if (!hasTasks && !hasHarvests && !hasPlantings && !hasPlantHarvests) {
                  return null;
                }
                
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasTasks ? Colors.red : 
                             hasHarvests ? Colors.green : 
                             hasPlantings || hasPlantHarvests ? Colors.blue : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
              todayBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                );
              },
              selectedBuilder: (context, date, _) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: const Icon(Icons.chevron_left),
              rightChevronIcon: const Icon(Icons.chevron_right),
            ),
            calendarStyle: CalendarStyle(
              cellMargin: const EdgeInsets.all(4),
              todayDecoration: const BoxDecoration(),
              selectedDecoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Events for selected day
          if (_selectedDay != null) ...[
            Expanded(
              child: _buildDayEvents(
                date: _selectedDay!,
                tasks: tasksByDate[_selectedDay] ?? [],
                harvests: harvestsByDate[_selectedDay] ?? [],
                plantings: plantingDates[_selectedDay] ?? [],
                plantHarvests: harvestDates[_selectedDay] ?? [],
                context: context,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayEvents({
    required DateTime date,
    required List<Task> tasks,
    required List<Harvest> harvests,
    required List<Plant> plantings,
    required List<Plant> plantHarvests,
    required BuildContext context,
  }) {
    final hasEvents = tasks.isNotEmpty || harvests.isNotEmpty || 
                     plantings.isNotEmpty || plantHarvests.isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          if (!hasEvents) ...[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.calendar_today, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun événement pour cette date',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ] else ...[
            // Tasks
            if (tasks.isNotEmpty) ...[
              _buildEventSection(
                title: 'Tâches (${tasks.length})',
                icon: Icons.task,
                color: Colors.red,
                children: tasks.map((task) => _buildTaskEvent(task, context)).toList(),
                context: context,
              ),
              const SizedBox(height: 16),
            ],
            
            // Harvests
            if (harvests.isNotEmpty) ...[
              _buildEventSection(
                title: 'Récoltes (${harvests.length})',
                icon: Icons.agriculture,
                color: Colors.green,
                children: harvests.map((harvest) => _buildHarvestEvent(harvest, context)).toList(),
                context: context,
              ),
              const SizedBox(height: 16),
            ],
            
            // Plantings
            if (plantings.isNotEmpty) ...[
              _buildEventSection(
                title: 'Plantations (${plantings.length})',
                icon: Icons.grass,
                color: Colors.blue,
                children: plantings.map((plant) => _buildPlantingEvent(plant, context)).toList(),
                context: context,
              ),
              const SizedBox(height: 16),
            ],
            
            // Plant harvests
            if (plantHarvests.isNotEmpty) ...[
              _buildEventSection(
                title: 'Récoltes de plantes (${plantHarvests.length})',
                icon: Icons.eco,
                color: Colors.purple,
                children: plantHarvests.map((plant) => _buildPlantHarvestEvent(plant, context)).toList(),
                context: context,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEventSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskEvent(Task task, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.taskPriorityColors[task.priority]?.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            task.type.icon,
            color: AppTheme.taskPriorityColors[task.priority],
            size: 20,
          ),
        ),
        title: Text(task.title),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.taskStatusColors[task.status]?.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.status.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.taskStatusColors[task.status],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('HH:mm', 'fr_FR').format(task.dueDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => context.push('/task/edit/${task.id}'),
        ),
        onTap: () => context.push('/task/edit/${task.id}'),
        dense: true,
      ),
    );
  }

  Widget _buildHarvestEvent(Harvest harvest, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.agriculture, color: Colors.green, size: 20),
        ),
        title: Text(harvest.plantName),
        subtitle: Text('${harvest.quantity} ${harvest.unit}'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            // TODO: Navigate to harvest detail
          },
        ),
        dense: true,
      ),
    );
  }

  Widget _buildPlantingEvent(Plant plant, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.plantTypeColors[plant.type]?.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            plant.type.icon,
            color: AppTheme.plantTypeColors[plant.type],
            size: 20,
          ),
        ),
        title: Text(plant.name),
        subtitle: Text(plant.scientificName ?? plant.type.displayName),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => context.push('/plant/${plant.id}'),
        ),
        onTap: () => context.push('/plant/${plant.id}'),
        dense: true,
      ),
    );
  }

  Widget _buildPlantHarvestEvent(Plant plant, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.agriculture, color: Colors.purple, size: 20),
        ),
        title: Text(plant.name),
        subtitle: Text('Récolte prévue'),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () => context.push('/plant/${plant.id}'),
        ),
        onTap: () => context.push('/plant/${plant.id}'),
        dense: true,
      ),
    );
  }
}
