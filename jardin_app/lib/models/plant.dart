import 'package:hive/hive.dart';

enum PlantType {
  vegetable,
  fruit,
  herb,
  flower,
  tree,
  shrub,
}

enum PlantCategory {
  legume,
  fruit,
  aromatique,
  fleur,
  agrume,
  berry,
  salade,
  racine,
  autre,
}

enum SunExposure {
  fullSun,
  partialShade,
  fullShade,
}

enum WaterNeed {
  low,
  medium,
  high,
}

enum SoilType {
  clay,
  sandy,
  loamy,
  chalky,
  peaty,
  silty,
}

@HiveType(typeId: 0)
class Plant {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? scientificName;
  
  @HiveField(3)
  final String? description;
  
  @HiveField(4)
  final PlantType type;
  
  @HiveField(5)
  final List<PlantCategory> categories;
  
  @HiveField(6)
  final String? imagePath;
  
  @HiveField(7)
  final DateTime? plantingDate;
  
  @HiveField(8)
  final DateTime? harvestDate;
  
  @HiveField(9)
  final int? daysToMaturity;
  
  @HiveField(10)
  final SunExposure sunExposure;
  
  @HiveField(11)
  final WaterNeed waterNeed;
  
  @HiveField(12)
  final SoilType soilType;
  
  @HiveField(13)
  final double? idealPh;
  
  @HiveField(14)
  final double? spacing;
  
  @HiveField(15)
  final double? depth;
  
  @HiveField(16)
  final String? companionPlants;
  
  @HiveField(17)
  final String? avoidPlants;
  
  @HiveField(18)
  final String? careInstructions;
  
  @HiveField(19)
  final String? harvestInstructions;
  
  @HiveField(20)
  final bool isFavorite;
  
  @HiveField(21)
  final bool isActive;
  
  @HiveField(22)
  final DateTime createdAt;
  
  @HiveField(23)
  final DateTime updatedAt;
  
  @HiveField(24)
  final String? gardenId;

  Plant({
    required this.id,
    required this.name,
    this.scientificName,
    this.description,
    required this.type,
    this.categories = const [],
    this.imagePath,
    this.plantingDate,
    this.harvestDate,
    this.daysToMaturity,
    this.sunExposure = SunExposure.fullSun,
    this.waterNeed = WaterNeed.medium,
    this.soilType = SoilType.loamy,
    this.idealPh,
    this.spacing,
    this.depth,
    this.companionPlants,
    this.avoidPlants,
    this.careInstructions,
    this.harvestInstructions,
    this.isFavorite = false,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.gardenId,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Plant copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? description,
    PlantType? type,
    List<PlantCategory>? categories,
    String? imagePath,
    DateTime? plantingDate,
    DateTime? harvestDate,
    int? daysToMaturity,
    SunExposure? sunExposure,
    WaterNeed? waterNeed,
    SoilType? soilType,
    double? idealPh,
    double? spacing,
    double? depth,
    String? companionPlants,
    String? avoidPlants,
    String? careInstructions,
    String? harvestInstructions,
    bool? isFavorite,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gardenId,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      type: type ?? this.type,
      categories: categories ?? this.categories,
      imagePath: imagePath ?? this.imagePath,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      daysToMaturity: daysToMaturity ?? this.daysToMaturity,
      sunExposure: sunExposure ?? this.sunExposure,
      waterNeed: waterNeed ?? this.waterNeed,
      soilType: soilType ?? this.soilType,
      idealPh: idealPh ?? this.idealPh,
      spacing: spacing ?? this.spacing,
      depth: depth ?? this.depth,
      companionPlants: companionPlants ?? this.companionPlants,
      avoidPlants: avoidPlants ?? this.avoidPlants,
      careInstructions: careInstructions ?? this.careInstructions,
      harvestInstructions: harvestInstructions ?? this.harvestInstructions,
      isFavorite: isFavorite ?? this.isFavorite,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      gardenId: gardenId ?? this.gardenId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'type': type.index,
      'categories': categories.map((c) => c.index).toList(),
      'imagePath': imagePath,
      'plantingDate': plantingDate?.toIso8601String(),
      'harvestDate': harvestDate?.toIso8601String(),
      'daysToMaturity': daysToMaturity,
      'sunExposure': sunExposure.index,
      'waterNeed': waterNeed.index,
      'soilType': soilType.index,
      'idealPh': idealPh,
      'spacing': spacing,
      'depth': depth,
      'companionPlants': companionPlants,
      'avoidPlants': avoidPlants,
      'careInstructions': careInstructions,
      'harvestInstructions': harvestInstructions,
      'isFavorite': isFavorite,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'gardenId': gardenId,
    };
  }

  factory Plant.fromMap(Map<String, dynamic> map) {
    return Plant(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      scientificName: map['scientificName'],
      description: map['description'],
      type: PlantType.values[map['type'] ?? 0],
      categories: (map['categories'] as List<dynamic>?)
          ?.map((e) => PlantCategory.values[e as int])
          .toList() ?? [],
      imagePath: map['imagePath'],
      plantingDate: map['plantingDate'] != null 
          ? DateTime.parse(map['plantingDate'])
          : null,
      harvestDate: map['harvestDate'] != null 
          ? DateTime.parse(map['harvestDate'])
          : null,
      daysToMaturity: map['daysToMaturity'],
      sunExposure: SunExposure.values[map['sunExposure'] ?? 0],
      waterNeed: WaterNeed.values[map['waterNeed'] ?? 1],
      soilType: SoilType.values[map['soilType'] ?? 2],
      idealPh: map['idealPh']?.toDouble(),
      spacing: map['spacing']?.toDouble(),
      depth: map['depth']?.toDouble(),
      companionPlants: map['companionPlants'],
      avoidPlants: map['avoidPlants'],
      careInstructions: map['careInstructions'],
      harvestInstructions: map['harvestInstructions'],
      isFavorite: map['isFavorite'] ?? false,
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      gardenId: map['gardenId'],
    );
  }
}

class PlantAdapter extends TypeAdapter<Plant> {
  @override
  final int typeId = 0;

  @override
  Plant read(BinaryReader reader) {
    return Plant(
      id: reader.readString(),
      name: reader.readString(),
      scientificName: reader.readString(),
      description: reader.readString(),
      type: PlantType.values[reader.readByte()],
      categories: List<PlantCategory>.from(
        reader.readByteList().map((e) => PlantCategory.values[e]),
      ),
      imagePath: reader.readString(),
      plantingDate: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      harvestDate: reader.readBool() ? DateTime.fromMillisecondsSinceEpoch(reader.readInt()) : null,
      daysToMaturity: reader.readBool() ? reader.readInt() : null,
      sunExposure: SunExposure.values[reader.readByte()],
      waterNeed: WaterNeed.values[reader.readByte()],
      soilType: SoilType.values[reader.readByte()],
      idealPh: reader.readBool() ? reader.readDouble() : null,
      spacing: reader.readBool() ? reader.readDouble() : null,
      depth: reader.readBool() ? reader.readDouble() : null,
      companionPlants: reader.readString(),
      avoidPlants: reader.readString(),
      careInstructions: reader.readString(),
      harvestInstructions: reader.readString(),
      isFavorite: reader.readBool(),
      isActive: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      gardenId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Plant obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.scientificName ?? '');
    writer.writeString(obj.description ?? '');
    writer.writeByte(obj.type.index);
    writer.writeByteList(obj.categories.map((e) => e.index).toList());
    writer.writeString(obj.imagePath ?? '');
    writer.writeBool(obj.plantingDate != null);
    if (obj.plantingDate != null) {
      writer.writeInt(obj.plantingDate!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.harvestDate != null);
    if (obj.harvestDate != null) {
      writer.writeInt(obj.harvestDate!.millisecondsSinceEpoch);
    }
    writer.writeBool(obj.daysToMaturity != null);
    if (obj.daysToMaturity != null) {
      writer.writeInt(obj.daysToMaturity!);
    }
    writer.writeByte(obj.sunExposure.index);
    writer.writeByte(obj.waterNeed.index);
    writer.writeByte(obj.soilType.index);
    writer.writeBool(obj.idealPh != null);
    if (obj.idealPh != null) {
      writer.writeDouble(obj.idealPh!);
    }
    writer.writeBool(obj.spacing != null);
    if (obj.spacing != null) {
      writer.writeDouble(obj.spacing!);
    }
    writer.writeBool(obj.depth != null);
    if (obj.depth != null) {
      writer.writeDouble(obj.depth!);
    }
    writer.writeString(obj.companionPlants ?? '');
    writer.writeString(obj.avoidPlants ?? '');
    writer.writeString(obj.careInstructions ?? '');
    writer.writeString(obj.harvestInstructions ?? '');
    writer.writeBool(obj.isFavorite);
    writer.writeBool(obj.isActive);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
    writer.writeString(obj.gardenId ?? '');
  }
}
