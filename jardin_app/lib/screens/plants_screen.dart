import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../providers/garden_provider.dart';
import '../models/plant.dart';
import '../models/garden.dart';
import '../utils/theme.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  String _searchQuery = '';
  PlantType? _selectedType;
  PlantCategory? _selectedCategory;
  bool _showFavoritesOnly = false;
  String? _selectedGardenId;

  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();
    final gardenProvider = context.watch<GardenProvider>();
    
    final gardens = gardenProvider.gardens;
    
    List<Plant> filteredPlants = plantProvider.plants;
    
    // Apply filters
    if (_showFavoritesOnly) {
      filteredPlants = filteredPlants.where((p) => p.isFavorite).toList();
    }
    
    if (_selectedType != null) {
      filteredPlants = filteredPlants.where((p) => p.type == _selectedType).toList();
    }
    
    if (_selectedCategory != null) {
      filteredPlants = filteredPlants.where((p) => p.categories.contains(_selectedCategory)).toList();
    }
    
    if (_selectedGardenId != null) {
      filteredPlants = filteredPlants.where((p) => p.gardenId == _selectedGardenId).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filteredPlants = plantProvider.searchPlants(_searchQuery);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Plantes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildSummaryItem(
                    title: 'Total',
                    value: plantProvider.plants.length.toString(),
                    icon: Icons.eco,
                    color: Colors.green,
                    context: context,
                  ),
                  const VerticalDivider(),
                  _buildSummaryItem(
                    title: 'Favorites',
                    value: plantProvider.getFavoritePlants().length.toString(),
                    icon: Icons.favorite,
                    color: Colors.red,
                    context: context,
                  ),
                  const VerticalDivider(),
                  _buildSummaryItem(
                    title: 'Actives',
                    value: plantProvider.getActivePlants().length.toString(),
                    icon: Icons.check_circle,
                    color: Colors.blue,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
          
          // Plant types filter chips
          if (_selectedType != null || _selectedCategory != null || _showFavoritesOnly || _selectedGardenId != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildFilterChips(context),
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Plants list
          Expanded(
            child: plantProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPlants.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.eco, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune plante trouvée',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez de modifier vos filtres ou ajoutez une nouvelle plante',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredPlants.length,
                        itemBuilder: (context, index) {
                          final plant = filteredPlants[index];
                          return _buildPlantCard(plant, context);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => context.push('/plant/add'),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPlantCard(Plant plant, BuildContext context) {
    final gardenProvider = context.read<GardenProvider>();
    final gardenName = plant.gardenId != null 
        ? gardenProvider.getGardenById(plant.gardenId!)?.name 
        : 'Aucun jardin';
    
    return Slidable(
      key: ValueKey(plant.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _toggleFavorite(plant.id, context),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: plant.isFavorite ? Icons.favorite : Icons.favorite_border,
            label: plant.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
          ),
          SlidableAction(
            onPressed: (_) => context.push('/plant/edit/${plant.id}'),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDeletePlant(plant, context),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Supprimer',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/plant/${plant.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant icon and type
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.plantTypeColors[plant.type]?.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        plant.type.icon,
                        color: AppTheme.plantTypeColors[plant.type],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Plant info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  plant.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (plant.isFavorite)
                                Icon(
                                  Icons.favorite,
                                  color: Colors.red,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plant.scientificName ?? gardenName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          
                          // Plant characteristics
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _buildPlantChip(
                                icon: plant.sunExposure.icon,
                                label: plant.sunExposure.displayName,
                                color: Colors.orange,
                                context: context,
                              ),
                              _buildPlantChip(
                                icon: plant.waterNeed.icon,
                                label: plant.waterNeed.displayName,
                                color: Colors.blue,
                                context: context,
                              ),
                              _buildPlantChip(
                                icon: Icons.grass,
                                label: plant.soilType.displayName,
                                color: Colors.brown,
                                context: context,
                              ),
                            ],
                          ),
                          
                          // Planting and harvest dates
                          if (plant.plantingDate != null || plant.harvestDate != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (plant.plantingDate != null) ...[
                                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Planté: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(plant.plantingDate!)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (plant.harvestDate != null) ...[
                                  Icon(Icons.agriculture, size: 16, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Récolte: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(plant.harvestDate!)}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Active status
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      plant.isActive ? Icons.check_circle : Icons.cancel,
                      color: plant.isActive ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plant.isActive ? 'Active' : 'Inactive',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: plant.isActive ? Colors.green : Colors.red,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlantChip({
    required IconData icon,
    required String label,
    required Color color,
    required BuildContext context,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      backgroundColor: color.withOpacity(0.1),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    final chips = <Widget>[];
    
    if (_showFavoritesOnly) {
      chips.add(
        FilterChip(
          label: const Text('Favorites'),
          selected: true,
          onSelected: (_) => setState(() => _showFavoritesOnly = false),
          avatar: const Icon(Icons.favorite, size: 18),
        ),
      );
    }
    
    if (_selectedType != null) {
      chips.add(
        FilterChip(
          label: Text(_selectedType!.displayName),
          selected: true,
          onSelected: (_) => setState(() => _selectedType = null),
          avatar: Icon(_selectedType!.icon, size: 18),
        ),
      );
    }
    
    if (_selectedCategory != null) {
      chips.add(
        FilterChip(
          label: Text(_selectedCategory!.displayName),
          selected: true,
          onSelected: (_) => setState(() => _selectedCategory = null),
        ),
      );
    }
    
    if (_selectedGardenId != null) {
      final gardenProvider = context.read<GardenProvider>();
      final garden = gardenProvider.getGardenById(_selectedGardenId!);
      if (garden != null) {
        chips.add(
          FilterChip(
            label: Text(garden.name),
            selected: true,
            onSelected: (_) => setState(() => _selectedGardenId = null),
            avatar: Icon(garden.type.icon, size: 18),
          ),
        );
      }
    }
    
    return chips;
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: PlantSearchDelegate(context),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterSheet(context),
    );
  }

  Widget _buildFilterSheet(BuildContext context) {
    final gardenProvider = context.read<GardenProvider>();
    final gardens = gardenProvider.gardens;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtrer les plantes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Favorites filter
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Favorites uniquement'),
            trailing: Switch(
              value: _showFavoritesOnly,
              onChanged: (value) => setState(() => _showFavoritesOnly = value),
            ),
          ),
          const Divider(),
          
          // Type filter
          Text(
            'Type de plante',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlantType.values.map((type) => FilterChip(
              label: Text(type.displayName),
              selected: _selectedType == type,
              onSelected: (selected) => setState(() {
                _selectedType = selected ? type : null;
              }),
              avatar: Icon(type.icon, size: 18),
            )).toList(),
          ),
          const SizedBox(height: 16),
          
          // Category filter
          Text(
            'Catégorie',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlantCategory.values.map((category) => FilterChip(
              label: Text(category.displayName),
              selected: _selectedCategory == category,
              onSelected: (selected) => setState(() {
                _selectedCategory = selected ? category : null;
              }),
            )).toList(),
          ),
          const SizedBox(height: 16),
          
          // Garden filter
          Text(
            'Jardin',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (gardens.isEmpty) ...[
            Text(
              'Aucun jardin créé',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Tous les jardins'),
                  selected: _selectedGardenId == null,
                  onSelected: (_) => setState(() => _selectedGardenId = null),
                ),
                ...gardens.map((garden) => FilterChip(
                  label: Text(garden.name),
                  selected: _selectedGardenId == garden.id,
                  onSelected: (selected) => setState(() {
                    _selectedGardenId = selected ? garden.id : null;
                  }),
                  avatar: Icon(garden.type.icon, size: 18),
                )),
              ],
            ),
          ],
          const SizedBox(height: 16),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFavoritesOnly = false;
                    _selectedType = null;
                    _selectedCategory = null;
                    _selectedGardenId = null;
                    _searchQuery = '';
                  });
                  Navigator.pop(context);
                },
                child: const Text('Réinitialiser'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(String plantId, BuildContext context) {
    context.read<PlantProvider>().toggleFavorite(plantId);
  }

  void _confirmDeletePlant(Plant plant, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la plante'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${plant.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PlantProvider>().deletePlant(plant.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${plant.name}" a été supprimée'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class PlantSearchDelegate extends SearchDelegate<String> {
  final BuildContext parentContext;

  PlantSearchDelegate(this.parentContext);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final plantProvider = Provider.of<PlantProvider>(parentContext, listen: false);
    final results = plantProvider.searchPlants(query);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final plant = results[index];
        return ListTile(
          leading: Icon(plant.type.icon, color: AppTheme.plantTypeColors[plant.type]),
          title: Text(plant.name),
          subtitle: Text(plant.scientificName ?? plant.type.displayName),
          onTap: () {
            close(context, plant.id);
            GoRouter.of(parentContext).push('/plant/${plant.id}');
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final plantProvider = Provider.of<PlantProvider>(parentContext, listen: false);
    final suggestions = plantProvider.searchPlants(query);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final plant = suggestions[index];
        return ListTile(
          leading: Icon(plant.type.icon, color: AppTheme.plantTypeColors[plant.type]),
          title: Text(plant.name),
          subtitle: Text(plant.scientificName ?? plant.type.displayName),
          onTap: () {
            query = plant.name;
            showResults(context);
          },
        );
      },
    );
  }

  @override
  String get searchFieldLabel => 'Rechercher une plante...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
