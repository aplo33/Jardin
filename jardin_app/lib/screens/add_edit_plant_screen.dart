import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/plant_provider.dart';
import '../providers/garden_provider.dart';
import '../models/plant.dart';
import '../models/garden.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddEditPlantScreen extends StatefulWidget {
  final String? plantId;

  const AddEditPlantScreen({super.key, this.plantId});

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _id;
  late String _name;
  String? _scientificName;
  String? _description;
  late PlantType _type;
  List<PlantCategory> _categories = [];
  String? _imagePath;
  DateTime? _plantingDate;
  DateTime? _harvestDate;
  int? _daysToMaturity;
  late SunExposure _sunExposure;
  late WaterNeed _waterNeed;
  late SoilType _soilType;
  double? _idealPh;
  double? _spacing;
  double? _depth;
  String? _companionPlants;
  String? _avoidPlants;
  String? _careInstructions;
  String? _harvestInstructions;
  late bool _isFavorite;
  late bool _isActive;
  String? _gardenId;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _scientificNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _daysToMaturityController = TextEditingController();
  final TextEditingController _idealPhController = TextEditingController();
  final TextEditingController _spacingController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();
  final TextEditingController _companionPlantsController = TextEditingController();
  final TextEditingController _avoidPlantsController = TextEditingController();
  final TextEditingController _careInstructionsController = TextEditingController();
  final TextEditingController _harvestInstructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializePlant();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _daysToMaturityController.dispose();
    _idealPhController.dispose();
    _spacingController.dispose();
    _depthController.dispose();
    _companionPlantsController.dispose();
    _avoidPlantsController.dispose();
    _careInstructionsController.dispose();
    _harvestInstructionsController.dispose();
    super.dispose();
  }

  void _initializePlant() {
    final plantProvider = context.read<PlantProvider>();
    final gardenProvider = context.read<GardenProvider>();
    
    if (widget.plantId != null) {
      final plant = plantProvider.getPlantById(widget.plantId!);
      if (plant != null) {
        _id = plant.id;
        _name = plant.name;
        _scientificName = plant.scientificName;
        _description = plant.description;
        _type = plant.type;
        _categories = plant.categories;
        _imagePath = plant.imagePath;
        _plantingDate = plant.plantingDate;
        _harvestDate = plant.harvestDate;
        _daysToMaturity = plant.daysToMaturity;
        _sunExposure = plant.sunExposure;
        _waterNeed = plant.waterNeed;
        _soilType = plant.soilType;
        _idealPh = plant.idealPh;
        _spacing = plant.spacing;
        _depth = plant.depth;
        _companionPlants = plant.companionPlants;
        _avoidPlants = plant.avoidPlants;
        _careInstructions = plant.careInstructions;
        _harvestInstructions = plant.harvestInstructions;
        _isFavorite = plant.isFavorite;
        _isActive = plant.isActive;
        _gardenId = plant.gardenId;
        
        _nameController.text = _name;
        _scientificNameController.text = _scientificName ?? '';
        _descriptionController.text = _description ?? '';
        _daysToMaturityController.text = _daysToMaturity?.toString() ?? '';
        _idealPhController.text = _idealPh?.toString() ?? '';
        _spacingController.text = _spacing?.toString() ?? '';
        _depthController.text = _depth?.toString() ?? '';
        _companionPlantsController.text = _companionPlants ?? '';
        _avoidPlantsController.text = _avoidPlants ?? '';
        _careInstructionsController.text = _careInstructions ?? '';
        _harvestInstructionsController.text = _harvestInstructions ?? '';
      } else {
        _initializeNewPlant(gardenProvider);
      }
    } else {
      _initializeNewPlant(gardenProvider);
    }
  }

  void _initializeNewPlant(GardenProvider gardenProvider) {
    _id = const Uuid().v4();
    _name = '';
    _scientificName = null;
    _description = null;
    _type = PlantType.vegetable;
    _categories = [];
    _imagePath = null;
    _plantingDate = null;
    _harvestDate = null;
    _daysToMaturity = null;
    _sunExposure = SunExposure.fullSun;
    _waterNeed = WaterNeed.medium;
    _soilType = SoilType.loamy;
    _idealPh = null;
    _spacing = null;
    _depth = null;
    _companionPlants = null;
    _avoidPlants = null;
    _careInstructions = null;
    _harvestInstructions = null;
    _isFavorite = false;
    _isActive = true;
    _gardenId = gardenProvider.currentGarden?.id;
  }

  @override
  Widget build(BuildContext context) {
    final gardenProvider = context.watch<GardenProvider>();
    final gardens = gardenProvider.gardens;
    final isEditing = widget.plantId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier la plante' : 'Ajouter une plante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePlant,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Information
              _buildSectionHeader('Informations de base', Icons.info),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                          hintText: 'Ex: Tomate, Rose, Basilic',
                          prefixIcon: Icon(Icons.text_fields),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un nom';
                          }
                          return null;
                        },
                        onChanged: (value) => _name = value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _scientificNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom scientifique',
                          hintText: 'Ex: Solanum lycopersicum',
                          prefixIcon: Icon(Icons.science),
                        ),
                        onChanged: (value) => _scientificName = value.isEmpty ? null : value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Description de la plante',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        onChanged: (value) => _description = value.isEmpty ? null : value,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PlantType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type *',
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: PlantType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon, color: AppTheme.plantTypeColors[type]),
                              const SizedBox(width: 8),
                              Text(type.displayName),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _type = value!),
                      ),
                      const SizedBox(height: 16),
                      _buildMultiSelectChip<PlantCategory>(
                        title: 'Catégories',
                        options: PlantCategory.values,
                        selectedOptions: _categories,
                        onChanged: (options) => setState(() => _categories = options),
                        optionDisplay: (category) => category.displayName,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Garden Assignment
              _buildSectionHeader('Jardin', Icons.nature),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (gardens.isEmpty) ...[
                        Text(
                          'Aucun jardin créé. Créez un jardin d\'abord.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to create garden
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez créer un jardin d\'abord'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Créer un jardin'),
                        ),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          value: _gardenId,
                          decoration: const InputDecoration(
                            labelText: 'Jardin',
                            prefixIcon: Icon(Icons.nature),
                          ),
                          hint: const Text('Sélectionnez un jardin'),
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
                          onChanged: (value) => setState(() => _gardenId = value),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Growing Conditions
              _buildSectionHeader('Conditions de culture', Icons.eco),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<SunExposure>(
                        value: _sunExposure,
                        decoration: const InputDecoration(
                          labelText: 'Exposition au soleil',
                          prefixIcon: Icon(Icons.wb_sunny),
                        ),
                        items: SunExposure.values.map((exposure) => DropdownMenuItem(
                          value: exposure,
                          child: Row(
                            children: [
                              Icon(exposure.icon),
                              const SizedBox(width: 8),
                              Text(exposure.displayName),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _sunExposure = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<WaterNeed>(
                        value: _waterNeed,
                        decoration: const InputDecoration(
                          labelText: 'Besoin en eau',
                          prefixIcon: Icon(Icons.opacity),
                        ),
                        items: WaterNeed.values.map((need) => DropdownMenuItem(
                          value: need,
                          child: Row(
                            children: [
                              Icon(need.icon),
                              const SizedBox(width: 8),
                              Text(need.displayName),
                            ],
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _waterNeed = value!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SoilType>(
                        value: _soilType,
                        decoration: const InputDecoration(
                          labelText: 'Type de sol',
                          prefixIcon: Icon(Icons.grass),
                        ),
                        items: SoilType.values.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        )).toList(),
                        onChanged: (value) => setState(() => _soilType = value!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _idealPhController,
                        decoration: const InputDecoration(
                          labelText: 'pH idéal du sol',
                          hintText: 'Ex: 6.5',
                          prefixIcon: Icon(Icons.ph),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _idealPh = value.isEmpty ? null : double.tryParse(value),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Planting Information
              _buildSectionHeader('Informations de plantation', Icons.agriculture),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Date de plantation',
                              date: _plantingDate,
                              onChanged: (date) => setState(() => _plantingDate = date),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              label: 'Date de récolte',
                              date: _harvestDate,
                              onChanged: (date) => setState(() => _harvestDate = date),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _daysToMaturityController,
                        decoration: const InputDecoration(
                          labelText: 'Jours jusqu\'à maturité',
                          hintText: 'Ex: 60',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _daysToMaturity = value.isEmpty ? null : int.tryParse(value),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _spacingController,
                              decoration: const InputDecoration(
                                labelText: 'Espacement (cm)',
                                hintText: 'Ex: 30',
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _spacing = value.isEmpty ? null : double.tryParse(value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _depthController,
                              decoration: const InputDecoration(
                                labelText: 'Profondeur (cm)',
                                hintText: 'Ex: 5',
                                prefixIcon: Icon(Icons.vertical_align_bottom),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) => _depth = value.isEmpty ? null : double.tryParse(value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Additional Information
              _buildSectionHeader('Informations supplémentaires', Icons.notes),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _companionPlantsController,
                        decoration: const InputDecoration(
                          labelText: 'Plantes compagnes',
                          hintText: 'Ex: Carottes, Oignons',
                          prefixIcon: Icon(Icons.group),
                        ),
                        onChanged: (value) => _companionPlants = value.isEmpty ? null : value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _avoidPlantsController,
                        decoration: const InputDecoration(
                          labelText: 'Plantes à éviter',
                          hintText: 'Ex: Pommes de terre',
                          prefixIcon: Icon(Icons.do_not_disturb),
                        ),
                        onChanged: (value) => _avoidPlants = value.isEmpty ? null : value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _careInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Instructions de soin',
                          hintText: 'Ex: Arroser régulièrement, Tailler en été',
                          prefixIcon: Icon(Icons.help),
                        ),
                        maxLines: 3,
                        onChanged: (value) => _careInstructions = value.isEmpty ? null : value,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _harvestInstructionsController,
                        decoration: const InputDecoration(
                          labelText: 'Instructions de récolte',
                          hintText: 'Ex: Récolter le matin, Utiliser des ciseaux',
                          prefixIcon: Icon(Icons.agriculture),
                        ),
                        maxLines: 3,
                        onChanged: (value) => _harvestInstructions = value.isEmpty ? null : value,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status and Actions
              _buildSectionHeader('Statut', Icons.settings),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Plante favorite'),
                        value: _isFavorite,
                        onChanged: (value) => setState(() => _isFavorite = value),
                        secondary: const Icon(Icons.favorite, color: Colors.red),
                      ),
                      SwitchListTile(
                        title: const Text('Plante active'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        secondary: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: _savePlant,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save),
                        const SizedBox(width: 8),
                        Text(isEditing ? 'Enregistrer les modifications' : 'Ajouter la plante'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onChanged,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: date != null 
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => onChanged(null),
              )
            : null,
      ),
      readOnly: true,
      controller: TextEditingController(
        text: date != null ? DateFormat('dd/MM/yyyy', 'fr_FR').format(date) : '',
      ),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          locale: const Locale('fr', 'FR'),
        );
        if (pickedDate != null) {
          onChanged(pickedDate);
        }
      },
    );
  }

  Widget _buildMultiSelectChip<T>({
    required String title,
    required List<T> options,
    required List<T> selectedOptions,
    required Function(List<T>) onChanged,
    required String Function(T) optionDisplay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) => FilterChip(
            label: Text(optionDisplay(option)),
            selected: selectedOptions.contains(option),
            onSelected: (selected) {
              if (selected) {
                onChanged([...selectedOptions, option]);
              } else {
                onChanged(selectedOptions.where((o) => o != option).toList());
              }
            },
          )).toList(),
        ),
      ],
    );
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final plant = Plant(
      id: _id,
      name: _name,
      scientificName: _scientificName,
      description: _description,
      type: _type,
      categories: _categories,
      imagePath: _imagePath,
      plantingDate: _plantingDate,
      harvestDate: _harvestDate,
      daysToMaturity: _daysToMaturity,
      sunExposure: _sunExposure,
      waterNeed: _waterNeed,
      soilType: _soilType,
      idealPh: _idealPh,
      spacing: _spacing,
      depth: _depth,
      companionPlants: _companionPlants,
      avoidPlants: _avoidPlants,
      careInstructions: _careInstructions,
      harvestInstructions: _harvestInstructions,
      isFavorite: _isFavorite,
      isActive: _isActive,
      gardenId: _gardenId,
    );

    try {
      final plantProvider = context.read<PlantProvider>();
      
      if (widget.plantId != null) {
        await plantProvider.updatePlant(plant);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${plant.name}" a été mise à jour'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await plantProvider.addPlant(plant);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${plant.name}" a été ajoutée'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'enregistrement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
