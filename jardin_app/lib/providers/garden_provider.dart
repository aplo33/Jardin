import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/garden.dart';

class GardenProvider with ChangeNotifier {
  final Box<Garden> _gardensBox = Hive.box<Garden>('gardens');
  
  List<Garden> _gardens = [];
  List<Garden> get gardens => _gardens;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  Garden? _currentGarden;
  Garden? get currentGarden => _currentGarden;

  GardenProvider() {
    _loadGardens();
  }

  Future<void> _loadGardens() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _gardens = _gardensBox.values.toList();
      _gardens.sort((a, b) => a.name.compareTo(b.name));
      
      // Set first garden as current if none selected
      if (_currentGarden == null && _gardens.isNotEmpty) {
        _currentGarden = _gardens.first;
      }
    } catch (e) {
      _error = 'Erreur lors du chargement des jardins: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addGarden(Garden garden) async {
    try {
      await _gardensBox.put(garden.id, garden);
      _gardens.add(garden);
      _gardens.sort((a, b) => a.name.compareTo(b.name));
      
      // If this is the first garden, set it as current
      if (_currentGarden == null) {
        _currentGarden = garden;
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du jardin: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateGarden(Garden garden) async {
    try {
      await _gardensBox.put(garden.id, garden);
      final index = _gardens.indexWhere((g) => g.id == garden.id);
      if (index != -1) {
        _gardens[index] = garden;
        _gardens.sort((a, b) => a.name.compareTo(b.name));
        
        // Update current garden if it's the one being updated
        if (_currentGarden?.id == garden.id) {
          _currentGarden = garden;
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du jardin: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteGarden(String gardenId) async {
    try {
      await _gardensBox.delete(gardenId);
      _gardens.removeWhere((g) => g.id == gardenId);
      
      // If deleted garden was current, set first garden as current
      if (_currentGarden?.id == gardenId) {
        _currentGarden = _gardens.isNotEmpty ? _gardens.first : null;
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression du jardin: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setCurrentGarden(String gardenId) async {
    final garden = _gardens.firstWhere((g) => g.id == gardenId);
    _currentGarden = garden;
    notifyListeners();
  }

  Future<void> toggleGardenActive(String gardenId) async {
    final index = _gardens.indexWhere((g) => g.id == gardenId);
    if (index != -1) {
      final garden = _gardens[index];
      final updatedGarden = garden.copyWith(isActive: !garden.isActive);
      await updateGarden(updatedGarden);
    }
  }

  Garden? getGardenById(String id) {
    return _gardens.firstWhere((g) => g.id == id);
  }

  List<Garden> getActiveGardens() {
    return _gardens.where((g) => g.isActive).toList();
  }

  List<Garden> getGardensByType(GardenType type) {
    return _gardens.where((g) => g.type == type).toList();
  }

  List<Garden> searchGardens(String query) {
    final lowerQuery = query.toLowerCase();
    return _gardens.where((g) => 
      g.name.toLowerCase().contains(lowerQuery) ||
      (g.description?.toLowerCase().contains(lowerQuery) ?? false) ||
      (g.location?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  Future<void> refresh() async {
    await _loadGardens();
  }
}
