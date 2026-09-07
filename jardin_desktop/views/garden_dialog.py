"""
Boîte de dialogue pour ajouter/modifier un jardin.
"""

from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QFormLayout, QLabel,
    QLineEdit, QTextEdit, QPushButton, QDoubleSpinBox,
    QListWidget, QMessageBox
)
from PyQt6.QtCore import Qt
from typing import Optional, List

from ..models.garden import Garden
from ..database.database_manager import DatabaseManager
from ..models.plant import Plant
from ..utils.helpers import generate_id


class GardenDialog(QDialog):
    """
    Boîte de dialogue pour ajouter ou modifier un jardin.
    """
    
    def __init__(self, parent, garden: Optional[Garden] = None, db_manager: Optional[DatabaseManager] = None):
        """
        Initialise la boîte de dialogue.
        
        Args:
            parent: Widget parent.
            garden: Jardin à modifier (None pour un nouveau jardin).
            db_manager: Gestionnaire de la base de données.
        """
        super().__init__(parent)
        self.db = db_manager
        self.garden = garden
        self.setWindowTitle("Ajouter un jardin" if garden is None else "Modifier le jardin")
        self.setMinimumSize(600, 500)
        
        # Initialiser l'interface
        self._init_ui()
        
        # Charger les données si on modifie un jardin existant
        if garden:
            self._load_garden_data()
    
    def _init_ui(self) -> None:
        """Initialise l'interface utilisateur."""
        layout = QVBoxLayout(self)
        
        # Formulaire
        form_layout = QFormLayout()
        form_layout.setFieldGrowthPolicy(QFormLayout.FieldGrowthPolicy.AllNonFixedFieldsGrow)
        form_layout.setFormAlignment(Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignTop)
        form_layout.setLabelAlignment(Qt.AlignmentFlag.AlignRight)
        
        # Nom
        self.name_edit = QLineEdit()
        self.name_edit.setPlaceholderText("Ex: Potager arrière, Jardin devant")
        form_layout.addRow("Nom *:", self.name_edit)
        
        # Description
        self.description_edit = QTextEdit()
        self.description_edit.setPlaceholderText("Description du jardin...")
        self.description_edit.setMaximumHeight(80)
        form_layout.addRow("Description:", self.description_edit)
        
        # Emplacement
        self.location_edit = QLineEdit()
        self.location_edit.setPlaceholderText("Ex: À l'est de la maison")
        form_layout.addRow("Emplacement:", self.location_edit)
        
        # Surface (en m²)
        self.area_spin = QDoubleSpinBox()
        self.area_spin.setRange(0.1, 10000.0)
        self.area_spin.setValue(10.0)
        self.area_spin.setDecimals(1)
        self.area_spin.setSuffix(" m²")
        form_layout.addRow("Surface:", self.area_spin)
        
        # Notes
        self.notes_edit = QTextEdit()
        self.notes_edit.setPlaceholderText("Notes supplémentaires...")
        self.notes_edit.setMaximumHeight(80)
        form_layout.addRow("Notes:", self.notes_edit)
        
        layout.addLayout(form_layout)
        
        # Sélection des plantes
        plants_label = QLabel("Plantes associées:")
        layout.addWidget(plants_label)
        
        # Liste des plantes disponibles
        self.available_plants_list = QListWidget()
        self.available_plants_list.setSelectionMode(QListWidget.SelectionMode.MultiSelection)
        
        if self.db:
            plants = self.db.get_all_plants()
            for plant in plants:
                item = f"{plant.name} ({plant.plant_type.value})"
                self.available_plants_list.addItem(item)
        
        layout.addWidget(self.available_plants_list)
        
        # Boutons pour gérer les plantes
        plants_button_layout = QHBoxLayout()
        
        add_plants_btn = QPushButton("Ajouter les plantes sélectionnées")
        add_plants_btn.clicked.connect(self._add_selected_plants)
        plants_button_layout.addWidget(add_plants_btn)
        
        remove_plants_btn = QPushButton("Retirer les plantes sélectionnées")
        remove_plants_btn.clicked.connect(self._remove_selected_plants)
        plants_button_layout.addWidget(remove_plants_btn)
        
        layout.addLayout(plants_button_layout)
        
        # Liste des plantes associées au jardin
        self.garden_plants_list = QListWidget()
        self.garden_plants_list.setSelectionMode(QListWidget.SelectionMode.MultiSelection)
        layout.addWidget(self.garden_plants_list)
        
        # Boutons
        button_layout = QHBoxLayout()
        
        save_btn = QPushButton("Sauvegarder")
        save_btn.clicked.connect(self._save_garden)
        button_layout.addWidget(save_btn)
        
        cancel_btn = QPushButton("Annuler")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)
        
        button_layout.addStretch()
        layout.addLayout(button_layout)
        
        # Stocker les IDs des plantes
        self.available_plant_ids = {}
        self.garden_plant_ids = []
        
        if self.db:
            plants = self.db.get_all_plants()
            for i, plant in enumerate(plants):
                self.available_plant_ids[i] = plant.id
    
    def _load_garden_data(self) -> None:
        """Charge les données du jardin dans les champs du formulaire."""
        if self.garden:
            self.name_edit.setText(self.garden.name)
            self.description_edit.setText(self.garden.description)
            self.location_edit.setText(self.garden.location)
            self.area_spin.setValue(self.garden.area)
            self.notes_edit.setText(self.garden.notes)
            
            # Charger les plantes associées
            for plant in self.garden.plants:
                item = f"{plant.name} ({plant.plant_type.value})"
                self.garden_plants_list.addItem(item)
                self.garden_plant_ids.append(plant.id)
    
    def _add_selected_plants(self) -> None:
        """Ajoute les plantes sélectionnées au jardin."""
        selected_items = self.available_plants_list.selectedItems()
        if not selected_items:
            return
        
        for item in selected_items:
            row = self.available_plants_list.row(item)
            plant_id = self.available_plant_ids.get(row)
            
            if plant_id and plant_id not in self.garden_plant_ids:
                # Ajouter à la liste du jardin
                self.garden_plants_list.addItem(item.text())
                self.garden_plant_ids.append(plant_id)
    
    def _remove_selected_plants(self) -> None:
        """Retire les plantes sélectionnées du jardin."""
        selected_rows = [self.garden_plants_list.row(item) for item in self.garden_plants_list.selectedItems()]
        
        for row in sorted(selected_rows, reverse=True):
            self.garden_plants_list.takeItem(row)
            if row < len(self.garden_plant_ids):
                self.garden_plant_ids.pop(row)
    
    def _save_garden(self) -> None:
        """Sauvegarde les données du jardin."""
        # Valider les champs obligatoires
        if not self.name_edit.text().strip():
            QMessageBox.warning(
                self, "Erreur",
                "Le champ 'Nom' est obligatoire."
            )
            return
        
        # Créer ou mettre à jour le jardin
        if self.garden is None:
            # Nouveau jardin
            self.garden = Garden(
                id=generate_id(),
                name=self.name_edit.text().strip(),
                description=self.description_edit.toPlainText().strip(),
                location=self.location_edit.text().strip(),
                area=self.area_spin.value(),
                notes=self.notes_edit.toPlainText().strip(),
            )
            
            # Ajouter les plantes sélectionnées
            if self.db:
                for plant_id in self.garden_plant_ids:
                    plant = self.db.get_plant_by_id(plant_id)
                    if plant:
                        self.garden.add_plant(plant)
                
                self.db.add_garden(self.garden)
        else:
            # Jardin existant
            self.garden.name = self.name_edit.text().strip()
            self.garden.description = self.description_edit.toPlainText().strip()
            self.garden.location = self.location_edit.text().strip()
            self.garden.area = self.area_spin.value()
            self.garden.notes = self.notes_edit.toPlainText().strip()
            
            # Mettre à jour les plantes associées
            if self.db:
                self.garden.plants.clear()
                for plant_id in self.garden_plant_ids:
                    plant = self.db.get_plant_by_id(plant_id)
                    if plant:
                        self.garden.add_plant(plant)
                
                self.db.update_garden(self.garden)
        
        # Accepter la dialogue
        self.accept()
