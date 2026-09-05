import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/garden_provider.dart';
import '../models/task.dart';
import '../utils/theme.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  TaskStatus? _selectedStatus;
  TaskPriority? _selectedPriority;
  TaskType? _selectedType;
  String? _selectedGardenId;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final plantProvider = context.watch<PlantProvider>();
    final gardenProvider = context.watch<GardenProvider>();
    
    final gardens = gardenProvider.gardens;
    
    List<Task> filteredTasks = taskProvider.tasks;
    
    // Apply filters
    if (_selectedStatus != null) {
      filteredTasks = filteredTasks.where((t) => t.status == _selectedStatus).toList();
    }
    
    if (_selectedPriority != null) {
      filteredTasks = filteredTasks.where((t) => t.priority == _selectedPriority).toList();
    }
    
    if (_selectedType != null) {
      filteredTasks = filteredTasks.where((t) => t.type == _selectedType).toList();
    }
    
    if (_selectedGardenId != null) {
      filteredTasks = filteredTasks.where((t) => t.gardenId == _selectedGardenId).toList();
    }
    
    if (_selectedDate != null) {
      filteredTasks = filteredTasks.where((t) => 
        t.dueDate.year == _selectedDate!.year &&
        t.dueDate.month == _selectedDate!.month &&
        t.dueDate.day == _selectedDate!.day
      ).toList();
    }

    // Sort by due date
    filteredTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tâches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildSummaryItem(
                    title: 'Total',
                    value: taskProvider.tasks.length.toString(),
                    icon: Icons.task,
                    color: Colors.blue,
                    context: context,
                  ),
                  const VerticalDivider(),
                  _buildSummaryItem(
                    title: 'En attente',
                    value: taskProvider.getPendingTasks().length.toString(),
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                    context: context,
                  ),
                  const VerticalDivider(),
                  _buildSummaryItem(
                    title: 'En retard',
                    value: taskProvider.getOverdueTasks().length.toString(),
                    icon: Icons.warning,
                    color: Colors.red,
                    context: context,
                  ),
                  const VerticalDivider(),
                  _buildSummaryItem(
                    title: 'Terminées',
                    value: taskProvider.getCompletedTasks().length.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
          
          // Filter chips
          if (_selectedStatus != null || _selectedPriority != null || 
              _selectedType != null || _selectedGardenId != null || _selectedDate != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildFilterChips(context),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Tasks list
          Expanded(
            child: taskProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune tâche trouvée',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez de modifier vos filtres ou ajoutez une nouvelle tâche',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
                          return _buildTaskCard(task, context);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => context.push('/task/add'),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, BuildContext context) {
    final plantProvider = context.read<PlantProvider>();
    final gardenProvider = context.read<GardenProvider>();
    
    final plantName = task.plantId != null 
        ? plantProvider.getPlantById(task.plantId!)?.name 
        : null;
    final gardenName = task.gardenId != null 
        ? gardenProvider.getGardenById(task.gardenId!)?.name 
        : null;
    
    final isOverdue = task.isOverdue;
    final daysUntilDue = task.daysUntilDue;

    return Slidable(
      key: ValueKey(task.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (task.status == TaskStatus.pending)
            SlidableAction(
              onPressed: (_) => _startTask(task.id, context),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.play_arrow,
              label: 'Démarrer',
            ),
          if (task.status == TaskStatus.inProgress)
            SlidableAction(
              onPressed: (_) => _completeTask(task.id, context),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: Icons.check,
              label: 'Terminer',
            ),
          SlidableAction(
            onPressed: (_) => context.push('/task/edit/${task.id}'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDeleteTask(task, context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 2,
        color: isOverdue ? Colors.red.withOpacity(0.1) : null,
        child: InkWell(
          onTap: () => context.push('/task/edit/${task.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task icon and priority
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.taskPriorityColors[task.priority]?.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.taskPriorityColors[task.priority] ?? Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        task.type.icon,
                        color: AppTheme.taskPriorityColors[task.priority],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Task info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isOverdue ? Colors.red : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOverdue)
                                const Icon(Icons.warning, color: Colors.red, size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Task details
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Échéance: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(task.dueDate)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (daysUntilDue > 0) ...[
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$daysUntilDue jours',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                              if (daysUntilDue < 0) ...[
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${-daysUntilDue} jours en retard',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          // Plant and garden info
                          if (plantName != null || gardenName != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (plantName != null) ...[
                                  Icon(Icons.eco, size: 16, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    plantName,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (gardenName != null) ...[
                                    const SizedBox(width: 16),
                                    Icon(Icons.nature, size: 16, color: Colors.brown),
                                    const SizedBox(width: 4),
                                    Text(
                                      gardenName,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ] else if (gardenName != null) ...[
                                  Icon(Icons.nature, size: 16, color: Colors.brown),
                                  const SizedBox(width: 4),
                                  Text(
                                    gardenName,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ],
                          
                          // Task description
                          if (task.description != null && task.description!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              task.description!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Status and actions
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.taskStatusColors[task.status]?.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.taskStatusColors[task.status] ?? Colors.grey,
                        ),
                      ),
                      child: Text(
                        task.status.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.taskStatusColors[task.status],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    final chips = <Widget>[];
    
    if (_selectedStatus != null) {
      chips.add(
        FilterChip(
          label: Text(_selectedStatus!.displayName),
          selected: true,
          onSelected: (_) => setState(() => _selectedStatus = null),
          avatar: Icon(Icons.flag, size: 18),
        ),
      );
    }
    
    if (_selectedPriority != null) {
      chips.add(
        FilterChip(
          label: Text(_selectedPriority!.displayName),
          selected: true,
          onSelected: (_) => setState(() => _selectedPriority = null),
          avatar: Icon(Icons.priority_high, size: 18),
        ),
      );
    }
    
    if (_selectedType != null) {
      chips.add(
        FilterChip(
          label: Text(_selectedType!.displayName),
          selected: true,
          onSelected: (_) => setState(() => _selectedType = null),
          avatar: Icon(_selectedType!.icon, size: 18),
        ),
      );
    }
    
    if (_selectedGardenId != null) {
      final garden = context.read<GardenProvider>().getGardenById(_selectedGardenId!);
      if (garden != null) {
        chips.add(
          FilterChip(
            label: Text(garden.name),
            selected: true,
            onSelected: (_) => setState(() => _selectedGardenId = null),
            avatar: Icon(garden.type.icon, size: 18),
          ),
        );
      }
    }
    
    if (_selectedDate != null) {
      chips.add(
        FilterChip(
          label: Text(DateFormat('dd/MM/yyyy', 'fr_FR').format(_selectedDate!)),
          selected: true,
          onSelected: (_) => setState(() => _selectedDate = null),
          avatar: const Icon(Icons.calendar_today, size: 18),
        ),
      );
    }
    
    return chips;
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterSheet(context),
    );
  }

  Widget _buildFilterSheet(BuildContext context) {
    final gardenProvider = context.read<GardenProvider>();
    final gardens = gardenProvider.gardens;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtrer les tâches',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Status filter
          Text(
            'Statut',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskStatus.values.map((status) => FilterChip(
              label: Text(status.displayName),
              selected: _selectedStatus == status,
              onSelected: (selected) => setState(() {
                _selectedStatus = selected ? status : null;
              }),
            )).toList(),
          ),
          const SizedBox(height: 16),
          
          // Priority filter
          Text(
            'Priorité',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskPriority.values.map((priority) => FilterChip(
              label: Text(priority.displayName),
              selected: _selectedPriority == priority,
              onSelected: (selected) => setState(() {
                _selectedPriority = selected ? priority : null;
              }),
            )).toList(),
          ),
          const SizedBox(height: 16),
          
          // Type filter
          Text(
            'Type de tâche',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskType.values.map((type) => FilterChip(
              label: Text(type.displayName),
              selected: _selectedType == type,
              onSelected: (selected) => setState(() {
                _selectedType = selected ? type : null;
              }),
              avatar: Icon(type.icon, size: 18),
            )).toList(),
          ),
          const SizedBox(height: 16),
          
          // Garden filter
          Text(
            'Jardin',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (gardens.isEmpty) ...[
            Text(
              'Aucun jardin créé',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tous les jardins'),
                  selected: _selectedGardenId == null,
                  onSelected: (_) => setState(() => _selectedGardenId = null),
                ),
                ...gardens.map((garden) => FilterChip(
                  label: Text(garden.name),
                  selected: _selectedGardenId == garden.id,
                  onSelected: (selected) => setState(() {
                    _selectedGardenId = selected ? garden.id : null;
                  }),
                  avatar: Icon(garden.type.icon, size: 18),
                )),
              ],
            ),
          ],
          const SizedBox(height: 16),
          
          // Date filter
          Text(
            'Date d\'échéance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDate != null 
                        ? DateFormat('dd/MM/yyyy', 'fr_FR').format(_selectedDate!)
                        : 'Sélectionner une date',
                  ),
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedDate = null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = null;
                    _selectedPriority = null;
                    _selectedType = null;
                    _selectedGardenId = null;
                    _selectedDate = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Réinitialiser'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startTask(String taskId, BuildContext context) {
    context.read<TaskProvider>().startTask(taskId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tâche démarrée'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _completeTask(String taskId, BuildContext context) {
    context.read<TaskProvider>().completeTask(taskId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tâche terminée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _confirmDeleteTask(Task task, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${task.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TaskProvider>().deleteTask(task.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${task.title}" a été supprimée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
