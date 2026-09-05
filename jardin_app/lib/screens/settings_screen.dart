import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../providers/task_provider.dart';
import '../providers/harvest_provider.dart';
import '../providers/garden_provider.dart';
import '../models/garden.dart';
import '../utils/theme.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final harvestProvider = context.watch<HarvestProvider>();
    final gardenProvider = context.watch<GardenProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statistics
            _buildSectionHeader('Statistiques', Icons.analytics),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow(
                      label: 'Nombre total de plantes',
                      value: plantProvider.plants.length.toString(),
                      icon: Icons.eco,
                      context: context,
                    ),
                    const Divider(height: 1),
                    _buildStatRow(
                      label: 'Nombre de jardins',
                      value: gardenProvider.gardens.length.toString(),
                      icon: Icons.nature,
                      context: context,
                    ),
                    const Divider(height: 1),
                    _buildStatRow(
                      label: 'Nombre total de tâches',
                      value: taskProvider.tasks.length.toString(),
                      icon: Icons.task,
                      context: context,
                    ),
                    const Divider(height: 1),
                    _buildStatRow(
                      label: 'Nombre total de récoltes',
                      value: harvestProvider.harvests.length.toString(),
                      icon: Icons.agriculture,
                      context: context,
                    ),
                    const Divider(height: 1),
                    _buildStatRow(
                      label: 'Tâches en attente',
                      value: taskProvider.getPendingTasks().length.toString(),
                      icon: Icons.hourglass_empty,
                      context: context,
                    ),
                    const Divider(height: 1),
                    _buildStatRow(
                      label: 'Tâches en retard',
                      value: taskProvider.getOverdueTasks().length.toString(),
                      icon: Icons.warning,
                      context: context,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Gardens Management
            _buildSectionHeader('Gestion des jardins', Icons.nature),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Jardin actuel: ${gardenProvider.currentGarden?.name ?? "Aucun"}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddGardenDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un jardin'),
                    ),
                    const SizedBox(height: 8),
                    if (gardenProvider.gardens.isNotEmpty) ...[
                      Text(
                        'Mes jardins:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...gardenProvider.gardens.map((garden) => Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(garden.type.icon, color: AppTheme.gardenTypeColors[garden.type]),
                          title: Text(garden.name),
                          subtitle: Text('${garden.area} m² - ${garden.type.displayName}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (gardenProvider.currentGarden?.id == garden.id)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Actuel',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _showEditGardenDialog(garden, context),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () => _confirmDeleteGarden(garden, context),
                              ),
                            ],
                          ),
                          onTap: () => gardenProvider.setCurrentGarden(garden.id),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Data Management
            _buildSectionHeader('Gestion des données', Icons.storage),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup, color: Colors.blue),
                      title: const Text('Sauvegarder les données'),
                      subtitle: const Text('Exportez toutes vos données'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showBackupDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.green),
                      title: const Text('Restaurer les données'),
                      subtitle: const Text('Importez une sauvegarde'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showRestoreDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text('Supprimer toutes les données'),
                      subtitle: const Text('Attention: action irréversible'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _confirmDeleteAllData(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notifications
            _buildSectionHeader('Notifications', Icons.notifications),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_active, color: Colors.orange),
                      title: const Text('Notifications des tâches'),
                      subtitle: const Text('Recevez des rappels pour vos tâches'),
                      trailing: Switch(
                        value: true, // TODO: Get from settings
                        onChanged: (value) {
                          // TODO: Update notification settings
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.alarm, color: Colors.blue),
                      title: const Text('Rappels quotidiens'),
                      subtitle: const Text('Rappel quotidien pour l\'arrosage'),
                      trailing: Switch(
                        value: false, // TODO: Get from settings
                        onChanged: (value) {
                          // TODO: Update daily reminder settings
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Information
            _buildSectionHeader('À propos', Icons.info),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.app_settings_alt),
                      title: const Text('Version de l\'application'),
                      subtitle: const Text('1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.developer_mode),
                      title: const Text('Développeur'),
                      subtitle: const Text('Jardin App'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Politique de confidentialité'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showPrivacyDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required IconData icon,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
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

  void _showAddGardenDialog(BuildContext context) {
    final gardenProvider = context.read<GardenProvider>();
    
    String name = '';
    String? description;
    GardenType type = GardenType.vegetableGarden;
    double area = 10.0;
    String? location;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Ajouter un jardin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    hintText: 'Ex: Mon potager, Jardin d\'agrément',
                    prefixIcon: Icon(Icons.text_fields),
                  ),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Description du jardin',
                    prefixIcon: Icon(Icons.description),
                  ),
                  onChanged: (value) => description = value.isEmpty ? null : value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GardenType>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Type *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: GardenType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, color: AppTheme.gardenTypeColors[t]),
                        const SizedBox(width: 8),
                        Text(t.displayName),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => setState(() => type = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Surface (m²) *',
                    hintText: 'Ex: 10',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: area.toString()),
                  onChanged: (value) => area = double.tryParse(value) ?? 0.0,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Emplacement',
                    hintText: 'Ex: Arrière-cour, Balcon',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  onChanged: (value) => location = value.isEmpty ? null : value,
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
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer un nom'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final garden = Garden(
                  id: const Uuid().v4(),
                  name: name,
                  description: description,
                  type: type,
                  area: area,
                  location: location,
                  isActive: true,
                );
                
                try {
                  await gardenProvider.addGarden(garden);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jardin "$name" ajouté'),
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

  void _showEditGardenDialog(Garden garden, BuildContext context) {
    String name = garden.name;
    String? description = garden.description;
    GardenType type = garden.type;
    double area = garden.area;
    String? location = garden.location;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Modifier: ${garden.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    prefixIcon: Icon(Icons.text_fields),
                  ),
                  onChanged: (value) => name = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: description ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  onChanged: (value) => description = value.isEmpty ? null : value,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GardenType>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Type *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: GardenType.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Row(
                      children: [
                        Icon(t.icon, color: AppTheme.gardenTypeColors[t]),
                        const SizedBox(width: 8),
                        Text(t.displayName),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) => setState(() => type = value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: area.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Surface (m²) *',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => area = double.tryParse(value) ?? 0.0,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: location ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Emplacement',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  onChanged: (value) => location = value.isEmpty ? null : value,
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
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez entrer un nom'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final updatedGarden = garden.copyWith(
                  name: name,
                  description: description,
                  type: type,
                  area: area,
                  location: location,
                );
                
                try {
                  await gardenProvider.updateGarden(updatedGarden);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Jardin "$name" mis à jour'),
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

  void _confirmDeleteGarden(Garden garden, BuildContext context) {
    final gardenProvider = context.read<GardenProvider>();
    final plantProvider = context.read<PlantProvider>();
    final taskProvider = context.read<TaskProvider>();
    final harvestProvider = context.read<HarvestProvider>();
    
    // Check if garden has any associated data
    final plantsInGarden = plantProvider.getPlantsByGarden(garden.id);
    final tasksInGarden = taskProvider.getTasksByGarden(garden.id);
    final harvestsInGarden = harvestProvider.getHarvestsByGarden(garden.id);
    
    final hasData = plantsInGarden.isNotEmpty || tasksInGarden.isNotEmpty || harvestsInGarden.isNotEmpty;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le jardin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Êtes-vous sûr de vouloir supprimer "${garden.name}" ?'),
            if (hasData) ...[
              const SizedBox(height: 16),
              Text(
                'Ce jardin contient:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (plantsInGarden.isNotEmpty)
                Text('• ${plantsInGarden.length} plante(s)'),
              if (tasksInGarden.isNotEmpty)
                Text('• ${tasksInGarden.length} tâche(s)'),
              if (harvestsInGarden.isNotEmpty)
                Text('• ${harvestsInGarden.length} récolte(s)'),
              const SizedBox(height: 8),
              Text(
                'Les données associées ne seront pas supprimées.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await gardenProvider.deleteGarden(garden.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Jardin "${garden.name}" supprimé'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder les données'),
        content: const Text(
          'Cette fonctionnalité permettra d\'exporter toutes vos données (plantes, tâches, récoltes, jardins) dans un fichier.\n\nFonctionnalité à venir dans une prochaine mise à jour.',
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

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer les données'),
        content: const Text(
          'Cette fonctionnalité permettra d\'importer vos données depuis un fichier de sauvegarde.\n\nFonctionnalité à venir dans une prochaine mise à jour.',
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

  void _confirmDeleteAllData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous ABSOLUMENT sûr de vouloir supprimer TOUTES vos données ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette action supprimera:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Toutes les plantes'),
            const Text('• Toutes les tâches'),
            const Text('• Toutes les récoltes'),
            const Text('• Tous les jardins'),
            const SizedBox(height: 8),
            const Text(
              'Cette action est IRRÉVERSIBLE !',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete all data
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité à venir'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('TOUT SUPPRIMER'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cette application ne collecte aucune donnée personnelle.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('Toutes vos données sont stockées localement sur votre appareil.'),
              SizedBox(height: 8),
              Text('Nous ne partageons aucune information avec des tiers.'),
              SizedBox(height: 8),
              Text('Vous êtes responsable de la sauvegarde de vos données.'),
              SizedBox(height: 16),
              Text(
                'Pour toute question, contactez le développeur.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
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
}
