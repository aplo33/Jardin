import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/harvest.dart';

class HarvestProvider with ChangeNotifier {
  final Box<Harvest> _harvestsBox = Hive.box<Harvest>('harvests');
  
  List<Harvest> _harvests = [];
  List<Harvest> get harvests => _harvests;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  HarvestProvider() {
    _loadHarvests();
  }

  Future<void> _loadHarvests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _harvests = _harvestsBox.values.toList();
      _harvests.sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
    } catch (e) {
      _error = 'Erreur lors du chargement des récoltes: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHarvest(Harvest harvest) async {
    try {
      await _harvestsBox.put(harvest.id, harvest);
      _harvests.add(harvest);
      _harvests.sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'ajout de la récolte: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateHarvest(Harvest harvest) async {
    try {
      await _harvestsBox.put(harvest.id, harvest);
      final index = _harvests.indexWhere((h) => h.id == harvest.id);
      if (index != -1) {
        _harvests[index] = harvest;
        _harvests.sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
        notifyListeners();
      }
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de la récolte: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteHarvest(String harvestId) async {
    try {
      await _harvestsBox.delete(harvestId);
      _harvests.removeWhere((h) => h.id == harvestId);
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression de la récolte: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  List<Harvest> getHarvestsByPlant(String plantId) {
    return _harvests.where((h) => h.plantId == plantId).toList();
  }

  List<Harvest> getHarvestsByGarden(String gardenId) {
    return _harvests.where((h) => h.gardenId == gardenId).toList();
  }

  List<Harvest> getHarvestsByDate(DateTime date) {
    return _harvests.where((h) => 
      h.harvestDate.year == date.year && 
      h.harvestDate.month == date.month && 
      h.harvestDate.day == date.day
    ).toList();
  }

  List<Harvest> getHarvestsByMonth(int year, int month) {
    return _harvests.where((h) => 
      h.harvestDate.year == year && 
      h.harvestDate.month == month
    ).toList();
  }

  List<Harvest> getHarvestsByYear(int year) {
    return _harvests.where((h) => h.harvestDate.year == year).toList();
  }

  double getTotalQuantityByPlant(String plantId) {
    return _harvests
        .where((h) => h.plantId == plantId)
        .fold(0.0, (sum, h) => sum + h.quantity);
  }

  double getTotalQuantityByGarden(String gardenId) {
    return _harvests
        .where((h) => h.gardenId == gardenId)
        .fold(0.0, (sum, h) => sum + h.quantity);
  }

  Map<String, double> getHarvestStatisticsByPlant() {
    final stats = <String, double>{};
    for (var harvest in _harvests) {
      stats.update(
        harvest.plantName,
        (value) => value + harvest.quantity,
        ifAbsent: () => harvest.quantity,
      );
    }
    return stats;
  }

  Harvest? getHarvestById(String id) {
    return _harvests.firstWhere((h) => h.id == id);
  }

  List<Harvest> getRecentHarvests([int limit = 10]) {
    return _harvests.take(limit).toList();
  }

  List<Harvest> searchHarvests(String query) {
    final lowerQuery = query.toLowerCase();
    return _harvests.where((h) => 
      h.plantName.toLowerCase().contains(lowerQuery) ||
      (h.notes?.toLowerCase().contains(lowerQuery) ?? false) ||
      (h.quality?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  Future<void> refresh() async {
    await _loadHarvests();
  }
}
