import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../providers/task_provider.dart';
import '../providers/harvest_provider.dart';
import '../providers/garden_provider.dart';
import '../models/task.dart';
import '../models/plant.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    await Future.wait([
      context.read<PlantProvider>().refresh(),
      context.read<TaskProvider>().refresh(),
      context.read<HarvestProvider>().refresh(),
      context.read<GardenProvider>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final harvestProvider = context.watch<HarvestProvider>();
    final gardenProvider = context.watch<GardenProvider>();

    final pendingTasks = taskProvider.getPendingTasks();
    final overdueTasks = taskProvider.getOverdueTasks();
    final dueThisWeekTasks = taskProvider.getTasksDueThisWeek();
    final activePlants = plantProvider.getActivePlants();
    final recentHarvests = harvestProvider.getRecentHarvests(5);
    final gardens = gardenProvider.gardens;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Jardin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gardens Summary
              if (gardens.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Mes Jardins',
                  icon: Icons.nature,
                  onTap: () {},
                ),
                _buildGardensSummary(gardens, context),
                const SizedBox(height: 24),
              ],

              // Tasks Summary
              _buildSectionHeader(
                title: 'Tâches',
                icon: Icons.task,
                onTap: () => context.push('/tasks'),
              ),
              _buildTasksSummary(
                pendingTasks: pendingTasks,
                overdueTasks: overdueTasks,
                dueThisWeekTasks: dueThisWeekTasks,
                context: context,
              ),
              const SizedBox(height: 24),

              // Plants Summary
              _buildSectionHeader(
                title: 'Plantes',
                icon: Icons.eco,
                onTap: () => context.push('/plants'),
              ),
              _buildPlantsSummary(activePlants, context),
              const SizedBox(height: 24),

              // Recent Harvests
              if (recentHarvests.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Dernières Récoltes',
                  icon: Icons.agriculture,
                  onTap: () => context.push('/harvests'),
                ),
                _buildRecentHarvests(recentHarvests, context),
                const SizedBox(height: 24),
              ],

              // Quick Actions
              _buildSectionHeader(
                title: 'Actions Rapides',
                icon: Icons.bolt,
                onTap: () {},
              ),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddMenu(context),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: const Text('Voir tout'),
        ),
      ],
    );
  }

  Widget _buildGardensSummary(List<Garden> gardens, BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: gardens.length,
        itemBuilder: (context, index) {
          final garden = gardens[index];
          return GestureDetector(
            onTap: () => context.read<GardenProvider>().setCurrentGarden(garden.id),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.gardenTypeColors[garden.type]?.withOpacity(0.2),
                border: Border.all(
                  color: AppTheme.gardenTypeColors[garden.type] ?? Colors.grey,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      garden.type.icon,
                      color: AppTheme.gardenTypeColors[garden.type],
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      garden.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${garden.area} m²',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          garden.isActive ? Icons.check_circle : Icons.cancel,
                          color: garden.isActive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          garden.isActive ? 'Actif' : 'Inactif',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: garden.isActive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTasksSummary({
    required List<Task> pendingTasks,
    required List<Task> overdueTasks,
    required List<Task> dueThisWeekTasks,
    required BuildContext context,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildTaskStat(
                  title: 'En attente',
                  count: pendingTasks.length,
                  color: AppTheme.taskStatusColors[TaskStatus.pending]!,
                  icon: Icons.hourglass_empty,
                  context: context,
                ),
                const VerticalDivider(width: 16),
                _buildTaskStat(
                  title: 'En retard',
                  count: overdueTasks.length,
                  color: AppTheme.taskStatusColors[TaskStatus.cancelled]!,
                  icon: Icons.warning,
                  context: context,
                ),
                const VerticalDivider(width: 16),
                _buildTaskStat(
                  title: 'Cette semaine',
                  count: dueThisWeekTasks.length,
                  color: AppTheme.taskPriorityColors[TaskPriority.high]!,
                  icon: Icons.calendar_today,
                  context: context,
                ),
              ],
            ),
            if (overdueTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Tâches en retard:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...overdueTasks.take(3).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    task.type.icon,
                    color: AppTheme.taskTypeColors[task.type],
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    'Échéance: ${DateFormat('dd MMM yyyy', 'fr_FR').format(task.dueDate)}',
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () => context.push('/task/edit/${task.id}'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  dense: true,
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStat({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required BuildContext context,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  Widget _buildPlantsSummary(List<Plant> plants, BuildContext context) {
    final plantsByType = <PlantType, int>{};
    for (var plant in plants) {
      plantsByType.update(plant.type, (value) => value + 1, ifAbsent: () => 1);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Total: ${plants.length} plantes actives',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: PlantType.values.map((type) {
                  final count = plantsByType[type] ?? 0;
                  if (count == 0) return const SizedBox();
                  
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Icon(
                          type.icon,
                          color: AppTheme.plantTypeColors[type],
                          size: 32,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          count.toString(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          type.displayName,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHarvests(List<Harvest> harvests, BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: harvests.map((harvest) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.agriculture, color: Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        harvest.plantName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${harvest.quantity} ${harvest.unit} - ${DateFormat('dd MMM yyyy', 'fr_FR').format(harvest.harvestDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: [
            _buildQuickActionButton(
              icon: Icons.add,
              label: 'Ajouter Plante',
              color: Colors.green,
              onTap: () => context.push('/plant/add'),
            ),
            _buildQuickActionButton(
              icon: Icons.add_task,
              label: 'Ajouter Tâche',
              color: Colors.blue,
              onTap: () => context.push('/task/add'),
            ),
            _buildQuickActionButton(
              icon: Icons.agriculture,
              label: 'Ajouter Récolte',
              color: Colors.orange,
              onTap: () {},
            ),
            _buildQuickActionButton(
              icon: Icons.calendar_today,
              label: 'Calendrier',
              color: Colors.purple,
              onTap: () => context.push('/calendar'),
            ),
            _buildQuickActionButton(
              icon: Icons.nature,
              label: 'Jardins',
              color: Colors.teal,
              onTap: () {},
            ),
            _buildQuickActionButton(
              icon: Icons.settings,
              label: 'Paramètres',
              color: Colors.grey,
              onTap: () => context.push('/settings'),
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

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.eco, color: Colors.green),
              title: const Text('Ajouter une plante'),
              onTap: () {
                Navigator.pop(context);
                context.push('/plant/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_task, color: Colors.blue),
              title: const Text('Ajouter une tâche'),
              onTap: () {
                Navigator.pop(context);
                context.push('/task/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.agriculture, color: Colors.orange),
              title: const Text('Ajouter une récolte'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add harvest screen navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.nature, color: Colors.teal),
              title: const Text('Ajouter un jardin'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add garden screen navigation
              },
            ),
          ],
        ),
      ),
    );
  }
}
