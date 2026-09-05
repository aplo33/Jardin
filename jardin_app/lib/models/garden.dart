import 'package:hive/hive.dart';

enum GardenType {
  vegetableGarden,
  flowerGarden,
  orchard,
  greenhouse,
  mixed,
}

@HiveType(typeId: 3)
class Garden {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final GardenType type;
  
  @HiveField(4)
  final double area;
  
  @HiveField(5)
  final String? location;
  
  @HiveField(6)
  final String? imagePath;
  
  @HiveField(7)
  final bool isActive;
  
  @HiveField(8)
  final DateTime createdAt;
  
  @HiveField(9)
  final DateTime updatedAt;

  Garden({
    required this.id,
    required this.name,
    this.description,
    this.type = GardenType.vegetableGarden,
    this.area = 0.0,
    this.location,
    this.imagePath,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Garden copyWith({
    String? id,
    String? name,
    String? description,
    GardenType? type,
    double? area,
    String? location,
    String? imagePath,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Garden(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      area: area ?? this.area,
      location: location ?? this.location,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'area': area,
      'location': location,
      'imagePath': imagePath,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Garden.fromMap(Map<String, dynamic> map) {
    return Garden(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      type: GardenType.values[map['type'] ?? 0],
      area: map['area']?.toDouble() ?? 0.0,
      location: map['location'],
      imagePath: map['imagePath'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

class GardenAdapter extends TypeAdapter<Garden> {
  @override
  final int typeId = 3;

  @override
  Garden read(BinaryReader reader) {
    return Garden(
      id: reader.readString(),
      name: reader.readString(),
      description: reader.readString(),
      type: GardenType.values[reader.readByte()],
      area: reader.readDouble(),
      location: reader.readString(),
      imagePath: reader.readString(),
      isActive: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Garden obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.description ?? '');
    writer.writeByte(obj.type.index);
    writer.writeDouble(obj.area);
    writer.writeString(obj.location ?? '');
    writer.writeString(obj.imagePath ?? '');
    writer.writeBool(obj.isActive);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
