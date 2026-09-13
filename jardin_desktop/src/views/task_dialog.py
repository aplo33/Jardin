"""
Boîte de dialogue pour ajouter/modifier une tâche.
"""

from PyQt6.QtWidgets import (
    QDialog, QVBoxLayout, QHBoxLayout, QFormLayout, QLabel,
    QLineEdit, QComboBox, QTextEdit, QPushButton, QDateEdit,
    QTimeEdit, QMessageBox
)
from PyQt6.QtCore import Qt, QDate, QTime
from typing import Optional
from datetime import date, time

from ..models.task import Task, TaskType, TaskStatus
from ..database.database_manager import DatabaseManager
from ..models.plant import Plant
from ..utils.helpers import generate_id


class TaskDialog(QDialog):
    """
    Boîte de dialogue pour ajouter ou modifier une tâche.
    """
    
    def __init__(self, parent, task: Optional[Task] = None, db_manager: Optional[DatabaseManager] = None):
        """
        Initialise la boîte de dialogue.
        
        Args:
            parent: Widget parent.
            task: Tâche à modifier (None pour une nouvelle tâche).
            db_manager: Gestionnaire de la base de données.
        """
        super().__init__(parent)
        self.db = db_manager
        self.task = task
        self.setWindowTitle("Ajouter une tâche" if task is None else "Modifier la tâche")
        self.setMinimumSize(500, 400)
        
        # Initialiser l'interface
        self._init_ui()
        
        # Charger les données si on modifie une tâche existante
        if task:
            self._load_task_data()
    
    def _init_ui(self) -> None:
        """Initialise l'interface utilisateur."""
        layout = QVBoxLayout(self)
        
        # Formulaire
        form_layout = QFormLayout()
        form_layout.setFieldGrowthPolicy(QFormLayout.FieldGrowthPolicy.AllNonFixedFieldsGrow)
        form_layout.setFormAlignment(Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignTop)
        form_layout.setLabelAlignment(Qt.AlignmentFlag.AlignRight)
        
        # Titre
        self.title_edit = QLineEdit()
        self.title_edit.setPlaceholderText("Ex: Arroser les tomates")
        form_layout.addRow("Titre *:", self.title_edit)
        
        # Description
        self.description_edit = QTextEdit()
        self.description_edit.setPlaceholderText("Description de la tâche...")
        self.description_edit.setMaximumHeight(80)
        form_layout.addRow("Description:", self.description_edit)
        
        # Type de tâche
        self.type_combo = QComboBox()
        self.type_combo.addItems([t.value for t in TaskType])
        form_layout.addRow("Type *:", self.type_combo)
        
        # Plante associée
        self.plant_combo = QComboBox()
        self.plant_combo.addItem("Aucune", 0)
        if self.db:
            plants = self.db.get_all_plants()
            for plant in plants:
                self.plant_combo.addItem(f"{plant.name} ({plant.plant_type.value})", plant.id)
        form_layout.addRow("Plante associée:", self.plant_combo)
        
        # Date limite
        self.due_date_edit = QDateEdit()
        self.due_date_edit.setCalendarPopup(True)
        self.due_date_edit.setDate(QDate.currentDate())
        form_layout.addRow("Date limite:", self.due_date_edit)
        
        # Heure limite
        self.due_time_edit = QTimeEdit()
        self.due_time_edit.setDisplayFormat("HH:mm")
        self.due_time_edit.setTime(QTime(12, 0))  # Midi par défaut
        form_layout.addRow("Heure limite:", self.due_time_edit)
        
        # Statut
        self.status_combo = QComboBox()
        self.status_combo.addItems([s.value for s in TaskStatus])
        form_layout.addRow("Statut:", self.status_combo)
        
        # Notes
        self.notes_edit = QTextEdit()
        self.notes_edit.setPlaceholderText("Notes supplémentaires...")
        self.notes_edit.setMaximumHeight(80)
        form_layout.addRow("Notes:", self.notes_edit)
        
        layout.addLayout(form_layout)
        
        # Boutons
        button_layout = QHBoxLayout()
        
        save_btn = QPushButton("Sauvegarder")
        save_btn.clicked.connect(self._save_task)
        button_layout.addWidget(save_btn)
        
        cancel_btn = QPushButton("Annuler")
        cancel_btn.clicked.connect(self.reject)
        button_layout.addWidget(cancel_btn)
        
        button_layout.addStretch()
        layout.addLayout(button_layout)
    
    def _load_task_data(self) -> None:
        """Charge les données de la tâche dans les champs du formulaire."""
        if self.task:
            self.title_edit.setText(self.task.title)
            self.description_edit.setText(self.task.description)
            self.type_combo.setCurrentText(self.task.task_type.value)
            
            # Sélectionner la plante associée
            if self.task.plant_id:
                index = self.plant_combo.findData(self.task.plant_id)
                if index >= 0:
                    self.plant_combo.setCurrentIndex(index)
            
            if self.task.due_date:
                self.due_date_edit.setDate(
                    QDate(self.task.due_date.year, self.task.due_date.month, self.task.due_date.day)
                )
            
            if self.task.due_time:
                self.due_time_edit.setTime(
                    QTime(self.task.due_time.hour, self.task.due_time.minute)
                )
            
            self.status_combo.setCurrentText(self.task.status.value)
            self.notes_edit.setText(self.task.notes)
    
    def _save_task(self) -> None:
        """Sauvegarde les données de la tâche."""
        # Valider les champs obligatoires
        if not self.title_edit.text().strip():
            QMessageBox.warning(
                self, "Erreur",
                "Le champ 'Titre' est obligatoire."
            )
            return
        
        # Créer ou mettre à jour la tâche
        if self.task is None:
            # Nouvelle tâche
            self.task = Task(
                id=generate_id(),
                title=self.title_edit.text().strip(),
                description=self.description_edit.toPlainText().strip(),
                task_type=TaskType(self.type_combo.currentText()),
                due_date=self.due_date_edit.date().toPython() if self.due_date_edit.date().isValid() else None,
                due_time=self.due_time_edit.time().toPython() if self.due_time_edit.time().isValid() else None,
                status=TaskStatus(self.status_combo.currentText()),
                plant_id=int(self.plant_combo.currentData()) if self.plant_combo.currentData() != 0 else None,
                notes=self.notes_edit.toPlainText().strip(),
            )
            
            if self.db:
                self.db.add_task(self.task)
        else:
            # Tâche existante
            self.task.title = self.title_edit.text().strip()
            self.task.description = self.description_edit.toPlainText().strip()
            self.task.task_type = TaskType(self.type_combo.currentText())
            self.task.due_date = self.due_date_edit.date().toPython() if self.due_date_edit.date().isValid() else None
            self.task.due_time = self.due_time_edit.time().toPython() if self.due_time_edit.time().isValid() else None
            self.task.status = TaskStatus(self.status_combo.currentText())
            self.task.plant_id = int(self.plant_combo.currentData()) if self.plant_combo.currentData() != 0 else None
            self.task.notes = self.notes_edit.toPlainText().strip()
            
            if self.db:
                self.db.update_task(self.task)
        
        # Accepter la dialogue
        self.accept()
