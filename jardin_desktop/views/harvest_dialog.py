"""
Boîte de dialogue pour ajouter/modifier une récolte.
"""

from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QFormLayout, QLabel,
    QLineEdit, QComboBox, QTextEdit, QPushButton, QDateEdit,
    QDoubleSpinBox, QMessageBox, QFileDialog
)
from PyQt6.QtCore import Qt, QDate
from PyQt6.QtGui import QPixmap
from typing import Optional
from datetime import date

from ..models.harvest import Harvest
from ..database.database_manager import DatabaseManager
from ..models.plant import Plant
from ..utils.helpers import generate_id


class HarvestDialog(QDialog):
    """
    Boîte de dialogue pour ajouter ou modifier une récolte.
    """
    
    def __init__(self, parent, harvest: Optional[Harvest] = None, db_manager: Optional[DatabaseManager] = None):
        """
        Initialise la boîte de dialogue.
        
        Args:
            parent: Widget parent.
            harvest: Récolte à modifier (None pour une nouvelle récolte).
            db_manager: Gestionnaire de la base de données.
        """
        super().__init__(parent)
        self.db = db_manager
        self.harvest = harvest
        self.setWindowTitle("Ajouter une récolte" if harvest is None else "Modifier la récolte")
        self.setMinimumSize(500, 400)
        
        # Initialiser l'interface
        self._init_ui()
        
        # Charger les données si on modifie une récolte existante
        if harvest:
            self._load_harvest_data()
    
    def _init_ui(self) -> None:
        """Initialise l'interface utilisateur."""
        layout = QVBoxLayout(self)
        
        # Formulaire
        form_layout = QFormLayout()
        form_layout.setFieldGrowthPolicy(QFormLayout.FieldGrowthPolicy.AllNonFixedFieldsGrow)
        form_layout.setFormAlignment(Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignTop)
        form_layout.setLabelAlignment(Qt.AlignmentFlag.AlignRight)
        
        # Plante associée (obligatoire)
        self.plant_combo = QComboBox()
        if self.db:
            plants = self.db.get_all_plants()
            for plant in plants:
                self.plant_combo.addItem(f"{plant.name} ({plant.plant_type.value})", plant.id)
        form_layout.addRow("Plante *:", self.plant_combo)
        
        # Date de récolte
        self.date_edit = QDateEdit()
        self.date_edit.setCalendarPopup(True)
        self.date_edit.setDate(QDate.currentDate())
        form_layout.addRow("Date de récolte *:", self.date_edit)
        
        # Quantité
        self.quantity_spin = QDoubleSpinBox()
        self.quantity_spin.setRange(0.01, 1000.0)
        self.quantity_spin.setValue(1.0)
        self.quantity_spin.setDecimals(2)
        form_layout.addRow("Quantité *:", self.quantity_spin)
        
        # Unité
        self.unit_combo = QComboBox()
        self.unit_combo.addItems(["kg", "g", "pièce", "botte", "panier", "autre"])
        form_layout.addRow("Unité:", self.unit_combo)
        
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
        self.notes_edit.setPlaceholderText("Notes sur la récolte...")
        self.notes_edit.setMaximumHeight(80)
        form_layout.addRow("Notes:", self.notes_edit)
        
        layout.addLayout(form_layout)
        
        # Boutons
        button_layout = QHBoxLayout()
        
        save_btn = QPushButton("Sauvegarder")
        save_btn.clicked.connect(self._save_harvest)
        button_layout.addWidget(save_btn)
        
        cancel_btn = QPushButton("Annuler")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)
        
        button_layout.addStretch()
        layout.addLayout(button_layout)
    
    def _load_harvest_data(self) -> None:
        """Charge les données de la récolte dans les champs du formulaire."""
        if self.harvest:
            # Sélectionner la plante associée
            index = self.plant_combo.findData(self.harvest.plant_id)
            if index >= 0:
                self.plant_combo.setCurrentIndex(index)
            
            self.date_edit.setDate(
                QDate(self.harvest.date.year, self.harvest.date.month, self.harvest.date.day)
            )
            
            self.quantity_spin.setValue(self.harvest.quantity)
            
            unit_index = self.unit_combo.findText(self.harvest.unit)
            if unit_index >= 0:
                self.unit_combo.setCurrentIndex(unit_index)
            
            if self.harvest.image_path:
                self.image_path_edit.setText(self.harvest.image_path)
                self._load_image_preview(self.harvest.image_path)
            
            self.notes_edit.setText(self.harvest.notes)
    
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
    
    def _save_harvest(self) -> None:
        """Sauvegarde les données de la récolte."""
        # Valider les champs obligatoires
        if self.plant_combo.currentIndex() < 0:
            QMessageBox.warning(
                self, "Erreur",
                "Veuillez sélectionner une plante."
            )
            return
        
        if not self.date_edit.date().isValid():
            QMessageBox.warning(
                self, "Erreur",
                "Veuillez spécifier une date de récolte valide."
            )
            return
        
        if self.quantity_spin.value() <= 0:
            QMessageBox.warning(
                self, "Erreur",
                "La quantité doit être supérieure à 0."
            )
            return
        
        # Créer ou mettre à jour la récolte
        if self.harvest is None:
            # Nouvelle récolte
            self.harvest = Harvest(
                id=generate_id(),
                plant_id=int(self.plant_combo.currentData()),
                date=self.date_edit.date().toPython(),
                quantity=self.quantity_spin.value(),
                unit=self.unit_combo.currentText(),
                notes=self.notes_edit.toPlainText().strip(),
                image_path=self.image_path_edit.text().strip() if self.image_path_edit.text().strip() else None,
            )
            
            if self.db:
                self.db.add_harvest(self.harvest)
        else:
            # Récolte existante
            self.harvest.plant_id = int(self.plant_combo.currentData())
            self.harvest.date = self.date_edit.date().toPython()
            self.harvest.quantity = self.quantity_spin.value()
            self.harvest.unit = self.unit_combo.currentText()
            self.harvest.notes = self.notes_edit.toPlainText().strip()
            self.harvest.image_path = self.image_path_edit.text().strip() if self.image_path_edit.text().strip() else None
            
            if self.db:
                self.db.update_harvest(self.harvest)
        
        # Accepter la dialogue
        self.accept()
