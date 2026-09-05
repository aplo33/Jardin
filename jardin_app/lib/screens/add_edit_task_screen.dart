import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/task_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/garden_provider.dart';
import '../models/task.dart';
import '../models/plant.dart';
import '../models/garden.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddEditTaskScreen extends StatefulWidget {
  final String? taskId;

  const AddEditTaskScreen({super.key, this.taskId});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _id;
  late String _title;
  String? _description;
  late TaskType _type;
  late TaskPriority _priority;
  late TaskStatus _status;
  late DateTime _dueDate;
  DateTime? _startDate;
  DateTime? _completedDate;
  String? _plantId;
  String? _gardenId;
  late bool _isRecurring;
  int? _recurrenceInterval;
  String? _recurrenceUnit;
  late bool _hasReminder;
  DateTime? _reminderDate;
  String? _notes;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _recurrenceIntervalController = TextEditingController();
  final TextEditingController _recurrenceUnitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeTask();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _recurrenceIntervalController.dispose();
    _recurrenceUnitController.dispose();
    super.dispose();
  }

  void _initializeTask() {
    final taskProvider = context.read<TaskProvider>();
    final gardenProvider = context.read<GardenProvider>();
    
    if (widget.taskId != null) {
      final task = taskProvider.getTaskById(widget.taskId!);
      if (task != null) {
        _id = task.id;
        _title = task.title;
        _description = task.description;
        _type = task.type;
        _priority = task.priority;
        _status = task.status;
        _dueDate = task.dueDate;
        _startDate = task.startDate;
        _completedDate = task.completedDate;
        _plantId = task.plantId;
        _gardenId = task.gardenId;
        _isRecurring = task.isRecurring;
        _recurrenceInterval = task.recurrenceInterval;
        _recurrenceUnit = task.recurrenceUnit;
        _hasReminder = task.hasReminder;
        _reminderDate = task.reminderDate;
        _notes = task.notes;
        
        _titleController.text = _title;
        _descriptionController.text = _description ?? '';
        _notesController.text = _notes ?? '';
        _recurrenceIntervalController.text = _recurrenceInterval?.toString() ?? '';
        _recurrenceUnitController.text = _recurrenceUnit ?? '';
      } else {
        _initializeNewTask(gardenProvider);
      }
    } else {
      _initializeNewTask(gardenProvider);
    }
  }

  void _initializeNewTask(GardenProvider gardenProvider) {
    _id = const Uuid().v4();
    _title = '';
    _description = null;
    _type = TaskType.watering;
    _priority = TaskPriority.medium;
    _status = TaskStatus.pending;
    _dueDate = DateTime.now().add(const Duration(days: 1));
    _startDate = null;
    _completedDate = null;
    _plantId = null;
    _gardenId = gardenProvider.currentGarden?.id;
    _isRecurring = false;
    _recurrenceInterval = null;
    _recurrenceUnit = null;
    _hasReminder = true;
    _reminderDate = null;
    _notes = null;
  }

  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();
    final gardenProvider = context.watch<GardenProvider>();
    final gardens = gardenProvider.gardens;
    final plants = plantProvider.getActivePlants();
    final isEditing = widget.taskId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la tâche' : 'Ajouter une tâche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information
              _buildSectionHeader('Informations de base', Icons.info),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre *',
                          hintText: 'Ex: Arroser les tomates, Tailler les rosiers',
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un titre';
                          }
                          return null;
                        },
                        onChanged: (value) => _title = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Description détaillée de la tâche',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        onChanged: (value) => _description = value.isEmpty ? null : value,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TaskType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: TaskType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, color: AppTheme.taskTypeColors[type]),
                              const SizedBox(width: 8),
                              Text(type.displayName),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _type = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<TaskPriority>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Priorité',
                          prefixIcon: Icon(Icons.priority_high),
                        ),
                        items: TaskPriority.values.map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: AppTheme.taskPriorityColors[priority],
                              ),
                              const SizedBox(width: 8),
                              Text(priority.displayName),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _priority = value!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Assignment
              _buildSectionHeader('Attribution', Icons.assignment),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Garden
                      if (gardens.isEmpty) ...[
                        Text(
                          'Aucun jardin créé. Créez un jardin d\'abord.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez créer un jardin d\'abord'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Créer un jardin'),
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          value: _gardenId,
                          decoration: const InputDecoration(
                            labelText: 'Jardin',
                            prefixIcon: Icon(Icons.nature),
                          ),
                          hint: const Text('Sélectionnez un jardin'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Aucun jardin'),
                            ),
                            ...gardens.map((garden) => DropdownMenuItem(
                              value: garden.id,
                              child: Row(
                                children: [
                                  Icon(garden.type.icon, color: AppTheme.gardenTypeColors[garden.type]),
                                  const SizedBox(width: 8),
                                  Text(garden.name),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (value) => setState(() => _gardenId = value),
                        ),
                      ],
                      const SizedBox(height: 16),
                      
                      // Plant
                      if (plants.isEmpty) ...[
                        Text(
                          'Aucune plante active disponible',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          value: _plantId,
                          decoration: const InputDecoration(
                            labelText: 'Plante',
                            prefixIcon: Icon(Icons.eco),
                          ),
                          hint: const Text('Sélectionnez une plante'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Aucune plante'),
                            ),
                            ...plants.map((plant) => DropdownMenuItem(
                              value: plant.id,
                              child: Row(
                                children: [
                                  Icon(plant.type.icon, color: AppTheme.plantTypeColors[plant.type]),
                                  const SizedBox(width: 8),
                                  Text(plant.name),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (value) => setState(() => _plantId = value),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Dates
              _buildSectionHeader('Dates', Icons.calendar_today),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Date d\'échéance *',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        controller: TextEditingController(
                          text: DateFormat('dd/MM/yyyy – HH:mm', 'fr_FR').format(_dueDate),
                        ),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            locale: const Locale('fr', 'FR'),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_dueDate),
                            );
                            if (time != null) {
                              setState(() {
                                _dueDate = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                              });
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      if (_startDate != null) ...[
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Date de début',
                            prefixIcon: Icon(Icons.play_arrow),
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: DateFormat('dd/MM/yyyy – HH:mm', 'fr_FR').format(_startDate!),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate!,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: _dueDate,
                              locale: const Locale('fr', 'FR'),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_startDate!),
                              );
                              if (time != null) {
                                setState(() {
                                  _startDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _startDate = null),
                        ),
                      ],
                      
                      if (_completedDate != null) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Date de complétion',
                            prefixIcon: Icon(Icons.check_circle),
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: DateFormat('dd/MM/yyyy – HH:mm', 'fr_FR').format(_completedDate!),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recurrence
              _buildSectionHeader('Répétition', Icons.repeat),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Tâche récurrente'),
                        value: _isRecurring,
                        onChanged: (value) => setState(() => _isRecurring = value),
                        secondary: const Icon(Icons.repeat),
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _recurrenceIntervalController,
                                decoration: const InputDecoration(
                                  labelText: 'Intervalle',
                                  hintText: 'Ex: 7',
                                  prefixIcon: Icon(Icons.numbers),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) => _recurrenceInterval = value.isEmpty ? null : int.tryParse(value),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _recurrenceUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unité',
                                  prefixIcon: Icon(Icons.unit),
                                ),
                                items: ['jours', 'semaines', 'mois'].map((unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                )).toList(),
                                onChanged: (value) => setState(() => _recurrenceUnit = value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Reminders
              _buildSectionHeader('Rappels', Icons.notifications),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Activer le rappel'),
                        value: _hasReminder,
                        onChanged: (value) => setState(() => _hasReminder = value),
                        secondary: const Icon(Icons.notifications_active),
                      ),
                      if (_hasReminder) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Date du rappel',
                            prefixIcon: Icon(Icons.alarm),
                          ),
                          readOnly: true,
                          controller: TextEditingController(
                            text: _reminderDate != null 
                                ? DateFormat('dd/MM/yyyy – HH:mm', 'fr_FR').format(_reminderDate!) 
                                : '',
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _reminderDate ?? _dueDate,
                              firstDate: DateTime.now(),
                              lastDate: _dueDate,
                              locale: const Locale('fr', 'FR'),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _reminderDate != null 
                                    ? TimeOfDay.fromDateTime(_reminderDate!) 
                                    : TimeOfDay.fromDateTime(_dueDate),
                              );
                              if (time != null) {
                                setState(() {
                                  _reminderDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status
              _buildSectionHeader('Statut', Icons.settings),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<TaskStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: TaskStatus.values.map((status) => DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: AppTheme.taskStatusColors[status],
                              ),
                              const SizedBox(width: 8),
                              Text(status.displayName),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _status = value!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              _buildSectionHeader('Notes', Icons.notes),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes supplémentaires',
                      hintText: 'Toute information supplémentaire sur la tâche',
                      prefixIcon: Icon(Icons.notes),
                      border: InputBorder.none,
                    ),
                    maxLines: 4,
                    onChanged: (value) => _notes = value.isEmpty ? null : value,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: _saveTask,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save),
                        const SizedBox(width: 8),
                        Text(isEditing ? 'Enregistrer les modifications' : 'Ajouter la tâche'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If task is completed but no completion date, set it to now
    DateTime? completedDate = _completedDate;
    if (_status == TaskStatus.completed && completedDate == null) {
      completedDate = DateTime.now();
    }
    
    // If task is in progress but no start date, set it to now
    DateTime? startDate = _startDate;
    if (_status == TaskStatus.inProgress && startDate == null) {
      startDate = DateTime.now();
    }

    final task = Task(
      id: _id,
      title: _title,
      description: _description,
      type: _type,
      priority: _priority,
      status: _status,
      dueDate: _dueDate,
      startDate: startDate,
      completedDate: completedDate,
      plantId: _plantId,
      gardenId: _gardenId,
      isRecurring: _isRecurring,
      recurrenceInterval: _recurrenceInterval,
      recurrenceUnit: _recurrenceUnit,
      hasReminder: _hasReminder,
      reminderDate: _reminderDate,
      notes: _notes,
    );

    try {
      final taskProvider = context.read<TaskProvider>();
      final notificationService = context.read<NotificationService>();
      
      if (widget.taskId != null) {
        await taskProvider.updateTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${task.title}" a été mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await taskProvider.addTask(task);
        
        // Schedule notification if reminder is enabled
        if (_hasReminder) {
          await notificationService.showTaskReminderNotification(task);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${task.title}" a été ajoutée'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
