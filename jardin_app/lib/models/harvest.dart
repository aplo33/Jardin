import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class Harvest {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String plantId;
  
  @HiveField(2)
  final String plantName;
  
  @HiveField(3)
  final DateTime harvestDate;
  
  @HiveField(4)
  final double quantity;
  
  @HiveField(5)
  final String unit;
  
  @HiveField(6)
  final String? notes;
  
  @HiveField(7)
  final String? quality;
  
  @HiveField(8)
  final String? imagePath;
  
  @HiveField(9)
  final String? gardenId;
  
  @HiveField(10)
  final DateTime createdAt;
  
  @HiveField(11)
  final DateTime updatedAt;

  Harvest({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.harvestDate,
    required this.quantity,
    required this.unit,
    this.notes,
    this.quality,
    this.imagePath,
    this.gardenId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Harvest copyWith({
    String? id,
    String? plantId,
    String? plantName,
    DateTime? harvestDate,
    double? quantity,
    String? unit,
    String? notes,
    String? quality,
    String? imagePath,
    String? gardenId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Harvest(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      plantName: plantName ?? this.plantName,
      harvestDate: harvestDate ?? this.harvestDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      quality: quality ?? this.quality,
      imagePath: imagePath ?? this.imagePath,
      gardenId: gardenId ?? this.gardenId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantId': plantId,
      'plantName': plantName,
      'harvestDate': harvestDate.toIso8601String(),
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'quality': quality,
      'imagePath': imagePath,
      'gardenId': gardenId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Harvest.fromMap(Map<String, dynamic> map) {
    return Harvest(
      id: map['id'] ?? '',
      plantId: map['plantId'] ?? '',
      plantName: map['plantName'] ?? '',
      harvestDate: DateTime.parse(map['harvestDate']),
      quantity: map['quantity']?.toDouble() ?? 0.0,
      unit: map['unit'] ?? '',
      notes: map['notes'],
      quality: map['quality'],
      imagePath: map['imagePath'],
      gardenId: map['gardenId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

class HarvestAdapter extends TypeAdapter<Harvest> {
  @override
  final int typeId = 2;

  @override
  Harvest read(BinaryReader reader) {
    return Harvest(
      id: reader.readString(),
      plantId: reader.readString(),
      plantName: reader.readString(),
      harvestDate: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      quantity: reader.readDouble(),
      unit: reader.readString(),
      notes: reader.readString(),
      quality: reader.readString(),
      imagePath: reader.readString(),
      gardenId: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Harvest obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.plantId);
    writer.writeString(obj.plantName);
    writer.writeInt(obj.harvestDate.millisecondsSinceEpoch);
    writer.writeDouble(obj.quantity);
    writer.writeString(obj.unit);
    writer.writeString(obj.notes ?? '');
    writer.writeString(obj.quality ?? '');
    writer.writeString(obj.imagePath ?? '');
    writer.writeString(obj.gardenId ?? '');
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
