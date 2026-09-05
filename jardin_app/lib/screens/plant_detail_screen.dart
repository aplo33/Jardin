import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../providers/harvest_provider.dart';
import '../providers/task_provider.dart';
import '../providers/garden_provider.dart';
import '../models/plant.dart';
import '../models/harvest.dart';
import '../models/task.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class PlantDetailScreen extends StatefulWidget {
  final String plantId;

  const PlantDetailScreen({super.key, required this.plantId});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();
    final harvestProvider = context.watch<HarvestProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final gardenProvider = context.watch<GardenProvider>();
    
    final plant = plantProvider.getPlantById(widget.plantId);
    
    if (plant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plante introuvable')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Plante introuvable',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Get related data
    final garden = plant.gardenId != null 
        ? gardenProvider.getGardenById(plant.gardenId!) 
        : null;
    final harvests = harvestProvider.getHarvestsByPlant(plant.id);
    final tasks = taskProvider.getTasksByPlant(plant.id);
    
    // Sort harvests by date (newest first)
    harvests.sort((a, b) => b.harvestDate.compareTo(a.harvestDate));
    
    // Sort tasks by due date
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    // Calculate total quantity harvested
    final totalQuantity = harvests.fold(0.0, (sum, h) => sum + h.quantity);
    
    // Calculate average quality
    final qualityScores = {'Excellente': 4, 'Bonne': 3, 'Moyenne': 2, 'Faible': 1};
    final avgQuality = harvests.isNotEmpty 
        ? harvests.map((h) => qualityScores[h.quality] ?? 0).reduce((a, b) => a + b) / harvests.length
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(plant.name),
        actions: [
          IconButton(
            icon: Icon(plant.isFavorite ? Icons.favorite : Icons.favorite_border),
            color: plant.isFavorite ? Colors.red : null,
            onPressed: () => plantProvider.toggleFavorite(plant.id),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/plant/edit/${plant.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plant header
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Plant type icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.plantTypeColors[plant.type]?.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.plantTypeColors[plant.type] ?? Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        plant.type.icon,
                        color: AppTheme.plantTypeColors[plant.type],
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Plant name and scientific name
                    Text(
                      plant.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (plant.scientificName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        plant.scientificName!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 8),
                    
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: plant.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: plant.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Text(
                        plant.isActive ? 'Active' : 'Inactive',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: plant.isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Garden info
                    if (garden != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(garden.type.icon, color: AppTheme.gardenTypeColors[garden.type]),
                          const SizedBox(width: 8),
                          Text(
                            garden.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Plant information sections
            _buildInfoSection(
              title: 'Description',
              icon: Icons.description,
              content: plant.description ?? 'Aucune description disponible',
              context: context,
            ),
            const SizedBox(height: 16),

            // Characteristics
            _buildCharacteristicsSection(plant, context),
            const SizedBox(height: 16),

            // Planting information
            _buildPlantingInfoSection(plant, context),
            const SizedBox(height: 16),

            // Companion plants
            if (plant.companionPlants != null || plant.avoidPlants != null) ...[
              _buildCompanionPlantsSection(plant, context),
              const SizedBox(height: 16),
            ],

            // Care instructions
            if (plant.careInstructions != null || plant.harvestInstructions != null) ...[
              _buildCareInstructionsSection(plant, context),
              const SizedBox(height: 16),
            ],

            // Harvests
            if (harvests.isNotEmpty) ...[
              _buildHarvestsSection(harvests, totalQuantity, avgQuality, context),
              const SizedBox(height: 16),
            ],

            // Tasks
            if (tasks.isNotEmpty) ...[
              _buildTasksSection(tasks, context),
              const SizedBox(height: 16),
            ],

            // Quick actions
            _buildQuickActionsSection(plant, context),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'harvest_${plant.id}',
            child: const Icon(Icons.agriculture),
            onPressed: () => _showAddHarvestDialog(plant, context),
            backgroundColor: Colors.green,
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'task_${plant.id}',
            child: const Icon(Icons.add_task),
            onPressed: () => _showAddTaskDialog(plant, context),
            backgroundColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required String content,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicsSection(Plant plant, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Caractéristiques',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: [
                _buildCharacteristicItem(
                  icon: plant.sunExposure.icon,
                  label: 'Exposition',
                  value: plant.sunExposure.displayName,
                  color: Colors.orange,
                  context: context,
                ),
                _buildCharacteristicItem(
                  icon: plant.waterNeed.icon,
                  label: 'Besoin en eau',
                  value: plant.waterNeed.displayName,
                  color: Colors.blue,
                  context: context,
                ),
                _buildCharacteristicItem(
                  icon: Icons.grass,
                  label: 'Type de sol',
                  value: plant.soilType.displayName,
                  color: Colors.brown,
                  context: context,
                ),
                _buildCharacteristicItem(
                  icon: Icons.ph,
                  label: 'pH idéal',
                  value: plant.idealPh != null ? plant.idealPh!.toStringAsFixed(1) : 'N/A',
                  color: Colors.purple,
                  context: context,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantingInfoSection(Plant plant, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Informations de plantation',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (plant.plantingDate != null) ...[
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Date de plantation',
                value: DateFormat('dd/MM/yyyy', 'fr_FR').format(plant.plantingDate!),
                context: context,
              ),
              const SizedBox(height: 8),
            ],
            
            if (plant.harvestDate != null) ...[
              _buildInfoRow(
                icon: Icons.agriculture,
                label: 'Date de récolte prévue',
                value: DateFormat('dd/MM/yyyy', 'fr_FR').format(plant.harvestDate!),
                context: context,
              ),
              const SizedBox(height: 8),
            ],
            
            if (plant.daysToMaturity != null) ...[
              _buildInfoRow(
                icon: Icons.calendar_view_day,
                label: 'Jours jusqu\'à maturité',
                value: '${plant.daysToMaturity} jours',
                context: context,
              ),
              const SizedBox(height: 8),
            ],
            
            if (plant.spacing != null || plant.depth != null) ...[
              Row(
                children: [
                  if (plant.spacing != null) ...[
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.straighten,
                        label: 'Espacement',
                        value: '${plant.spacing} cm',
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (plant.depth != null) ...[
                    Expanded(
                      child: _buildInfoRow(
                        icon: Icons.vertical_align_bottom,
                        label: 'Profondeur',
                        value: '${plant.depth} cm',
                        context: context,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            
            // Categories
            if (plant.categories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plant.categories.map((category) => Chip(
                  label: Text(category.displayName),
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanionPlantsSection(Plant plant, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Plantes compagnes',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (plant.companionPlants != null) ...[
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plant.companionPlants!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            if (plant.avoidPlants != null) ...[
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plant.avoidPlants!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCareInstructionsSection(Plant plant, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.help, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Conseils de culture',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (plant.careInstructions != null) ...[
              Row(
                children: [
                  Icon(Icons.eco, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plant.careInstructions!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            if (plant.harvestInstructions != null) ...[
              Row(
                children: [
                  Icon(Icons.agriculture, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plant.harvestInstructions!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHarvestsSection(List<Harvest> harvests, double totalQuantity, double avgQuality, BuildContext context) {
    final qualityLabels = {
      4: 'Excellente',
      3: 'Bonne',
      2: 'Moyenne',
      1: 'Faible',
    };
    final qualityColors = {
      4: Colors.green,
      3: Colors.lightGreen,
      2: Colors.orange,
      1: Colors.red,
    };
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.agriculture, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Récoltes (${harvests.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/harvests'),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total récolté',
                    value: '${totalQuantity.toStringAsFixed(1)} kg',
                    icon: Icons.monitor_weight,
                    color: Colors.green,
                    context: context,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    title: 'Qualité moyenne',
                    value: qualityLabels[avgQuality.round()] ?? 'N/A',
                    icon: Icons.star,
                    color: qualityColors[avgQuality.round()] ?? Colors.grey,
                    context: context,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    title: 'Dernière récolte',
                    value: harvests.isNotEmpty 
                        ? DateFormat('dd/MM', 'fr_FR').format(harvests.first.harvestDate)
                        : 'N/A',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                    context: context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Harvests list (last 5)
            if (harvests.isNotEmpty) ...[
              Text(
                'Dernières récoltes:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...harvests.take(5).map((harvest) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.agriculture, color: Colors.green, size: 20),
                  ),
                  title: Text('${harvest.quantity} ${harvest.unit}'),
                  subtitle: Text(DateFormat('dd/MM/yyyy', 'fr_FR').format(harvest.harvestDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => _showHarvestDetail(harvest, context),
                  ),
                  onTap: () => _showHarvestDetail(harvest, context),
                  dense: true,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
      ),
    );
  }

  Widget _buildTasksSection(List<Task> tasks, BuildContext context) {
    final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).toList();
    final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.task, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Tâches associées (${tasks.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/tasks'),
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Task statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'En attente',
                    value: pendingTasks.length.toString(),
                    icon: Icons.hourglass_empty,
                    color: Colors.orange,
                    context: context,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    title: 'En cours',
                    value: inProgressTasks.length.toString(),
                    icon: Icons.play_arrow,
                    color: Colors.blue,
                    context: context,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    title: 'Terminées',
                    value: completedTasks.length.toString(),
                    icon: Icons.check_circle,
                    color: Colors.green,
                    context: context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tasks list (last 5)
            if (tasks.isNotEmpty) ...[
              Text(
                'Prochaines tâches:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...tasks.take(5).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.taskPriorityColors[task.priority]?.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      task.type.icon,
                      color: AppTheme.taskPriorityColors[task.priority],
                      size: 20,
                    ),
                  ),
                  title: Text(task.title),
                  subtitle: Text(DateFormat('dd/MM/yyyy', 'fr_FR').format(task.dueDate)),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () => context.push('/task/edit/${task.id}'),
                  ),
                  onTap: () => context.push('/task/edit/${task.id}'),
                  dense: true,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(Plant plant, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Actions rapides',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionButton(
                  icon: Icons.edit,
                  label: 'Modifier',
                  color: Colors.blue,
                  onTap: () => context.push('/plant/edit/${plant.id}'),
                ),
                _buildQuickActionButton(
                  icon: plant.isFavorite ? Icons.favorite : Icons.favorite_border,
                  label: plant.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  color: Colors.red,
                  onTap: () => context.read<PlantProvider>().toggleFavorite(plant.id),
                ),
                _buildQuickActionButton(
                  icon: plant.isActive ? Icons.cancel : Icons.check_circle,
                  label: plant.isActive ? 'Désactiver' : 'Activer',
                  color: plant.isActive ? Colors.orange : Colors.green,
                  onTap: () => context.read<PlantProvider>().toggleActive(plant.id),
                ),
                _buildQuickActionButton(
                  icon: Icons.agriculture,
                  label: 'Ajouter récolte',
                  color: Colors.green,
                  onTap: () => _showAddHarvestDialog(plant, context),
                ),
                _buildQuickActionButton(
                  icon: Icons.add_task,
                  label: 'Ajouter tâche',
                  color: Colors.blue,
                  onTap: () => _showAddTaskDialog(plant, context),
                ),
                _buildQuickActionButton(
                  icon: Icons.delete,
                  label: 'Supprimer',
                  color: Colors.red,
                  onTap: () => _confirmDeletePlant(plant, context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddHarvestDialog(Plant plant, BuildContext context) {
    final gardenProvider = context.read<GardenProvider>();
    final gardens = gardenProvider.gardens;
    
    DateTime selectedDate = DateTime.now();
    double quantity = 1.0;
    String selectedUnit = 'kg';
    String quality = 'Bonne';
    String notes = '';
    String? selectedGardenId = gardenProvider.currentGarden?.id;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Ajouter une récolte: ${plant.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    onChanged: (value) => setState(() => selectedGardenId = value),
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
                final harvestProvider = context.read<HarvestProvider>();
                
                final harvest = Harvest(
                  id: const Uuid().v4(),
                  plantId: plant.id,
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

  void _showAddTaskDialog(Plant plant, BuildContext context) {
    final gardenProvider = context.read<GardenProvider>();
    final gardens = gardenProvider.gardens;
    
    String title = 'Arroser ${plant.name}';
    String description = '';
    TaskType selectedType = TaskType.watering;
    TaskPriority selectedPriority = TaskPriority.medium;
    DateTime dueDate = DateTime.now().add(const Duration(days: 1));
    String? selectedGardenId = gardenProvider.currentGarden?.id;
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Ajouter une tâche: ${plant.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Titre *',
                    prefixIcon: Icon(Icons.title),
                  ),
                  initialValue: title,
                  onChanged: (value) => title = value,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  initialValue: description,
                  onChanged: (value) => description = value,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<TaskType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: TaskType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, color: AppTheme.taskTypeColors[type]),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => selectedType = value!,
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<TaskPriority>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priorité',
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  items: TaskPriority.values.map((priority) => DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          color: AppTheme.taskPriorityColors[priority],
                        ),
                        const SizedBox(width: 8),
                        Text(priority.displayName),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => selectedPriority = value!,
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
                
                // Due date
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Date d\'échéance *',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy – HH:mm', 'fr_FR').format(dueDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(dueDate),
                      );
                      if (time != null) {
                        setState(() {
                          dueDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  initialValue: notes,
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
                final taskProvider = context.read<TaskProvider>();
                final notificationService = context.read<NotificationService>();
                
                final task = Task(
                  id: const Uuid().v4(),
                  title: title,
                  description: description.isEmpty ? null : description,
                  type: selectedType,
                  priority: selectedPriority,
                  status: TaskStatus.pending,
                  dueDate: dueDate,
                  plantId: plant.id,
                  gardenId: selectedGardenId,
                  hasReminder: true,
                  notes: notes.isEmpty ? null : notes,
                );
                
                try {
                  await taskProvider.addTask(task);
                  await notificationService.showTaskReminderNotification(task);
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tâche "$title" ajoutée'),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePlant(Plant plant, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la plante'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${plant.name}" ? Toutes les données associées (tâches, récoltes) seront conservées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<PlantProvider>().deletePlant(plant.id);
              Navigator.pop(context);
              context.pop();
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
