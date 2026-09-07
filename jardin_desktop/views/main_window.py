"""
Fenêtre principale de l'application Jardin Desktop.
"""

from PyQt6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, QStackedWidget,
    QTreeWidget, QTreeWidgetItem, QPushButton, QLabel, QToolBar,
    QStatusBar, QMessageBox, QInputDialog, QFileDialog
)
from PyQt6.QtCore import Qt, pyqtSignal, QSize
from PyQt6.QtGui import QAction, QIcon, QPixmap
from typing import Optional, List

from ..database.database_manager import DatabaseManager
from ..models.plant import Plant, PlantType, SoilType, SunExposure
from ..models.task import Task, TaskType, TaskStatus
from ..models.harvest import Harvest
from ..models.garden import Garden
from .plant_dialog import PlantDialog
from .task_dialog import TaskDialog
from .harvest_dialog import HarvestDialog
from .garden_dialog import GardenDialog
from ..utils.helpers import format_date_french, get_season


class MainWindow(QMainWindow):
    """
    Fenêtre principale de l'application Jardin.
    Gère l'affichage des plantes, tâches, récoltes et jardins.
    """
    
    # Signaux pour la communication entre les vues
    plant_updated = pyqtSignal()
    task_updated = pyqtSignal()
    harvest_updated = pyqtSignal()
    garden_updated = pyqtSignal()
    
    def __init__(self, db_manager: DatabaseManager):
        """
        Initialise la fenêtre principale.
        
        Args:
            db_manager: Gestionnaire de la base de données.
        """
        super().__init__()
        self.db = db_manager
        self.setWindowTitle("Jardin Desktop - Gestion de jardin et potager")
        self.setMinimumSize(1024, 768)
        
        # Initialiser l'interface
        self._init_ui()
        self._load_data()
        self._connect_signals()
    
    def _init_ui(self) -> None:
        """Initialise l'interface utilisateur."""
        # Créer la barre d'outils
        self._create_toolbar()
        
        # Créer la barre de statut
        self._create_statusbar()
        
        # Créer le widget central
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Layout principal
        main_layout = QHBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)
        
        # Créer le panneau de navigation (à gauche)
        self.navigation_panel = self._create_navigation_panel()
        main_layout.addWidget(self.navigation_panel, stretch=1)
        
        # Créer le panneau principal (au centre)
        self.stacked_widget = QStackedWidget()
        main_layout.addWidget(self.stacked_widget, stretch=4)
        
        # Créer les pages pour chaque section
        self._create_pages()
    
    def _create_toolbar(self) -> None:
        """Crée la barre d'outils."""
        toolbar = QToolBar("Barre d'outils")
        self.addToolBar(toolbar)
        
        # Ajouter des actions à la barre d'outils
        new_action = QAction(QIcon.fromTheme("document-new"), "Nouveau", self)
        new_action.setShortcut("Ctrl+N")
        new_action.triggered.connect(self._on_new_item)
        toolbar.addAction(new_action)
        
        save_action = QAction(QIcon.fromTheme("document-save"), "Sauvegarder", self)
        save_action.setShortcut("Ctrl+S")
        save_action.triggered.connect(self._on_save_data)
        toolbar.addAction(save_action)
        
        toolbar.addSeparator()
        
        export_action = QAction(QIcon.fromTheme("document-export"), "Exporter", self)
        export_action.setShortcut("Ctrl+E")
        export_action.triggered.connect(self._on_export_data)
        toolbar.addAction(export_action)
        
        toolbar.addSeparator()
        
        about_action = QAction(QIcon.fromTheme("help-about"), "À propos", self)
        about_action.triggered.connect(self._on_about)
        toolbar.addAction(about_action)
    
    def _create_statusbar(self) -> None:
        """Crée la barre de statut."""
        statusbar = QStatusBar()
        self.setStatusBar(statusbar)
        
        # Afficher le nombre total d'éléments
        self.status_label = QLabel("Prêt")
        statusbar.addWidget(self.status_label)
        
        # Afficher la saison actuelle
        season = get_season()
        season_label = QLabel(f"Saison: {season}")
        statusbar.addPermanentWidget(season_label)
    
    def _create_navigation_panel(self) -> QWidget:
        """Crée le panneau de navigation."""
        panel = QWidget()
        panel.setMaximumWidth(250)
        layout = QVBoxLayout(panel)
        layout.setContentsMargins(10, 10, 10, 10)
        layout.setSpacing(5)
        
        # Titre
        title = QLabel("<h2>Jardin Desktop</h2>")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title)
        
        # Boutons de navigation
        self.nav_buttons = {}
        
        buttons = [
            ("Plantes", "plants"),
            ("Tâches", "tasks"),
            ("Récoltes", "harvests"),
            ("Jardins", "gardens"),
            ("Statistiques", "stats"),
            ("Calendrier", "calendar"),
        ]
        
        for text, page_name in buttons:
            btn = QPushButton(text)
            btn.setProperty("page", page_name)
            btn.clicked.connect(self._on_navigate)
            layout.addWidget(btn)
            self.nav_buttons[page_name] = btn
        
        # Sélectionner le premier bouton par défaut
        self.nav_buttons["plants"].setStyleSheet(
            "QPushButton { background-color: #4CAF50; color: white; }"
        )
        
        # Espace flexible pour pousser les boutons vers le haut
        layout.addStretch()
        
        return panel
    
    def _create_pages(self) -> None:
        """Crée les pages pour chaque section."""
        # Page Plantes
        self.plants_page = self._create_plants_page()
        self.stacked_widget.addWidget(self.plants_page)
        
        # Page Tâches
        self.tasks_page = self._create_tasks_page()
        self.stacked_widget.addWidget(self.tasks_page)
        
        # Page Récoltes
        self.harvests_page = self._create_harvests_page()
        self.stacked_widget.addWidget(self.harvests_page)
        
        # Page Jardins
        self.gardens_page = self._create_gardens_page()
        self.stacked_widget.addWidget(self.gardens_page)
        
        # Page Statistiques
        self.stats_page = self._create_stats_page()
        self.stacked_widget.addWidget(self.stats_page)
        
        # Page Calendrier
        self.calendar_page = self._create_calendar_page()
        self.stacked_widget.addWidget(self.calendar_page)
    
    def _create_plants_page(self) -> QWidget:
        """Crée la page des plantes."""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(10, 10, 10, 10)
        layout.setSpacing(10)
        
        # Barre d'outils pour les plantes
        plant_toolbar = QHBoxLayout()
        
        add_btn = QPushButton("Ajouter une plante")
        add_btn.clicked.connect(lambda: self._show_plant_dialog())
        plant_toolbar.addWidget(add_btn)
        
        plant_toolbar.addStretch()
        
        # Champ de recherche
        self.plant_search = QLineEdit()
        self.plant_search.setPlaceholderText("Rechercher une plante...")
        self.plant_search.textChanged.connect(self._filter_plants)
        plant_toolbar.addWidget(self.plant_search)
        
        layout.addLayout(plant_toolbar)
        
        # Tableau des plantes
        self.plants_tree = QTreeWidget()
        self.plants_tree.setHeaderLabels([
            "ID", "Nom", "Type", "Date de plantation", 
            "Date de récolte", "Prochain arrosage"
        ])
        self.plants_tree.setColumnCount(6)
        self.plants_tree.setSelectionMode(QTreeWidget.SelectionMode.SingleSelection)
        self.plants_tree.itemDoubleClicked.connect(self._on_plant_double_clicked)
        
        layout.addWidget(self.plants_tree)
        
        # Boutons d'action
        action_layout = QHBoxLayout()
        
        edit_btn = QPushButton("Modifier")
        edit_btn.clicked.connect(self._edit_selected_plant)
        action_layout.addWidget(edit_btn)
        
        delete_btn = QPushButton("Supprimer")
        delete_btn.clicked.connect(self._delete_selected_plant)
        action_layout.addWidget(delete_btn)
        
        action_layout.addStretch()
        layout.addLayout(action_layout)
        
        return widget
    
    def _create_tasks_page(self) -> QWidget:
        """Crée la page des tâches."""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(10, 10, 10, 10)
        layout.setSpacing(10)
        
        # Barre d'outils pour les tâches
        task_toolbar = QHBoxLayout()
        
        add_btn = QPushButton("Ajouter une tâche")
        add_btn.clicked.connect(lambda: self._show_task_dialog())
        task_toolbar.addWidget(add_btn)
        
        task_toolbar.addStretch()
        
        # Filtre par statut
        self.task_status_filter = QComboBox()
        self.task_status_filter.addItems([
            "Toutes", "À faire", "En cours", "Terminé"
        ])
        self.task_status_filter.currentTextChanged.connect(self._filter_tasks)
        task_toolbar.addWidget(self.task_status_filter)
        
        layout.addLayout(task_toolbar)
        
        # Tableau des tâches
        self.tasks_tree = QTreeWidget()
        self.tasks_tree.setHeaderLabels([
            "ID", "Titre", "Type", "Date limite", "Statut", "Plante associée"
        ])
        self.tasks_tree.setColumnCount(6)
        self.tasks_tree.setSelectionMode(QTreeWidget.SelectionMode.SingleSelection)
        self.tasks_tree.itemDoubleClicked.connect(self._on_task_double_clicked)
        
        layout.addWidget(self.tasks_tree)
        
        # Boutons d'action
        action_layout = QHBoxLayout()
        
        edit_btn = QPushButton("Modifier")
        edit_btn.clicked.connect(self._edit_selected_task)
        action_layout.addWidget(edit_btn)
        
        delete_btn = QPushButton("Supprimer")
        delete_btn.clicked.connect(self._delete_selected_task)
        action_layout.addWidget(delete_btn)
        
        mark_complete_btn = QPushButton("Marquer comme terminé")
        mark_complete_btn.clicked.connect(self._mark_selected_task_complete)
        action_layout.addWidget(mark_complete_btn)
        
        action_layout.addStretch()
        layout.addLayout(action_layout)
        
        return widget
    
    def _create_harvests_page(self) -> QWidget:
        """Crée la page des récoltes."""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(10, 10, 10, 10)
        layout.setSpacing(10)
        
        # Barre d'outils pour les récoltes
        harvest_toolbar = QHBoxLayout()
        
        add_btn = QPushButton("Ajouter une récolte")
        add_btn.clicked.connect(lambda: self._show_harvest_dialog())
        harvest_toolbar.addWidget(add_btn)
        
        harvest_toolbar.addStretch()
        
        # Filtre par année
        self.harvest_year_filter = QComboBox()
        years = [str(year) for year in range(2020, date.today().year + 2)]
        self.harvest_year_filter.addItems(["Toutes les années"] + years)
        self.harvest_year_filter.currentTextChanged.connect(self._filter_harvests)
        harvest_toolbar.addWidget(self.harvest_year_filter)
        
        layout.addLayout(harvest_toolbar)
        
        # Tableau des récoltes
        self.harvests_tree = QTreeWidget()
        self.harvests_tree.setHeaderLabels([
            "ID", "Plante", "Date", "Quantité", "Unité", "Notes"
        ])
        self.harvests_tree.setColumnCount(6)
        self.harvests_tree.setSelectionMode(QTreeWidget.SelectionMode.SingleSelection)
        self.harvests_tree.itemDoubleClicked.connect(self._on_harvest_double_clicked)
        
        layout.addWidget(self.harvests_tree)
        
        # Boutons d'action
        action_layout = QHBoxLayout()
        
        edit_btn = QPushButton("Modifier")
        edit_btn.clicked.connect(self._edit_selected_harvest)
        action_layout.addWidget(edit_btn)
        
        delete_btn = QPushButton("Supprimer")
        delete_btn.clicked.connect(self._delete_selected_harvest)
        action_layout.addWidget(delete_btn)
        
        action_layout.addStretch()
        layout.addLayout(action_layout)
        
        return widget
    
    def _create_gardens_page(self) -> QWidget:
        """Crée la page des jardins."""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(10, 10, 10, 10)
        layout.setSpacing(10)
        
        # Barre d'outils pour les jardins
        garden_toolbar = QHBoxLayout()
        
        add_btn = QPushButton("Ajouter un jardin")
        add_btn.clicked.connect(lambda: self._show_garden_dialog())
        garden_toolbar.addWidget(add_btn)
        
        garden_toolbar.addStretch()
        layout.addLayout(garden_toolbar)
        
        # Tableau des jardins
        self.gardens_tree = QTreeWidget()
        self.gardens_tree.setHeaderLabels([
            "ID", "Nom", "Emplacement", "Surface (m²)", "Nombre de plantes"
        ])
        self.gardens_tree.setColumnCount(5)
        self.gardens_tree.setSelectionMode(QTreeWidget.SelectionMode.SingleSelection)
        self.gardens_tree.itemDoubleClicked.connect(self._on_garden_double_clicked)
        
        layout.addWidget(self.gardens_tree)
        
        # Boutons d'action
        action_layout = QHBoxLayout()
        
        edit_btn = QPushButton("Modifier")
        edit_btn.clicked.connect(self._edit_selected_garden)
        action_layout.addWidget(edit_btn)
        
        delete_btn = QPushButton("Supprimer")
        delete_btn.clicked.connect(self._delete_selected_garden)
        action_layout.addWidget(delete_btn)
        
        view_plants_btn = QPushButton("Voir les plantes")
        view_plants_btn.clicked.connect(self._view_garden_plants)
        action_layout.addWidget(view_plants_btn)
        
        action_layout.addStretch()
        layout.addLayout(action_layout)
        
        return widget
    
    def _create_stats_page(self) -> QWidget:
        """Crée la page des statistiques."""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(10, 10, 10, 10)
        layout.setSpacing(10)
        
        # Titre
        title = QLabel("<h2>Statistiques du jardin</h2>")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title)
        
        # Statistiques générales
        self.stats_labels = {}
        
        stats_layout = QVBoxLayout()
        
        self.stats_labels["total_plants"] = QLabel("Nombre total de plantes: 0")
        stats_layout.addWidget(self.stats_labels["total_plants"])
        
        self.stats_labels["total_tasks"] = QLabel("Nombre total de tâches: 0")
        stats_layout.addWidget(self.stats_labels["total_tasks"])
        
        self.stats_labels["pending_tasks"] = QLabel("Tâches en attente: 0")
        stats_layout.addWidget(self.stats_labels["pending_tasks"])
        
        self.stats_labels["total_harvests"] = QLabel("Nombre total de récoltes: 0")
        stats_layout.addWidget(self.stats_labels["total_harvests"])
        
        self.stats_labels["total_gardens"] = QLabel("Nombre total de jardins: 0")
        stats_layout.addWidget(self.stats_labels["total_gardens"])
        
        layout.addLayout(stats_layout)
        layout.addStretch()
        
        return widget
    
    def _create_calendar_page(self) -> QWidget:
        """Crée la page du calendrier."""
        widget = QWidget()
        layout = QVBoxLayout(widget)
        layout.setContentsMargins(10, 10, 10, 10)
        layout.setSpacing(10)
        
        # Titre
        title = QLabel("<h2>Calendrier</h2>")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(title)
        
        # Calendrier (simplifié pour l'instant)
        self.calendar = QCalendarWidget()
        self.calendar.setGridVisible(True)
        self.calendar.clicked.connect(self._on_calendar_date_clicked)
        layout.addWidget(self.calendar)
        
        # Liste des tâches pour la date sélectionnée
        self.calendar_tasks_tree = QTreeWidget()
        self.calendar_tasks_tree.setHeaderLabels([
            "Heure", "Titre", "Type", "Statut"
        ])
        self.calendar_tasks_tree.setColumnCount(4)
        layout.addWidget(self.calendar_tasks_tree)
        
        return widget
    
    def _connect_signals(self) -> None:
        """Connecte les signaux aux slots."""
        self.plant_updated.connect(self._load_plants)
        self.task_updated.connect(self._load_tasks)
        self.harvest_updated.connect(self._load_harvests)
        self.garden_updated.connect(self._load_gardens)
    
    def _load_data(self) -> None:
        """Charge toutes les données depuis la base de données."""
        self._load_plants()
        self._load_tasks()
        self._load_harvests()
        self._load_gardens()
        self._update_stats()
    
    def _load_plants(self) -> None:
        """Charge et affiche les plantes."""
        self.plants_tree.clear()
        plants = self.db.get_all_plants()
        
        for plant in plants:
            item = QTreeWidgetItem()
            item.setText(0, str(plant.id))
            item.setText(1, plant.name)
            item.setText(2, plant.plant_type.value)
            item.setText(3, format_date_french(plant.planting_date))
            item.setText(4, format_date_french(plant.harvest_date))
            
            # Vérifier si la plante a besoin d'arrosage
            if plant.needs_watering():
                item.setText(5, "⚠️ À arroser")
                item.setBackground(5, Qt.GlobalColor.yellow)
            else:
                item.setText(5, "OK")
                item.setBackground(5, Qt.GlobalColor.green)
            
            item.setData(0, Qt.ItemDataRole.UserRole, plant.id)
            self.plants_tree.addTopLevelItem(item)
        
        # Mettre à jour le statut
        self.status_label.setText(f"Plantes: {len(plants)} | Tâches: {len(self.db.get_all_tasks())}")
    
    def _load_tasks(self) -> None:
        """Charge et affiche les tâches."""
        self.tasks_tree.clear()
        tasks = self.db.get_all_tasks()
        
        for task in tasks:
            item = QTreeWidgetItem()
            item.setText(0, str(task.id))
            item.setText(1, task.title)
            item.setText(2, task.task_type.value)
            item.setText(3, format_date_french(task.due_date))
            item.setText(4, task.status.value)
            
            # Afficher le nom de la plante associée si elle existe
            if task.plant_id:
                plant = self.db.get_plant_by_id(task.plant_id)
                item.setText(5, plant.name if plant else "Inconnu")
            else:
                item.setText(5, "Aucune")
            
            # Colorer selon le statut
            if task.status == TaskStatus.TERMINE:
                item.setBackground(4, Qt.GlobalColor.green)
            elif task.is_overdue():
                item.setBackground(3, Qt.GlobalColor.red)
                item.setBackground(4, Qt.GlobalColor.red)
            
            item.setData(0, Qt.ItemDataRole.UserRole, task.id)
            self.tasks_tree.addTopLevelItem(item)
    
    def _load_harvests(self) -> None:
        """Charge et affiche les récoltes."""
        self.harvests_tree.clear()
        harvests = self.db.get_all_harvests()
        
        for harvest in harvests:
            item = QTreeWidgetItem()
            item.setText(0, str(harvest.id))
            
            # Récupérer le nom de la plante
            plant = self.db.get_plant_by_id(harvest.plant_id)
            item.setText(1, plant.name if plant else "Inconnu")
            
            item.setText(2, format_date_french(harvest.date))
            item.setText(3, f"{harvest.quantity}")
            item.setText(4, harvest.unit)
            item.setText(5, harvest.notes)
            
            item.setData(0, Qt.ItemDataRole.UserRole, harvest.id)
            self.harvests_tree.addTopLevelItem(item)
    
    def _load_gardens(self) -> None:
        """Charge et affiche les jardins."""
        self.gardens_tree.clear()
        gardens = self.db.get_all_gardens()
        
        for garden in gardens:
            item = QTreeWidgetItem()
            item.setText(0, str(garden.id))
            item.setText(1, garden.name)
            item.setText(2, garden.location)
            item.setText(3, f"{garden.area}")
            item.setText(4, str(len(garden.plants)))
            
            item.setData(0, Qt.ItemDataRole.UserRole, garden.id)
            self.gardens_tree.addTopLevelItem(item)
    
    def _update_stats(self) -> None:
        """Met à jour les statistiques affichées."""
        plants = self.db.get_all_plants()
        tasks = self.db.get_all_tasks()
        harvests = self.db.get_all_harvests()
        gardens = self.db.get_all_gardens()
        
        pending_tasks = [t for t in tasks if t.status != TaskStatus.TERMINE]
        
        self.stats_labels["total_plants"].setText(f"Nombre total de plantes: {len(plants)}")
        self.stats_labels["total_tasks"].setText(f"Nombre total de tâches: {len(tasks)}")
        self.stats_labels["pending_tasks"].setText(f"Tâches en attente: {len(pending_tasks)}")
        self.stats_labels["total_harvests"].setText(f"Nombre total de récoltes: {len(harvests)}")
        self.stats_labels["total_gardens"].setText(f"Nombre total de jardins: {len(gardens)}")
    
    def _on_navigate(self) -> None:
        """Gère la navigation entre les pages."""
        sender = self.sender()
        if hasattr(sender, "property"):
            page_name = sender.property("page")
            
            # Réinitialiser le style des boutons
            for btn in self.nav_buttons.values():
                btn.setStyleSheet("")
            
            # Mettre en évidence le bouton sélectionné
            sender.setStyleSheet(
                "QPushButton { background-color: #4CAF50; color: white; }"
            )
            
            # Afficher la page correspondante
            page_index = list(self.nav_buttons.keys()).index(page_name)
            self.stacked_widget.setCurrentIndex(page_index)
    
    def _show_plant_dialog(self, plant: Optional[Plant] = None) -> None:
        """Affiche la boîte de dialogue pour ajouter/modifier une plante."""
        dialog = PlantDialog(self, plant, self.db)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            self.plant_updated.emit()
    
    def _show_task_dialog(self, task: Optional[Task] = None) -> None:
        """Affiche la boîte de dialogue pour ajouter/modifier une tâche."""
        dialog = TaskDialog(self, task, self.db)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            self.task_updated.emit()
    
    def _show_harvest_dialog(self, harvest: Optional[Harvest] = None) -> None:
        """Affiche la boîte de dialogue pour ajouter/modifier une récolte."""
        dialog = HarvestDialog(self, harvest, self.db)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            self.harvest_updated.emit()
    
    def _show_garden_dialog(self, garden: Optional[Garden] = None) -> None:
        """Affiche la boîte de dialogue pour ajouter/modifier un jardin."""
        dialog = GardenDialog(self, garden, self.db)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            self.garden_updated.emit()
    
    def _on_plant_double_clicked(self, item: QTreeWidgetItem, column: int) -> None:
        """Gère le double-clic sur une plante."""
        plant_id = item.data(0, Qt.ItemDataRole.UserRole)
        plant = self.db.get_plant_by_id(plant_id)
        if plant:
            self._show_plant_dialog(plant)
    
    def _on_task_double_clicked(self, item: QTreeWidgetItem, column: int) -> None:
        """Gère le double-clic sur une tâche."""
        task_id = item.data(0, Qt.ItemDataRole.UserRole)
        task = self.db.get_task_by_id(task_id)
        if task:
            self._show_task_dialog(task)
    
    def _on_harvest_double_clicked(self, item: QTreeWidgetItem, column: int) -> None:
        """Gère le double-clic sur une récolte."""
        harvest_id = item.data(0, Qt.ItemDataRole.UserRole)
        harvest = self.db.get_harvest_by_id(harvest_id)
        if harvest:
            self._show_harvest_dialog(harvest)
    
    def _on_garden_double_clicked(self, item: QTreeWidgetItem, column: int) -> None:
        """Gère le double-clic sur un jardin."""
        garden_id = item.data(0, Qt.ItemDataRole.UserRole)
        garden = self.db.get_garden_by_id(garden_id)
        if garden:
            self._show_garden_dialog(garden)
    
    def _edit_selected_plant(self) -> None:
        """Modifie la plante sélectionnée."""
        selected = self.plants_tree.currentItem()
        if selected:
            plant_id = selected.data(0, Qt.ItemDataRole.UserRole)
            plant = self.db.get_plant_by_id(plant_id)
            if plant:
                self._show_plant_dialog(plant)
    
    def _edit_selected_task(self) -> None:
        """Modifie la tâche sélectionnée."""
        selected = self.tasks_tree.currentItem()
        if selected:
            task_id = selected.data(0, Qt.ItemDataRole.UserRole)
            task = self.db.get_task_by_id(task_id)
            if task:
                self._show_task_dialog(task)
    
    def _edit_selected_harvest(self) -> None:
        """Modifie la récolte sélectionnée."""
        selected = self.harvests_tree.currentItem()
        if selected:
            harvest_id = selected.data(0, Qt.ItemDataRole.UserRole)
            harvest = self.db.get_harvest_by_id(harvest_id)
            if harvest:
                self._show_harvest_dialog(harvest)
    
    def _edit_selected_garden(self) -> None:
        """Modifie le jardin sélectionné."""
        selected = self.gardens_tree.currentItem()
        if selected:
            garden_id = selected.data(0, Qt.ItemDataRole.UserRole)
            garden = self.db.get_garden_by_id(garden_id)
            if garden:
                self._show_garden_dialog(garden)
    
    def _delete_selected_plant(self) -> None:
        """Supprime la plante sélectionnée."""
        selected = self.plants_tree.currentItem()
        if selected:
            plant_id = selected.data(0, Qt.ItemDataRole.UserRole)
            reply = QMessageBox.question(
                self, "Supprimer la plante",
                "Voulez-vous vraiment supprimer cette plante ?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
            )
            if reply == QMessageBox.StandardButton.Yes:
                self.db.delete_plant(plant_id)
                self.plant_updated.emit()
    
    def _delete_selected_task(self) -> None:
        """Supprime la tâche sélectionnée."""
        selected = self.tasks_tree.currentItem()
        if selected:
            task_id = selected.data(0, Qt.ItemDataRole.UserRole)
            reply = QMessageBox.question(
                self, "Supprimer la tâche",
                "Voulez-vous vraiment supprimer cette tâche ?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
            )
            if reply == QMessageBox.StandardButton.Yes:
                self.db.delete_task(task_id)
                self.task_updated.emit()
    
    def _delete_selected_harvest(self) -> None:
        """Supprime la récolte sélectionnée."""
        selected = self.harvests_tree.currentItem()
        if selected:
            harvest_id = selected.data(0, Qt.ItemDataRole.UserRole)
            reply = QMessageBox.question(
                self, "Supprimer la récolte",
                "Voulez-vous vraiment supprimer cette récolte ?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
            )
            if reply == QMessageBox.StandardButton.Yes:
                self.db.delete_harvest(harvest_id)
                self.harvest_updated.emit()
    
    def _delete_selected_garden(self) -> None:
        """Supprime le jardin sélectionné."""
        selected = self.gardens_tree.currentItem()
        if selected:
            garden_id = selected.data(0, Qt.ItemDataRole.UserRole)
            reply = QMessageBox.question(
                self, "Supprimer le jardin",
                "Voulez-vous vraiment supprimer ce jardin ?",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
            )
            if reply == QMessageBox.StandardButton.Yes:
                self.db.delete_garden(garden_id)
                self.garden_updated.emit()
    
    def _mark_selected_task_complete(self) -> None:
        """Marque la tâche sélectionnée comme terminée."""
        selected = self.tasks_tree.currentItem()
        if selected:
            task_id = selected.data(0, Qt.ItemDataRole.UserRole)
            task = self.db.get_task_by_id(task_id)
            if task:
                task.status = TaskStatus.TERMINE
                task.completed_date = date.today()
                self.db.update_task(task)
                self.task_updated.emit()
    
    def _view_garden_plants(self) -> None:
        """Affiche les plantes du jardin sélectionné."""
        selected = self.gardens_tree.currentItem()
        if selected:
            garden_id = selected.data(0, Qt.ItemDataRole.UserRole)
            garden = self.db.get_garden_by_id(garden_id)
            if garden:
                # Filtrer les plantes par jardin
                self.plants_tree.clear()
                
                for plant in garden.plants:
                    item = QTreeWidgetItem()
                    item.setText(0, str(plant.id))
                    item.setText(1, plant.name)
                    item.setText(2, plant.plant_type.value)
                    item.setText(3, format_date_french(plant.planting_date))
                    item.setText(4, format_date_french(plant.harvest_date))
                    
                    if plant.needs_watering():
                        item.setText(5, "⚠️ À arroser")
                        item.setBackground(5, Qt.GlobalColor.yellow)
                    else:
                        item.setText(5, "OK")
                        item.setBackground(5, Qt.GlobalColor.green)
                    
                    self.plants_tree.addTopLevelItem(item)
                
                # Passer à la page des plantes
                self.stacked_widget.setCurrentIndex(0)
                self.nav_buttons["plants"].setStyleSheet(
                    "QPushButton { background-color: #4CAF50; color: white; }"
                )
    
    def _filter_plants(self, text: str) -> None:
        """Filtre les plantes en fonction du texte de recherche."""
        for i in range(self.plants_tree.topLevelItemCount()):
            item = self.plants_tree.topLevelItem(i)
            plant_name = item.text(1).lower()
            item.setHidden(text.lower() not in plant_name)
    
    def _filter_tasks(self, status: str) -> None:
        """Filtre les tâches en fonction du statut sélectionné."""
        for i in range(self.tasks_tree.topLevelItemCount()):
            item = self.tasks_tree.topLevelItem(i)
            task_status = item.text(4)
            
            if status == "Toutes" or task_status == status:
                item.setHidden(False)
            else:
                item.setHidden(True)
    
    def _filter_harvests(self, year: str) -> None:
        """Filtre les récoltes en fonction de l'année sélectionnée."""
        for i in range(self.harvests_tree.topLevelItemCount()):
            item = self.harvests_tree.topLevelItem(i)
            harvest_date = item.text(2)
            
            if year == "Toutes les années" or year in harvest_date:
                item.setHidden(False)
            else:
                item.setHidden(True)
    
    def _on_calendar_date_clicked(self, qdate) -> None:
        """Gère le clic sur une date du calendrier."""
        from datetime import datetime
        clicked_date = qdate.toPython()
        
        self.calendar_tasks_tree.clear()
        
        # Récupérer les tâches pour cette date
        tasks = self.db.get_all_tasks()
        for task in tasks:
            if task.due_date and task.due_date == clicked_date:
                item = QTreeWidgetItem()
                item.setText(0, task.due_time.isoformat() if task.due_time else "")
                item.setText(1, task.title)
                item.setText(2, task.task_type.value)
                item.setText(3, task.status.value)
                self.calendar_tasks_tree.addTopLevelItem(item)
    
    def _on_new_item(self) -> None:
        """Gère l'ajout d'un nouvel élément."""
        current_page = self.stacked_widget.currentIndex()
        page_names = ["plants", "tasks", "harvests", "gardens", "stats", "calendar"]
        current_page_name = page_names[current_page]
        
        if current_page_name == "plants":
            self._show_plant_dialog()
        elif current_page_name == "tasks":
            self._show_task_dialog()
        elif current_page_name == "harvests":
            self._show_harvest_dialog()
        elif current_page_name == "gardens":
            self._show_garden_dialog()
    
    def _on_save_data(self) -> None:
        """Sauvegarde les données (pour l'instant, tout est déjà sauvegardé automatiquement)."""
        QMessageBox.information(
            self, "Sauvegarde",
            "Les données sont sauvegardées automatiquement dans la base de données."
        )
    
    def _on_export_data(self) -> None:
        """Exporte les données vers un fichier."""
        options = QFileDialog.Options()
        file_path, _ = QFileDialog.getSaveFileName(
            self, "Exporter les données", "",
            "Fichiers JSON (*.json);;Fichiers CSV (*.csv)",
            options=options
        )
        
        if file_path:
            if file_path.endswith(".json"):
                self._export_to_json(file_path)
            elif file_path.endswith(".csv"):
                self._export_to_csv(file_path)
    
    def _export_to_json(self, file_path: str) -> None:
        """Exporte les données vers un fichier JSON."""
        import json
        
        data = {
            "plants": [p.to_dict() for p in self.db.get_all_plants()],
            "tasks": [t.to_dict() for t in self.db.get_all_tasks()],
            "harvests": [h.to_dict() for h in self.db.get_all_harvests()],
            "gardens": [
                {
                    "id": g.id,
                    "name": g.name,
                    "description": g.description,
                    "location": g.location,
                    "area": g.area,
                    "notes": g.notes,
                    "plant_ids": [p.id for p in g.plants]
                }
                for g in self.db.get_all_gardens()
            ]
        }
        
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
        
        QMessageBox.information(
            self, "Export",
            f"Les données ont été exportées vers {file_path}"
        )
    
    def _export_to_csv(self, file_path: str) -> None:
        """Exporte les données vers un fichier CSV."""
        import csv
        
        with open(file_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            
            # Écrire les plantes
            writer.writerow(["Type", "ID", "Nom", "Type de plante", "Date de plantation", "Date de récolte"])
            for plant in self.db.get_all_plants():
                writer.writerow([
                    "Plante",
                    plant.id,
                    plant.name,
                    plant.plant_type.value,
                    format_date_french(plant.planting_date),
                    format_date_french(plant.harvest_date)
                ])
            
            # Écrire les tâches
            writer.writerow([])
            writer.writerow(["Type", "ID", "Titre", "Type de tâche", "Date limite", "Statut"])
            for task in self.db.get_all_tasks():
                writer.writerow([
                    "Tâche",
                    task.id,
                    task.title,
                    task.task_type.value,
                    format_date_french(task.due_date),
                    task.status.value
                ])
        
        QMessageBox.information(
            self, "Export",
            f"Les données ont été exportées vers {file_path}"
        )
    
    def _on_about(self) -> None:
        """Affiche la boîte de dialogue "À propos"."""
        QMessageBox.about(
            self, "À propos de Jardin Desktop",
            "<h2>Jardin Desktop</h2>"
            "<p>Application de gestion de jardin d'agrément et potager.</p>"
            "<p>Développée avec Python et PyQt6.</p>"
            "<p>© 2025 JardinApp</p>"
        )


# Corriger l'import manquant pour QDialog
from PyQt6.QtWidgets import QDialog, QLineEdit, QComboBox, QCalendarWidget
