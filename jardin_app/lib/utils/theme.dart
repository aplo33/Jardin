import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF4CAF50),
        primaryContainer: const Color(0xFFC8E6C9),
        secondary: const Color(0xFF8BC34A),
        secondaryContainer: const Color(0xFFDCEDC8),
        surface: Colors.white,
        surfaceVariant: const Color(0xFFF5F5F5),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.black87,
        error: const Color(0xFFE57373),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: const BorderSide(color: Color(0xFF4CAF50)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF4CAF50),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE57373)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE57373), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: Color(0xFFFFFFFF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      iconTheme: const IconThemeData(
        color: Color(0xFF4CAF50),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black87),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black54),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
        bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        labelMedium: TextStyle(fontSize: 12, color: Colors.black54),
        labelSmall: TextStyle(fontSize: 10, color: Colors.black38),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF66BB6A),
        primaryContainer: const Color(0xFF4CAF50),
        secondary: const Color(0xFF8BC34A),
        secondaryContainer: const Color(0xFF689F38),
        surface: const Color(0xFF121212),
        surfaceVariant: const Color(0xFF1E1E1E),
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        error: const Color(0xFFEF9A9A),
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF1E1E1E),
        surfaceTintColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF66BB6A),
        foregroundColor: Colors.black,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF66BB6A),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF424242)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF66BB6A), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dialogTheme: const DialogTheme(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        surfaceTintColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xFF323232),
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF424242),
        thickness: 1,
      ),
    );
  }

  // Custom colors for the app
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color secondaryColor = Color(0xFF8BC34A);
  static const Color accentColor = Color(0xFFCDDC39);
  static const Color errorColor = Color(0xFFE57373);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color infoColor = Color(0xFF2196F3);
  static const Color successColor = Color(0xFF66BB6A);
  
  // Plant type colors
  static const Map<PlantType, Color> plantTypeColors = {
    PlantType.vegetable: Color(0xFF4CAF50),
    PlantType.fruit: Color(0xFFFF9800),
    PlantType.herb: Color(0xFF8BC34A),
    PlantType.flower: Color(0xFFE91E63),
    PlantType.tree: Color(0xFF8D6E63),
    PlantType.shrub: Color(0xFF795548),
  };
  
  // Task priority colors
  static const Map<TaskPriority, Color> taskPriorityColors = {
    TaskPriority.low: Color(0xFF9E9E9E),
    TaskPriority.medium: Color(0xFFFFC107),
    TaskPriority.high: Color(0xFFFF9800),
    TaskPriority.urgent: Color(0xFFE57373),
  };
  
  // Task status colors
  static const Map<TaskStatus, Color> taskStatusColors = {
    TaskStatus.pending: Color(0xFFFFC107),
    TaskStatus.inProgress: Color(0xFF2196F3),
    TaskStatus.completed: Color(0xFF66BB6A),
    TaskStatus.cancelled: Color(0xFF9E9E9E),
  };

  // Garden type colors
  static const Map<GardenType, Color> gardenTypeColors = {
    GardenType.vegetableGarden: Color(0xFF4CAF50),
    GardenType.flowerGarden: Color(0xFFE91E63),
    GardenType.orchard: Color(0xFFFF9800),
    GardenType.greenhouse: Color(0xFF2196F3),
    GardenType.mixed: Color(0xFF9C27B0),
  };
}

// Extensions for PlantType, TaskType, etc.
import '../models/plant.dart';
import '../models/task.dart';
import '../models/garden.dart';

extension PlantTypeExtension on PlantType {
  String get displayName {
    switch (this) {
      case PlantType.vegetable:
        return 'Légume';
      case PlantType.fruit:
        return 'Fruit';
      case PlantType.herb:
        return 'Plante aromatique';
      case PlantType.flower:
        return 'Fleur';
      case PlantType.tree:
        return 'Arbre';
      case PlantType.shrub:
        return 'Arbuste';
    }
  }
  
  IconData get icon {
    switch (this) {
      case PlantType.vegetable:
        return Icons.eco;
      case PlantType.fruit:
        return Icons.apple;
      case PlantType.herb:
        return Icons.grass;
      case PlantType.flower:
        return Icons.flower;
      case PlantType.tree:
        return Icons.park;
      case PlantType.shrub:
        return Icons.nature;
    }
  }
}

extension PlantCategoryExtension on PlantCategory {
  String get displayName {
    switch (this) {
      case PlantCategory.legume:
        return 'Légumineuse';
      case PlantCategory.fruit:
        return 'Fruit';
      case PlantCategory.aromatique:
        return 'Aromatique';
      case PlantCategory.fleur:
        return 'Fleur';
      case PlantCategory.agrumes:
        return 'Agrume';
      case PlantCategory.berry:
        return 'Baie';
      case PlantCategory.salade:
        return 'Salade';
      case PlantCategory.racine:
        return 'Racine';
      case PlantCategory.autre:
        return 'Autre';
    }
  }
}

extension SunExposureExtension on SunExposure {
  String get displayName {
    switch (this) {
      case SunExposure.fullSun:
        return 'Plein soleil';
      case SunExposure.partialShade:
        return 'Mi-ombre';
      case SunExposure.fullShade:
        return 'Ombre totale';
    }
  }
  
  IconData get icon {
    switch (this) {
      case SunExposure.fullSun:
        return Icons.wb_sunny;
      case SunExposure.partialShade:
        return Icons.wb_cloudy;
      case SunExposure.fullShade:
        return Icons.brightness_2;
    }
  }
}

extension WaterNeedExtension on WaterNeed {
  String get displayName {
    switch (this) {
      case WaterNeed.low:
        return 'Faible';
      case WaterNeed.medium:
        return 'Modéré';
      case WaterNeed.high:
        return 'Élevé';
    }
  }
  
  IconData get icon {
    switch (this) {
      case WaterNeed.low:
        return Icons.opacity;
      case WaterNeed.medium:
        return Icons.opacity;
      case WaterNeed.high:
        return Icons.opacity;
    }
  }
}

extension SoilTypeExtension on SoilType {
  String get displayName {
    switch (this) {
      case SoilType.clay:
        return 'Argileux';
      case SoilType.sandy:
        return 'Sableux';
      case SoilType.loamy:
        return 'Limoneux';
      case SoilType.chalky:
        return 'Calcaire';
      case SoilType.peaty:
        return 'Tourbeux';
      case SoilType.silty:
        return 'Limon';
    }
  }
}

extension TaskTypeExtension on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.watering:
        return 'Arrosage';
      case TaskType.pruning:
        return 'Taille';
      case TaskType.fertilizing:
        return 'Fertilisation';
      case TaskType.harvesting:
        return 'Récolte';
      case TaskType.planting:
        return 'Plantation';
      case TaskType.weeding:
        return 'Désherbage';
      case TaskType.pestControl:
        return 'Lutte contre les nuisibles';
      case TaskType.other:
        return 'Autre';
    }
  }
  
  IconData get icon {
    switch (this) {
      case TaskType.watering:
        return Icons.opacity;
      case TaskType.pruning:
        return Icons.content_cut;
      case TaskType.fertilizing:
        return Icons.eco;
      case TaskType.harvesting:
        return Icons.agriculture;
      case TaskType.planting:
        return Icons.grass;
      case TaskType.weeding:
        return Icons.weed;
      case TaskType.pestControl:
        return Icons.bug_report;
      case TaskType.other:
        return Icons.task;
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Faible';
      case TaskPriority.medium:
        return 'Moyenne';
      case TaskPriority.high:
        return 'Haute';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }
}

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'En attente';
      case TaskStatus.inProgress:
        return 'En cours';
      case TaskStatus.completed:
        return 'Terminée';
      case TaskStatus.cancelled:
        return 'Annulée';
    }
  }
}

extension GardenTypeExtension on GardenType {
  String get displayName {
    switch (this) {
      case GardenType.vegetableGarden:
        return 'Potager';
      case GardenType.flowerGarden:
        return 'Jardin d\'agrément';
      case GardenType.orchard:
        return 'Verger';
      case GardenType.greenhouse:
        return 'Serre';
      case GardenType.mixed:
        return 'Mixte';
    }
  }
  
  IconData get icon {
    switch (this) {
      case GardenType.vegetableGarden:
        return Icons.agriculture;
      case GardenType.flowerGarden:
        return Icons.flower;
      case GardenType.orchard:
        return Icons.apple;
      case GardenType.greenhouse:
        return Icons.house;
      case GardenType.mixed:
        return Icons.nature;
    }
  }
}
