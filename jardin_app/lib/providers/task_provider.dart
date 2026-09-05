import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  final Box<Task> _tasksBox = Hive.box<Task>('tasks');
  
  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  TaskProvider() {
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _tasks = _tasksBox.values.toList();
      _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } catch (e) {
      _error = 'Erreur lors du chargement des tâches: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    try {
      await _tasksBox.put(task.id, task);
      _tasks.add(task);
      _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'ajout de la tâche: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _tasksBox.put(task.id, task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de la tâche: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksBox.delete(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression de la tâche: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> completeTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(
        status: TaskStatus.completed,
        completedDate: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> startTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(
        status: TaskStatus.inProgress,
        startDate: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> cancelTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final updatedTask = task.copyWith(status: TaskStatus.cancelled);
      await updateTask(updatedTask);
    }
  }

  List<Task> getPendingTasks() {
    return _tasks.where((t) => t.status == TaskStatus.pending).toList();
  }

  List<Task> getInProgressTasks() {
    return _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  }

  List<Task> getCompletedTasks() {
    return _tasks.where((t) => t.status == TaskStatus.completed).toList();
  }

  List<Task> getOverdueTasks() {
    return _tasks.where((t) => t.isOverdue).toList();
  }

  List<Task> getHighPriorityTasks() {
    return _tasks.where((t) => t.priority == TaskPriority.high || t.priority == TaskPriority.urgent).toList();
  }

  List<Task> getTasksByPlant(String plantId) {
    return _tasks.where((t) => t.plantId == plantId).toList();
  }

  List<Task> getTasksByGarden(String gardenId) {
    return _tasks.where((t) => t.gardenId == gardenId).toList();
  }

  List<Task> getTasksByType(TaskType type) {
    return _tasks.where((t) => t.type == type).toList();
  }

  List<Task> getTasksByDate(DateTime date) {
    return _tasks.where((t) => 
      t.dueDate.year == date.year && 
      t.dueDate.month == date.month && 
      t.dueDate.day == date.day
    ).toList();
  }

  List<Task> getTasksDueThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    
    return _tasks.where((t) => 
      t.status == TaskStatus.pending &&
      t.dueDate.isAfter(startOfWeek) &&
      t.dueDate.isBefore(endOfWeek)
    ).toList();
  }

  Task? getTaskById(String id) {
    return _tasks.firstWhere((t) => t.id == id);
  }

  List<Task> searchTasks(String query) {
    final lowerQuery = query.toLowerCase();
    return _tasks.where((t) => 
      t.title.toLowerCase().contains(lowerQuery) ||
      (t.description?.toLowerCase().contains(lowerQuery) ?? false) ||
      (t.notes?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  Future<void> refresh() async {
    await _loadTasks();
  }
}
