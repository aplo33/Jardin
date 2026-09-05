import 'package:hive/hive.dart';

enum TaskType {
  watering,
  pruning,
  fertilizing,
  harvesting,
  planting,
  weeding,
  pestControl,
  other,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

enum TaskStatus {
  pending,
  inProgress,
  completed,
  cancelled,
}

@HiveType(typeId: 1)
class Task {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final TaskType type;
  
  @HiveField(4)
  final TaskPriority priority;
  
  @HiveField(5)
  final TaskStatus status;
  
  @HiveField(6)
  final DateTime dueDate;
  
  @HiveField(7)
  final DateTime? startDate;
  
  @HiveField(8)
  final DateTime? completedDate;
  
  @HiveField(9)
  final String? plantId;
  
  @HiveField(10)
  final String? gardenId;
  
  @HiveField(11)
  final bool isRecurring;
  
  @HiveField(12)
  final int? recurrenceInterval;
  
  @HiveField(13)
  final String? recurrenceUnit;
  
  @HiveField(14)
  final bool hasReminder;
  
  @HiveField(15)
  final DateTime? reminderDate;
  
  @HiveField(16)
  final String? notes;
  
  @HiveField(17)
  final DateTime createdAt;
  
  @HiveField(18)
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.type = TaskType.other,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    required this.dueDate,
    this.startDate,
    this.completedDate,
    this.plantId,
    this.gardenId,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.recurrenceUnit,
    this.hasReminder = false,
    this.reminderDate,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? completedDate,
    String? plantId,
    String? gardenId,
    bool? isRecurring,
    int? recurrenceInterval,
    String? recurrenceUnit,
    bool? hasReminder,
    DateTime? reminderDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      startDate: startDate ?? this.startDate,
      completedDate: completedDate ?? this.completedDate,
      plantId: plantId ?? this.plantId,
      gardenId: gardenId ?? this.gardenId,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceUnit: recurrenceUnit ?? this.recurrenceUnit,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderDate: reminderDate ?? this.reminderDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.index,
      'priority': priority.index,
      'status': status.index,
      'dueDate': dueDate.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'plantId': plantId,
      'gardenId': gardenId,
      'isRecurring': isRecurring,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceUnit': recurrenceUnit,
      'hasReminder': hasReminder,
      'reminderDate': reminderDate?.toIso8601String(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      type: TaskType.values[map['type'] ?? 4],
      priority: TaskPriority.values[map['priority'] ?? 1],
      status: TaskStatus.values[map['status'] ?? 0],
      dueDate: DateTime.parse(map['dueDate']),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      completedDate: map['completedDate'] != null ? DateTime.parse(map['completedDate']) : null,
      plantId: map['plantId'],
      gardenId: map['gardenId'],
      isRecurring: map['isRecurring'] ?? false,
      recurrenceInterval: map['recurrenceInterval'],
      recurrenceUnit: map['recurrenceUnit'],
      hasReminder: map['hasReminder'] ?? false,
      reminderDate: map['reminderDate'] != null ? DateTime.parse(map['reminderDate']) : null,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  bool get isOverdue => 
      status == TaskStatus.pending && 
      dueDate.isBefore(DateTime.now());

  int get daysUntilDue {
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    return diff.inDays;
  }
}

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 1;

  @override
  Task read(BinaryReader reader) {
    return Task(
      id: reader.readString(),
      title: reader.readString(),
      description: reader.readString(),
      type: TaskType.values[reader.readByte()],
      priority: TaskPriority.values[reader.readByte()],
      status: TaskStatus.values[reader.readByte()],
      dueDate: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      startDate: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      completedDate: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      plantId: reader.readString(),
      gardenId: reader.readString(),
      isRecurring: reader.readBool(),
      recurrenceInterval: reader.readBool() ? reader.readInt() : null,
      recurrenceUnit: reader.readString(),
      hasReminder: reader.readBool(),
      reminderDate: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      notes: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.title);
    writer.writeString(obj.description ?? '');
    writer.writeByte(obj.type.index);
    writer.writeByte(obj.priority.index);
    writer.writeByte(obj.status.index);
    writer.writeInt(obj.dueDate.millisecondsSinceEpoch);
    writer.writeBool(obj.startDate != null);
    if (obj.startDate != null) {
      writer.writeInt(obj.startDate!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.completedDate != null);
    if (obj.completedDate != null) {
      writer.writeInt(obj.completedDate!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.plantId ?? '');
    writer.writeString(obj.gardenId ?? '');
    writer.writeBool(obj.isRecurring);
    writer.writeBool(obj.recurrenceInterval != null);
    if (obj.recurrenceInterval != null) {
      writer.writeInt(obj.recurrenceInterval!);
    }
    writer.writeString(obj.recurrenceUnit ?? '');
    writer.writeBool(obj.hasReminder);
    writer.writeBool(obj.reminderDate != null);
    if (obj.reminderDate != null) {
      writer.writeInt(obj.reminderDate!.millisecondsSinceEpoch);
    }
    writer.writeString(obj.notes ?? '');
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
