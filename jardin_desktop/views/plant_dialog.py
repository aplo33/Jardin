"""
Boîte de dialogue pour ajouter/modifier une plante.
"""

from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QFormLayout, QLabel,
    QLineEdit, QComboBox, QTextEdit, QPushButton, QDateEdit,
    QSpinBox, QMessageBox, QFileDialog
)
from PyQt6.QtCore import Qt, QDate
from PyQt6.QtGui import QPixmap
from typing import Optional
from datetime import date

from ..models.plant import Plant, PlantType, SoilType, SunExposure
from ..database.database_manager import DatabaseManager
from ..utils.helpers import generate_id


class PlantDialog(QDialog):
    """
    Boîte de dialogue pour ajouter ou modifier une plante.
    """
    
    def __init__(self, parent, plant: Optional[Plant] = None, db_manager: Optional[DatabaseManager] = None):
        """
        Initialise la boîte de dialogue.
        
        Args:
            parent: Widget parent.
            plant: Plante à modifier (None pour une nouvelle plante).
            db_manager: Gestionnaire de la base de données.
        """
        super().__init__(parent)
        self.db = db_manager
        self.plant = plant
        self.setWindowTitle("Ajouter une plante" if plant is None else "Modifier la plante")
        self.setMinimumSize(500, 600)
        
        # Initialiser l'interface
        self._init_ui()
        
        # Charger les données si on modifie une plante existante
        if plant:
            self._load_plant_data()
    
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
        self.name_edit.setPlaceholderText("Ex: Tomate Cerise")
        form_layout.addRow("Nom *:", self.name_edit)
        
        # Description
        self.description_edit = QTextEdit()
        self.description_edit.setPlaceholderText("Description de la plante...")
        self.description_edit.setMaximumHeight(100)
        form_layout.addRow("Description:", self.description_edit)
        
        # Type de plante
        self.type_combo = QComboBox()
        self.type_combo.addItems([t.value for t in PlantType])
        form_layout.addRow("Type *:", self.type_combo)
        
        # Variété
        self.variety_edit = QLineEdit()
        self.variety_edit.setPlaceholderText("Ex: Cerise, Roma, etc.")
        form_layout.addRow("Variété:", self.variety_edit)
        
        # Date de plantation
        self.planting_date_edit = QDateEdit()
        self.planting_date_edit.setCalendarPopup(True)
        self.planting_date_edit.setDate(QDate.currentDate())
        form_layout.addRow("Date de plantation:", self.planting_date_edit)
        
        # Date de récolte
        self.harvest_date_edit = QDateEdit()
        self.harvest_date_edit.setCalendarPopup(True)
        self.harvest_date_edit.setDate(QDate.currentDate())
        form_layout.addRow("Date de récolte:", self.harvest_date_edit)
        
        # Type de sol
        self.soil_combo = QComboBox()
        self.soil_combo.addItems([s.value for s in SoilType])
        form_layout.addRow("Type de sol:", self.soil_combo)
        
        # Exposition au soleil
        self.sun_combo = QComboBox()
        self.sun_combo.addItems([s.value for s in SunExposure])
        form_layout.addRow("Exposition au soleil:", self.sun_combo)
        
        # Fréquence d'arrosage (en jours)
        self.watering_spin = QSpinBox()
        self.watering_spin.setRange(1, 30)
        self.watering_spin.setValue(7)
        self.watering_spin.setSuffix(" jours")
        form_layout.addRow("Fréquence d'arrosage:", self.watering_spin)
        
        # Date du dernier arrosage
        self.last_watering_edit = QDateEdit()
        self.last_watering_edit.setCalendarPopup(True)
        self.last_watering_edit.setDate(QDate.currentDate())
        form_layout.addRow("Dernier arrosage:", self.last_watering_edit)
        
        # Image
        self.image_path_edit = QLineEdit()
        self.image_path_edit.setPlaceholderText("Chemin vers l'image...")
        browse_btn = QPushButton("Parcourir...")
        browse_btn.clicked.connect(self._browse_image)
        image_layout = QHBoxLayout()
        image_layout.addWidget(self.image_path_edit)
        image_layout.addWidget(browse_btn)
        form_layout.addRow("Image:", image_layout)
        
        # Aperçu de l'image
        self.image_preview = QLabel()
        self.image_preview.setFixedHeight(150)
        self.image_preview.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.image_preview.setStyleSheet("background-color: #f0f0f0; border: 1px solid #ccc;")
        form_layout.addRow("Aperçu:", self.image_preview)
        
        # Notes
        self.notes_edit = QTextEdit()
        self.notes_edit.setPlaceholderText("Notes supplémentaires...")
        self.notes_edit.setMaximumHeight(100)
        form_layout.addRow("Notes:", self.notes_edit)
        
        layout.addLayout(form_layout)
        
        # Boutons
        button_layout = QHBoxLayout()
        
        save_btn = QPushButton("Sauvegarder")
        save_btn.clicked.connect(self._save_plant)
        button_layout.addWidget(save_btn)
        
        cancel_btn = QPushButton("Annuler")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)
        
        button_layout.addStretch()
        layout.addLayout(button_layout)
    
    def _load_plant_data(self) -> None:
        """Charge les données de la plante dans les champs du formulaire."""
        if self.plant:
            self.name_edit.setText(self.plant.name)
            self.description_edit.setText(self.plant.description)
            self.type_combo.setCurrentText(self.plant.plant_type.value)
            self.variety_edit.setText(self.plant.variety)
            
            if self.plant.planting_date:
                self.planting_date_edit.setDate(
                    QDate(self.plant.planting_date.year, self.plant.planting_date.month, self.plant.planting_date.day)
                )
            
            if self.plant.harvest_date:
                self.harvest_date_edit.setDate(
                    QDate(self.plant.harvest_date.year, self.plant.harvest_date.month, self.plant.harvest_date.day)
                )
            
            self.soil_combo.setCurrentText(self.plant.soil_type.value)
            self.sun_combo.setCurrentText(self.plant.sun_exposure.value)
            self.watering_spin.setValue(self.plant.watering_frequency)
            
            if self.plant.last_watering:
                self.last_watering_edit.setDate(
                    QDate(self.plant.last_watering.year, self.plant.last_watering.month, self.plant.last_watering.day)
                )
            
            if self.plant.image_path:
                self.image_path_edit.setText(self.plant.image_path)
                self._load_image_preview(self.plant.image_path)
            
            self.notes_edit.setText(self.plant.notes)
    
    def _browse_image(self) -> None:
        """Ouvre une boîte de dialogue pour sélectionner une image."""
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Sélectionner une image", "",
            "Images (*.png *.jpg *.jpeg *.bmp *.gif)"
        )
        
        if file_path:
            self.image_path_edit.setText(file_path)
            self._load_image_preview(file_path)
    
    def _load_image_preview(self, image_path: str) -> None:
        """Charge l'aperçu de l'image."""
        pixmap = QPixmap(image_path)
        if not pixmap.isNull():
            # Redimensionner l'image pour l'aperçu
            scaled_pixmap = pixmap.scaled(
                self.image_preview.width(), self.image_preview.height(),
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation
            )
            self.image_preview.setPixmap(scaled_pixmap)
        else:
            self.image_preview.setText("Impossible de charger l'image")
    
    def _save_plant(self) -> None:
        """Sauvegarde les données de la plante."""
        # Valider les champs obligatoires
        if not self.name_edit.text().strip():
            QMessageBox.warning(
                self, "Erreur",
                "Le champ 'Nom' est obligatoire."
            )
            return
        
        # Créer ou mettre à jour la plante
        if self.plant is None:
            # Nouvelle plante
            self.plant = Plant(
                id=generate_id(),
                name=self.name_edit.text().strip(),
                description=self.description_edit.toPlainText().strip(),
                plant_type=PlantType(self.type_combo.currentText()),
                variety=self.variety_edit.text().strip(),
                planting_date=self.planting_date_edit.date().toPython() if self.planting_date_edit.date().isValid() else None,
                harvest_date=self.harvest_date_edit.date().toPython() if self.harvest_date_edit.date().isValid() else None,
                soil_type=SoilType(self.soil_combo.currentText()),
                sun_exposure=SunExposure(self.sun_combo.currentText()),
                watering_frequency=self.watering_spin.value(),
                last_watering=self.last_watering_edit.date().toPython() if self.last_watering_edit.date().isValid() else None,
                notes=self.notes_edit.toPlainText().strip(),
                image_path=self.image_path_edit.text().strip() if self.image_path_edit.text().strip() else None,
            )
            
            if self.db:
                self.db.add_plant(self.plant)
        else:
            # Plante existante
            self.plant.name = self.name_edit.text().strip()
            self.plant.description = self.description_edit.toPlainText().strip()
            self.plant.plant_type = PlantType(self.type_combo.currentText())
            self.plant.variety = self.variety_edit.text().strip()
            self.plant.planting_date = self.planting_date_edit.date().toPython() if self.planting_date_edit.date().isValid() else None
            self.plant.harvest_date = self.harvest_date_edit.date().toPython() if self.harvest_date_edit.date().isValid() else None
            self.plant.soil_type = SoilType(self.soil_combo.currentText())
            self.plant.sun_exposure = SunExposure(self.sun_combo.currentText())
            self.plant.watering_frequency = self.watering_spin.value()
            self.plant.last_watering = self.last_watering_edit.date().toPython() if self.last_watering_edit.date().isValid() else None
            self.plant.notes = self.notes_edit.toPlainText().strip()
            self.plant.image_path = self.image_path_edit.text().strip() if self.image_path_edit.text().strip() else None
            
            if self.db:
                self.db.update_plant(self.plant)
        
        # Accepter la dialogue
        self.accept()
