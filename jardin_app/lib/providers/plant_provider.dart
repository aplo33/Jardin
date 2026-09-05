import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/plant.dart';

class PlantProvider with ChangeNotifier {
  final Box<Plant> _plantsBox = Hive.box<Plant>('plants');
  
  List<Plant> _plants = [];
  List<Plant> get plants => _plants;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  PlantProvider() {
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _plants = _plantsBox.values.toList();
      _plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      _error = 'Erreur lors du chargement des plantes: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPlant(Plant plant) async {
    try {
      await _plantsBox.put(plant.id, plant);
      _plants.add(plant);
      _plants.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'ajout de la plante: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updatePlant(Plant plant) async {
    try {
      await _plantsBox.put(plant.id, plant);
      final index = _plants.indexWhere((p) => p.id == plant.id);
      if (index != -1) {
        _plants[index] = plant;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de la plante: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePlant(String plantId) async {
    try {
      await _plantsBox.delete(plantId);
      _plants.removeWhere((p) => p.id == plantId);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression de la plante: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleFavorite(String plantId) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index != -1) {
      final plant = _plants[index];
      final updatedPlant = plant.copyWith(isFavorite: !plant.isFavorite);
      await updatePlant(updatedPlant);
    }
  }

  Future<void> toggleActive(String plantId) async {
    final index = _plants.indexWhere((p) => p.id == plantId);
    if (index != -1) {
      final plant = _plants[index];
      final updatedPlant = plant.copyWith(isActive: !plant.isActive);
      await updatePlant(updatedPlant);
    }
  }

  List<Plant> getFavoritePlants() {
    return _plants.where((p) => p.isFavorite).toList();
  }

  List<Plant> getActivePlants() {
    return _plants.where((p) => p.isActive).toList();
  }

  List<Plant> getPlantsByType(PlantType type) {
    return _plants.where((p) => p.type == type).toList();
  }

  List<Plant> getPlantsByCategory(PlantCategory category) {
    return _plants.where((p) => p.categories.contains(category)).toList();
  }

  List<Plant> getPlantsByGarden(String gardenId) {
    return _plants.where((p) => p.gardenId == gardenId).toList();
  }

  List<Plant> searchPlants(String query) {
    final lowerQuery = query.toLowerCase();
    return _plants.where((p) => 
      p.name.toLowerCase().contains(lowerQuery) ||
      (p.scientificName?.toLowerCase().contains(lowerQuery) ?? false) ||
      (p.description?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  Plant? getPlantById(String id) {
    return _plants.firstWhere((p) => p.id == id);
  }

  Future<void> refresh() async {
    await _loadPlants();
  }
}
