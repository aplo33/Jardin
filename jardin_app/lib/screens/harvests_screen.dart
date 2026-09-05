import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/harvest_provider.dart';
import '../providers/plant_provider.dart';
import '../providers/garden_provider.dart';
import '../models/harvest.dart';
import '../models/plant.dart';
import '../utils/theme.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class HarvestsScreen extends StatefulWidget {
  const HarvestsScreen({super.key});

  @override
  State<HarvestsScreen> createState() => _HarvestsScreenState();
}

class _HarvestsScreenState extends State<HarvestsScreen> {
  String? _selectedPlantId;
  String? _selectedGardenId;
  DateTime? _selectedDate;
  int? _selectedMonth;
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final harvestProvider = context.watch<HarvestProvider>();
    final plantProvider = context.watch<PlantProvider>();
    final gardenProvider = context.watch<GardenProvider>();
    
    final gardens = gardenProvider.gardens;
    final plants = plantProvider.getActivePlants();
    
    List<Harvest> filteredHarvests = harvestProvider.harvests;
    
    // Apply filters
    if (_selectedPlantId != null) {
      filteredHarvests = filteredHarvests.where((h) => h.plantId == _selectedPlantId).toList();
    }
    
    if (_selectedGardenId != null) {
      filteredHarvests = filteredHarvests.where((h) => h.gardenId == _selectedGardenId).toList();
    }
    
    if (_selectedDate != null) {
      filteredHarvests = filteredHarvests.where((h) => 
        h.harvestDate.year == _selectedDate!.year &&
        h.harvestDate.month == _selectedDate!.month &&
        h.harvestDate.day == _selectedDate!.day
      ).toList();
    }
    
    if (_selectedMonth != null) {
      filteredHarvests = filteredHarvests.where((h) => 
        h.harvestDate.year == _selectedYear &&
        h.harvestDate.month == _selectedMonth
      ).toList();
    }

    // Sort by harvest date (newest first)
    filteredHarvests.sort((a, b) => b.harvestDate.compareTo(a.harvestDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Récoltes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showMonthPicker,
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
                    value: harvestProvider.harvests.length.toString(),
                    icon: Icons.agriculture,
                    color: Colors.green,
                    context: context,
                  ),
                  const VerticalDivider(),
                  _buildSummaryItem(
                    title: 'Ce mois',
                    value: harvestProvider.getHarvestsByMonth(
                      DateTime.now().year, 
                      DateTime.now().month
                    ).length.toString(),
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    context: context,
                  ),
                  const VerticalDivider(),
                  _buildSummaryItem(
                    title: 'Cette année',
                    value: harvestProvider.getHarvestsByYear(DateTime.now().year).length.toString(),
                    icon: Icons.calendar_view_year,
                    color: Colors.orange,
                    context: context,
                  ),
                  const VerticalDivider(),
                  _buildSummaryItem(
                    title: 'Total (kg)',
                    value: _formatTotalQuantity(harvestProvider.harvests),
                    icon: Icons.monitor_weight,
                    color: Colors.purple,
                    context: context,
                  ),
                ],
              ),
            ),
          ),
          
          // Filter chips
          if (_selectedPlantId != null || _selectedGardenId != null || 
              _selectedDate != null || _selectedMonth != null) ...[
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
          
          // Harvests list
          Expanded(
            child: harvestProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHarvests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.agriculture, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune récolte trouvée',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Essayez de modifier vos filtres ou enregistrez une nouvelle récolte',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredHarvests.length,
                        itemBuilder: (context, index) {
                          final harvest = filteredHarvests[index];
                          return _buildHarvestCard(harvest, context);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddHarvestDialog(context),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTotalQuantity(List<Harvest> harvests) {
    // Filter harvests with kg unit and sum quantities
    final kgHarvests = harvests.where((h) => h.unit.toLowerCase().contains('kg'));
    final totalKg = kgHarvests.fold(0.0, (sum, h) => sum + h.quantity);
    return totalKg.toStringAsFixed(1);
  }

  Widget _buildHarvestCard(Harvest harvest, BuildContext context) {
    final plantProvider = context.read<PlantProvider>();
    final gardenProvider = context.read<GardenProvider>();
    final plant = plantProvider.getPlantById(harvest.plantId);
    final garden = harvest.gardenId != null 
        ? gardenProvider.getGardenById(harvest.gardenId!) 
        : null;

    return Slidable(
      key: ValueKey(harvest.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => _showEditHarvestDialog(harvest, context),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDeleteHarvest(harvest, context),
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
          onTap: () => _showHarvestDetail(harvest, context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Harvest icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.agriculture, color: Colors.green, size: 28),
                    ),
                    const SizedBox(width: 12),
                    
                    // Harvest info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  harvest.plantName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: Text(
                                  '${harvest.quantity} ${harvest.unit}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Date and garden
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('dd/MM/yyyy', 'fr_FR').format(harvest.harvestDate),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (garden != null) ...[
                                const SizedBox(width: 16),
                                Icon(Icons.nature, size: 16, color: Colors.brown),
                                const SizedBox(width: 4),
                                Text(
                                  garden.name,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ],
                          ),
                          
                          // Quality
                          if (harvest.quality != null && harvest.quality!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  'Qualité: ${harvest.quality}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                          
                          // Notes
                          if (harvest.notes != null && harvest.notes!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              harvest.notes!,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Additional info
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (plant != null) ...[
                      Icon(plant.type.icon, size: 16, color: AppTheme.plantTypeColors[plant.type]),
                      const SizedBox(width: 4),
                      Text(
                        plant.type.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                    ],
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

  List<Widget> _buildFilterChips(BuildContext context) {
    final chips = <Widget>[];
    
    if (_selectedPlantId != null) {
      final plantProvider = context.read<PlantProvider>();
      final plant = plantProvider.getPlantById(_selectedPlantId!);
      if (plant != null) {
        chips.add(
          FilterChip(
            label: Text(plant.name),
            selected: true,
            onSelected: (_) => setState(() => _selectedPlantId = null),
            avatar: Icon(plant.type.icon, size: 18),
          ),
        );
      }
    }
    
    if (_selectedGardenId != null) {
      final garden = context.read<GardenProvider>().getGardenById(_selectedGardenId!);
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
    
    if (_selectedDate != null) {
      chips.add(
        FilterChip(
          label: Text(DateFormat('dd/MM/yyyy', 'fr_FR').format(_selectedDate!)),
          selected: true,
          onSelected: (_) => setState(() => _selectedDate = null),
          avatar: const Icon(Icons.calendar_today, size: 18),
        ),
      );
    }
    
    if (_selectedMonth != null) {
      chips.add(
        FilterChip(
          label: Text(DateFormat('MMMM yyyy', 'fr_FR').format(
            DateTime(_selectedYear ?? DateTime.now().year, _selectedMonth!)
          )),
          selected: true,
          onSelected: (_) => setState(() => _selectedMonth = null),
          avatar: const Icon(Icons.calendar_month, size: 18),
        ),
      );
    }
    
    return chips;
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildFilterSheet(context),
    );
  }

  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMonthPickerSheet(context),
    );
  }

  Widget _buildFilterSheet(BuildContext context) {
    final plantProvider = context.read<PlantProvider>();
    final gardenProvider = context.read<GardenProvider>();
    final plants = plantProvider.getActivePlants();
    final gardens = gardenProvider.gardens;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Filtrer les récoltes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Plant filter
          Text(
            'Plante',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (plants.isEmpty) ...[
            Text(
              'Aucune plante active disponible',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Toutes les plantes'),
                  selected: _selectedPlantId == null,
                  onSelected: (_) => setState(() => _selectedPlantId = null),
                ),
                ...plants.map((plant) => FilterChip(
                  label: Text(plant.name),
                  selected: _selectedPlantId == plant.id,
                  onSelected: (selected) => setState(() {
                    _selectedPlantId = selected ? plant.id : null;
                  }),
                  avatar: Icon(plant.type.icon, size: 18),
                )),
              ],
            ),
          ],
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
          
          // Date filter
          Text(
            'Date spécifique',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                      lastDate: DateTime.now(),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                        _selectedMonth = null;
                        _selectedYear = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDate != null 
                        ? DateFormat('dd/MM/yyyy', 'fr_FR').format(_selectedDate!)
                        : 'Sélectionner une date',
                  ),
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedDate = null),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedPlantId = null;
                    _selectedGardenId = null;
                    _selectedDate = null;
                    _selectedMonth = null;
                    _selectedYear = null;
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

  Widget _buildMonthPickerSheet(BuildContext context) {
    final now = DateTime.now();
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sélectionner un mois',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Year selector
          DropdownButtonFormField<int>(
            value: _selectedYear ?? now.year,
            decoration: const InputDecoration(
              labelText: 'Année',
              prefixIcon: Icon(Icons.calendar_view_year),
            ),
            items: List.generate(5, (index) {
              final year = now.year - 2 + index;
              return DropdownMenuItem(
                value: year,
                child: Text(year.toString()),
              );
            }),
            onChanged: (value) => setState(() => _selectedYear = value),
          ),
          const SizedBox(height: 16),
          
          // Month selector
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(12, (index) {
              final month = index + 1;
              final isSelected = _selectedMonth == month && 
                                (_selectedYear ?? now.year) == (_selectedYear ?? now.year);
              
              return Card(
                color: isSelected ? AppTheme.primaryColor : null,
                elevation: isSelected ? 4 : 2,
                child: InkWell(
                  onTap: () => setState(() {
                    _selectedMonth = month;
                    _selectedDate = null;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      DateFormat('MMM', 'fr_FR').format(DateTime(now.year, month)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMonth = null;
                    _selectedYear = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_selectedMonth != null) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHarvestDetail(Harvest harvest, BuildContext context) {
    final plantProvider = context.read<PlantProvider>();
    final gardenProvider = context.read<GardenProvider>();
    final plant = plantProvider.getPlantById(harvest.plantId);
    final garden = harvest.gardenId != null 
        ? gardenProvider.getGardenById(harvest.gardenId!) 
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(harvest.plantName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.agriculture, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Quantité: ${harvest.quantity} ${harvest.unit}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy', 'fr_FR').format(harvest.harvestDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              if (plant != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(plant.type.icon, color: AppTheme.plantTypeColors[plant.type]),
                    const SizedBox(width: 8),
                    Text(
                      'Type: ${plant.type.displayName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (garden != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(garden.type.icon, color: AppTheme.gardenTypeColors[garden.type]),
                    const SizedBox(width: 8),
                    Text(
                      'Jardin: ${garden.name}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (harvest.quality != null && harvest.quality!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Qualité: ${harvest.quality}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (harvest.notes != null && harvest.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.notes, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notes: ${harvest.notes}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'ID: ${harvest.id}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditHarvestDialog(harvest, context);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  void _showAddHarvestDialog(BuildContext context) {
    final plantProvider = context.read<PlantProvider>();
    final gardenProvider = context.read<GardenProvider>();
    final plants = plantProvider.getActivePlants();
    final gardens = gardenProvider.gardens;
    
    final harvestProvider = context.read<HarvestProvider>();
    
    // Default values
    String selectedPlantId = plants.isNotEmpty ? plants.first.id : '';
    String selectedGardenId = gardenProvider.currentGarden?.id ?? (gardens.isNotEmpty ? gardens.first.id : '');
    DateTime selectedDate = DateTime.now();
    double quantity = 1.0;
    String selectedUnit = 'kg';
    String quality = 'Bonne';
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter une récolte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Plant
                DropdownButtonFormField<String>(
                  value: selectedPlantId,
                  decoration: const InputDecoration(
                    labelText: 'Plante *',
                    prefixIcon: Icon(Icons.eco),
                  ),
                  items: plants.map((plant) => DropdownMenuItem(
                    value: plant.id,
                    child: Row(
                      children: [
                        Icon(plant.type.icon, color: AppTheme.plantTypeColors[plant.type]),
                        const SizedBox(width: 8),
                        Text(plant.name),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => selectedPlantId = value!,
                ),
                const SizedBox(height: 16),
                
                // Garden
                if (gardens.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedGardenId,
                    decoration: const InputDecoration(
                      labelText: 'Jardin',
                      prefixIcon: Icon(Icons.nature),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Aucun jardin'),
                      ),
                      ...gardens.map((garden) => DropdownMenuItem(
                        value: garden.id,
                        child: Row(
                          children: [
                            Icon(garden.type.icon, color: AppTheme.gardenTypeColors[garden.type]),
                            const SizedBox(width: 8),
                            Text(garden.name),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (value) => selectedGardenId = value,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Date
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date de récolte *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy', 'fr_FR').format(selectedDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Quantity and unit
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Quantité *',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: quantity.toString()),
                        onChanged: (value) => quantity = double.tryParse(value) ?? 0.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unité *',
                          prefixIcon: Icon(Icons.unit),
                        ),
                        items: ['kg', 'g', 'L', 'piece', 'botte', 'panier'].map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        )).toList(),
                        onChanged: (value) => selectedUnit = value!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quality
                DropdownButtonFormField<String>(
                  value: quality,
                  decoration: const InputDecoration(
                    labelText: 'Qualité',
                    prefixIcon: Icon(Icons.star),
                  ),
                  items: ['Excellente', 'Bonne', 'Moyenne', 'Faible'].map((q) => DropdownMenuItem(
                    value: q,
                    child: Text(q),
                  )).toList(),
                  onChanged: (value) => quality = value!,
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                  controller: TextEditingController(text: notes),
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedPlantId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner une plante'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final plant = plantProvider.getPlantById(selectedPlantId);
                if (plant == null) return;
                
                final harvest = Harvest(
                  id: const Uuid().v4(),
                  plantId: selectedPlantId,
                  plantName: plant.name,
                  harvestDate: selectedDate,
                  quantity: quantity,
                  unit: selectedUnit,
                  quality: quality,
                  notes: notes.isEmpty ? null : notes,
                  gardenId: selectedGardenId,
                );
                
                try {
                  await harvestProvider.addHarvest(harvest);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Récolte de "${plant.name}" enregistrée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditHarvestDialog(Harvest harvest, BuildContext context) {
    final plantProvider = context.read<PlantProvider>();
    final gardenProvider = context.read<GardenProvider>();
    final plants = plantProvider.getActivePlants();
    final gardens = gardenProvider.gardens;
    
    final harvestProvider = context.read<HarvestProvider>();
    
    // Initialize with harvest values
    String selectedPlantId = harvest.plantId;
    String selectedGardenId = harvest.gardenId ?? '';
    DateTime selectedDate = harvest.harvestDate;
    double quantity = harvest.quantity;
    String selectedUnit = harvest.unit;
    String quality = harvest.quality ?? 'Bonne';
    String notes = harvest.notes ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Modifier la récolte: ${harvest.plantName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Plant
                DropdownButtonFormField<String>(
                  value: selectedPlantId,
                  decoration: const InputDecoration(
                    labelText: 'Plante *',
                    prefixIcon: Icon(Icons.eco),
                  ),
                  items: plants.map((plant) => DropdownMenuItem(
                    value: plant.id,
                    child: Row(
                      children: [
                        Icon(plant.type.icon, color: AppTheme.plantTypeColors[plant.type]),
                        const SizedBox(width: 8),
                        Text(plant.name),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => selectedPlantId = value!,
                ),
                const SizedBox(height: 16),
                
                // Garden
                if (gardens.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedGardenId,
                    decoration: const InputDecoration(
                      labelText: 'Jardin',
                      prefixIcon: Icon(Icons.nature),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Aucun jardin'),
                      ),
                      ...gardens.map((garden) => DropdownMenuItem(
                        value: garden.id,
                        child: Row(
                          children: [
                            Icon(garden.type.icon, color: AppTheme.gardenTypeColors[garden.type]),
                            const SizedBox(width: 8),
                            Text(garden.name),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (value) => selectedGardenId = value,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Date
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date de récolte *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy', 'fr_FR').format(selectedDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now(),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Quantity and unit
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Quantité *',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: quantity.toString()),
                        onChanged: (value) => quantity = double.tryParse(value) ?? 0.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unité *',
                          prefixIcon: Icon(Icons.unit),
                        ),
                        items: ['kg', 'g', 'L', 'piece', 'botte', 'panier'].map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        )).toList(),
                        onChanged: (value) => selectedUnit = value!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Quality
                DropdownButtonFormField<String>(
                  value: quality,
                  decoration: const InputDecoration(
                    labelText: 'Qualité',
                    prefixIcon: Icon(Icons.star),
                  ),
                  items: ['Excellente', 'Bonne', 'Moyenne', 'Faible'].map((q) => DropdownMenuItem(
                    value: q,
                    child: Text(q),
                  )).toList(),
                  onChanged: (value) => quality = value!,
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                  controller: TextEditingController(text: notes),
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedPlantId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez sélectionner une plante'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final plant = plantProvider.getPlantById(selectedPlantId);
                if (plant == null) return;
                
                final updatedHarvest = harvest.copyWith(
                  plantId: selectedPlantId,
                  plantName: plant.name,
                  harvestDate: selectedDate,
                  quantity: quantity,
                  unit: selectedUnit,
                  quality: quality,
                  notes: notes.isEmpty ? null : notes,
                  gardenId: selectedGardenId,
                );
                
                try {
                  await harvestProvider.updateHarvest(updatedHarvest);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Récolte mise à jour'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteHarvest(Harvest harvest, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la récolte'),
        content: Text('Êtes-vous sûr de vouloir supprimer la récolte de "${harvest.plantName}" du ${DateFormat('dd/MM/yyyy', 'fr_FR').format(harvest.harvestDate)} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<HarvestProvider>().deleteHarvest(harvest.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Récolte de "${harvest.plantName}" supprimée'),
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
