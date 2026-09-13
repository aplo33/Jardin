"""
Gestionnaire de la base de données SQLite pour l'application Jardin.
"""
import sqlite3
import os
from typing import List, Optional, Dict, Any
from datetime import date, time
from ..models.plant import Plant, PlantType, SoilType, SunExposure
from ..models.task import Task, TaskType, TaskStatus
from ..models.harvest import Harvest
from ..models.garden import Garden


class DatabaseManager:
    """
    Gère les opérations de base de données pour l'application Jardin.
    Utilise SQLite pour le stockage local.
    """
    
    def __init__(self, db_path: str = "jardin.db"):
        """
        Initialise le gestionnaire de base de données.
        
        Args:
            db_path: Chemin vers le fichier de la base de données.
        """
        self.db_path = db_path
        self._initialize_database()
    
    def _initialize_database(self) -> None:
        """
        Initialise la base de données et crée les tables si elles n'existent pas.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Table pour les plantes
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS plants (
                    id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    plant_type TEXT,
                    variety TEXT,
                    planting_date TEXT,
                    harvest_date TEXT,
                    soil_type TEXT,
                    sun_exposure TEXT,
                    watering_frequency INTEGER,
                    last_watering TEXT,
                    notes TEXT,
                    image_path TEXT
                )
            """)
            
            # Table pour les tâches
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS tasks (
                    id INTEGER PRIMARY KEY,
                    title TEXT NOT NULL,
                    description TEXT,
                    task_type TEXT,
                    due_date TEXT,
                    due_time TEXT,
                    status TEXT,
                    plant_id INTEGER,
                    notes TEXT,
                    completed_date TEXT,
                    FOREIGN KEY (plant_id) REFERENCES plants(id)
                )
            """)
            
            # Table pour les récoltes
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS harvests (
                    id INTEGER PRIMARY KEY,
                    plant_id INTEGER NOT NULL,
                    date TEXT NOT NULL,
                    quantity REAL NOT NULL,
                    unit TEXT,
                    notes TEXT,
                    image_path TEXT,
                    FOREIGN KEY (plant_id) REFERENCES plants(id)
                )
            """)
            
            # Table pour les jardins
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS gardens (
                    id INTEGER PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    location TEXT,
                    area REAL,
                    notes TEXT
                )
            """)
            
            # Table pour l'association entre jardins et plantes
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS garden_plants (
                    garden_id INTEGER NOT NULL,
                    plant_id INTEGER NOT NULL,
                    PRIMARY KEY (garden_id, plant_id),
                    FOREIGN KEY (garden_id) REFERENCES gardens(id),
                    FOREIGN KEY (plant_id) REFERENCES plants(id)
                )
            """)
            
            conn.commit()
    
    # ==================== Méthodes pour les plantes ====================
    
    def add_plant(self, plant: Plant) -> int:
        """
        Ajoute une plante à la base de données.
        
        Args:
            plant: Plante à ajouter.
            
        Returns:
            int: ID de la plante ajoutée.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO plants (
                    name, description, plant_type, variety, planting_date, 
                    harvest_date, soil_type, sun_exposure, watering_frequency, 
                    last_watering, notes, image_path
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                plant.name,
                plant.description,
                plant.plant_type.value,
                plant.variety,
                plant.planting_date.isoformat() if plant.planting_date else None,
                plant.harvest_date.isoformat() if plant.harvest_date else None,
                plant.soil_type.value,
                plant.sun_exposure.value,
                plant.watering_frequency,
                plant.last_watering.isoformat() if plant.last_watering else None,
                plant.notes,
                plant.image_path,
            ))
            plant.id = cursor.lastrowid
            conn.commit()
            return plant.id
    
    def get_plant_by_id(self, plant_id: int) -> Optional[Plant]:
        """
        Récupère une plante par son ID.
        
        Args:
            plant_id: ID de la plante.
            
        Returns:
            Plant ou None: La plante si trouvée, None sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM plants WHERE id = ?", (plant_id,))
            row = cursor.fetchone()
            
            if row:
                return Plant(
                    id=row[0],
                    name=row[1],
                    description=row[2],
                    plant_type=PlantType(row[3]),
                    variety=row[4],
                    planting_date=date.fromisoformat(row[5]) if row[5] else None,
                    harvest_date=date.fromisoformat(row[6]) if row[6] else None,
                    soil_type=SoilType(row[7]),
                    sun_exposure=SunExposure(row[8]),
                    watering_frequency=row[9],
                    last_watering=date.fromisoformat(row[10]) if row[10] else None,
                    notes=row[11],
                    image_path=row[12],
                )
            return None
    
    def get_all_plants(self) -> List[Plant]:
        """
        Récupère toutes les plantes de la base de données.
        
        Returns:
            List[Plant]: Liste de toutes les plantes.
        """
        plants = []
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM plants")
            rows = cursor.fetchall()
            
            for row in rows:
                plant = Plant(
                    id=row[0],
                    name=row[1],
                    description=row[2],
                    plant_type=PlantType(row[3]),
                    variety=row[4],
                    planting_date=date.fromisoformat(row[5]) if row[5] else None,
                    harvest_date=date.fromisoformat(row[6]) if row[6] else None,
                    soil_type=SoilType(row[7]),
                    sun_exposure=SunExposure(row[8]),
                    watering_frequency=row[9],
                    last_watering=date.fromisoformat(row[10]) if row[10] else None,
                    notes=row[11],
                    image_path=row[12],
                )
                plants.append(plant)
        return plants
    
    def update_plant(self, plant: Plant) -> bool:
        """
        Met à jour une plante dans la base de données.
        
        Args:
            plant: Plante à mettre à jour.
            
        Returns:
            bool: True si la mise à jour a réussi, False sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE plants SET
                    name = ?,
                    description = ?,
                    plant_type = ?,
                    variety = ?,
                    planting_date = ?,
                    harvest_date = ?,
                    soil_type = ?,
                    sun_exposure = ?,
                    watering_frequency = ?,
                    last_watering = ?,
                    notes = ?,
                    image_path = ?
                WHERE id = ?
            """, (
                plant.name,
                plant.description,
                plant.plant_type.value,
                plant.variety,
                plant.planting_date.isoformat() if plant.planting_date else None,
                plant.harvest_date.isoformat() if plant.harvest_date else None,
                plant.soil_type.value,
                plant.sun_exposure.value,
                plant.watering_frequency,
                plant.last_watering.isoformat() if plant.last_watering else None,
                plant.notes,
                plant.image_path,
                plant.id,
            ))
            conn.commit()
            return cursor.rowcount > 0
    
    def delete_plant(self, plant_id: int) -> bool:
        """
        Supprime une plante de la base de données.
        
        Args:
            plant_id: ID de la plante à supprimer.
            
        Returns:
            bool: True si la suppression a réussi, False sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM plants WHERE id = ?", (plant_id,))
            conn.commit()
            return cursor.rowcount > 0
    
    # ==================== Méthodes pour les tâches ====================
    
    def add_task(self, task: Task) -> int:
        """
        Ajoute une tâche à la base de données.
        
        Args:
            task: Tâche à ajouter.
            
        Returns:
            int: ID de la tâche ajoutée.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO tasks (
                    title, description, task_type, due_date, due_time,
                    status, plant_id, notes, completed_date
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                task.title,
                task.description,
                task.task_type.value,
                task.due_date.isoformat() if task.due_date else None,
                task.due_time.isoformat() if task.due_time else None,
                task.status.value,
                task.plant_id,
                task.notes,
                task.completed_date.isoformat() if task.completed_date else None,
            ))
            task.id = cursor.lastrowid
            conn.commit()
            return task.id
    
    def get_task_by_id(self, task_id: int) -> Optional[Task]:
        """
        Récupère une tâche par son ID.
        
        Args:
            task_id: ID de la tâche.
            
        Returns:
            Task ou None: La tâche si trouvée, None sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM tasks WHERE id = ?", (task_id,))
            row = cursor.fetchone()
            
            if row:
                return Task(
                    id=row[0],
                    title=row[1],
                    description=row[2],
                    task_type=TaskType(row[3]),
                    due_date=date.fromisoformat(row[4]) if row[4] else None,
                    due_time=time.fromisoformat(row[5]) if row[5] else None,
                    status=TaskStatus(row[6]),
                    plant_id=row[7],
                    notes=row[8],
                    completed_date=date.fromisoformat(row[9]) if row[9] else None,
                )
            return None
    
    def get_all_tasks(self) -> List[Task]:
        """
        Récupère toutes les tâches de la base de données.
        
        Returns:
            List[Task]: Liste de toutes les tâches.
        """
        tasks = []
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM tasks")
            rows = cursor.fetchall()
            
            for row in rows:
                task = Task(
                    id=row[0],
                    title=row[1],
                    description=row[2],
                    task_type=TaskType(row[3]),
                    due_date=date.fromisoformat(row[4]) if row[4] else None,
                    due_time=time.fromisoformat(row[5]) if row[5] else None,
                    status=TaskStatus(row[6]),
                    plant_id=row[7],
                    notes=row[8],
                    completed_date=date.fromisoformat(row[9]) if row[9] else None,
                )
                tasks.append(task)
        return tasks
    
    def get_tasks_by_plant(self, plant_id: int) -> List[Task]:
        """
        Récupère toutes les tâches associées à une plante.
        
        Args:
            plant_id: ID de la plante.
            
        Returns:
            List[Task]: Liste des tâches associées à la plante.
        """
        tasks = []
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM tasks WHERE plant_id = ?", (plant_id,))
            rows = cursor.fetchall()
            
            for row in rows:
                task = Task(
                    id=row[0],
                    title=row[1],
                    description=row[2],
                    task_type=TaskType(row[3]),
                    due_date=date.fromisoformat(row[4]) if row[4] else None,
                    due_time=time.fromisoformat(row[5]) if row[5] else None,
                    status=TaskStatus(row[6]),
                    plant_id=row[7],
                    notes=row[8],
                    completed_date=date.fromisoformat(row[9]) if row[9] else None,
                )
                tasks.append(task)
        return tasks
    
    def update_task(self, task: Task) -> bool:
        """
        Met à jour une tâche dans la base de données.
        
        Args:
            task: Tâche à mettre à jour.
            
        Returns:
            bool: True si la mise à jour a réussi, False sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE tasks SET
                    title = ?,
                    description = ?,
                    task_type = ?,
                    due_date = ?,
                    due_time = ?,
                    status = ?,
                    plant_id = ?,
                    notes = ?,
                    completed_date = ?
                WHERE id = ?
            """, (
                task.title,
                task.description,
                task.task_type.value,
                task.due_date.isoformat() if task.due_date else None,
                task.due_time.isoformat() if task.due_time else None,
                task.status.value,
                task.plant_id,
                task.notes,
                task.completed_date.isoformat() if task.completed_date else None,
                task.id,
            ))
            conn.commit()
            return cursor.rowcount > 0
    
    def delete_task(self, task_id: int) -> bool:
        """
        Supprime une tâche de la base de données.
        
        Args:
            task_id: ID de la tâche à supprimer.
            
        Returns:
            bool: True si la suppression a réussi, False sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
            conn.commit()
            return cursor.rowcount > 0
    
    # ==================== Méthodes pour les récoltes ====================
    
    def add_harvest(self, harvest: Harvest) -> int:
        """
        Ajoute une récolte à la base de données.
        
        Args:
            harvest: Récolte à ajouter.
            
        Returns:
            int: ID de la récolte ajoutée.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO harvests (
                    plant_id, date, quantity, unit, notes, image_path
                ) VALUES (?, ?, ?, ?, ?, ?)
            """, (
                harvest.plant_id,
                harvest.date.isoformat(),
                harvest.quantity,
                harvest.unit,
                harvest.notes,
                harvest.image_path,
            ))
            harvest.id = cursor.lastrowid
            conn.commit()
            return harvest.id
    
    def get_harvest_by_id(self, harvest_id: int) -> Optional[Harvest]:
        """
        Récupère une récolte par son ID.
        
        Args:
            harvest_id: ID de la récolte.
            
        Returns:
            Harvest ou None: La récolte si trouvée, None sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM harvests WHERE id = ?", (harvest_id,))
            row = cursor.fetchone()
            
            if row:
                return Harvest(
                    id=row[0],
                    plant_id=row[1],
                    date=date.fromisoformat(row[2]),
                    quantity=row[3],
                    unit=row[4],
                    notes=row[5],
                    image_path=row[6],
                )
            return None
    
    def get_all_harvests(self) -> List[Harvest]:
        """
        Récupère toutes les récoltes de la base de données.
        
        Returns:
            List[Harvest]: Liste de toutes les récoltes.
        """
        harvests = []
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM harvests")
            rows = cursor.fetchall()
            
            for row in rows:
                harvest = Harvest(
                    id=row[0],
                    plant_id=row[1],
                    date=date.fromisoformat(row[2]),
                    quantity=row[3],
                    unit=row[4],
                    notes=row[5],
                    image_path=row[6],
                )
                harvests.append(harvest)
        return harvests
    
    def get_harvests_by_plant(self, plant_id: int) -> List[Harvest]:
        """
        Récupère toutes les récoltes associées à une plante.
        
        Args:
            plant_id: ID de la plante.
            
        Returns:
            List[Harvest]: Liste des récoltes associées à la plante.
        """
        harvests = []
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM harvests WHERE plant_id = ?", (plant_id,))
            rows = cursor.fetchall()
            
            for row in rows:
                harvest = Harvest(
                    id=row[0],
                    plant_id=row[1],
                    date=date.fromisoformat(row[2]),
                    quantity=row[3],
                    unit=row[4],
                    notes=row[5],
                    image_path=row[6],
                )
                harvests.append(harvest)
        return harvests
    
    def update_harvest(self, harvest: Harvest) -> bool:
        """
        Met à jour une récolte dans la base de données.
        
        Args:
            harvest: Récolte à mettre à jour.
            
        Returns:
            bool: True si la mise à jour a réussi, False sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE harvests SET
                    plant_id = ?,
                    date = ?,
                    quantity = ?,
                    unit = ?,
                    notes = ?,
                    image_path = ?
                WHERE id = ?
            """, (
                harvest.plant_id,
                harvest.date.isoformat(),
                harvest.quantity,
                harvest.unit,
                harvest.notes,
                harvest.image_path,
                harvest.id,
            ))
            conn.commit()
            return cursor.rowcount > 0
    
    def delete_harvest(self, harvest_id: int) -> bool:
        """
        Supprime une récolte de la base de données.
        
        Args:
            harvest_id: ID de la récolte à supprimer.
            
        Returns:
            bool: True si la suppression a réussi, False sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM harvests WHERE id = ?", (harvest_id,))
            conn.commit()
            return cursor.rowcount > 0
    
    # ==================== Méthodes pour les jardins ====================
    
    def add_garden(self, garden: Garden) -> int:
        """
        Ajoute un jardin à la base de données.
        
        Args:
            garden: Jardin à ajouter.
            
        Returns:
            int: ID du jardin ajouté.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO gardens (
                    name, description, location, area, notes
                ) VALUES (?, ?, ?, ?, ?)
            """, (
                garden.name,
                garden.description,
                garden.location,
                garden.area,
                garden.notes,
            ))
            garden.id = cursor.lastrowid
            
            # Ajouter les associations avec les plantes
            for plant in garden.plants:
                cursor.execute("""
                    INSERT INTO garden_plants (garden_id, plant_id)
                    VALUES (?, ?)
                """, (garden.id, plant.id))
            
            conn.commit()
            return garden.id
    
    def get_garden_by_id(self, garden_id: int) -> Optional[Garden]:
        """
        Récupère un jardin par son ID.
        
        Args:
            garden_id: ID du jardin.
            
        Returns:
            Garden ou None: Le jardin si trouvé, None sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM gardens WHERE id = ?", (garden_id,))
            row = cursor.fetchone()
            
            if row:
                garden = Garden(
                    id=row[0],
                    name=row[1],
                    description=row[2],
                    location=row[3],
                    area=row[4],
                    notes=row[5],
                )
                
                # Récupérer les plantes associées
                cursor.execute("""
                    SELECT p.* FROM plants p
                    JOIN garden_plants gp ON p.id = gp.plant_id
                    WHERE gp.garden_id = ?
                """, (garden_id,))
                plant_rows = cursor.fetchall()
                
                plants = []
                for plant_row in plant_rows:
                    plant = Plant(
                        id=plant_row[0],
                        name=plant_row[1],
                        description=plant_row[2],
                        plant_type=PlantType(plant_row[3]),
                        variety=plant_row[4],
                        planting_date=date.fromisoformat(plant_row[5]) if plant_row[5] else None,
                        harvest_date=date.fromisoformat(plant_row[6]) if plant_row[6] else None,
                        soil_type=SoilType(plant_row[7]),
                        sun_exposure=SunExposure(plant_row[8]),
                        watering_frequency=plant_row[9],
                        last_watering=date.fromisoformat(plant_row[10]) if plant_row[10] else None,
                        notes=plant_row[11],
                        image_path=plant_row[12],
                    )
                    plants.append(plant)
                
                garden.plants = plants
                return garden
            return None
    
    def get_all_gardens(self) -> List[Garden]:
        """
        Récupère tous les jardins de la base de données.
        
        Returns:
            List[Garden]: Liste de tous les jardins.
        """
        gardens = []
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM gardens")
            garden_rows = cursor.fetchall()
            
            for garden_row in garden_rows:
                garden = Garden(
                    id=garden_row[0],
                    name=garden_row[1],
                    description=garden_row[2],
                    location=garden_row[3],
                    area=garden_row[4],
                    notes=garden_row[5],
                )
                
                # Récupérer les plantes associées
                cursor.execute("""
                    SELECT p.* FROM plants p
                    JOIN garden_plants gp ON p.id = gp.plant_id
                    WHERE gp.garden_id = ?
                """, (garden_row[0],))
                plant_rows = cursor.fetchall()
                
                plants = []
                for plant_row in plant_rows:
                    plant = Plant(
                        id=plant_row[0],
                        name=plant_row[1],
                        description=plant_row[2],
                        plant_type=PlantType(plant_row[3]),
                        variety=plant_row[4],
                        planting_date=date.fromisoformat(plant_row[5]) if plant_row[5] else None,
                        harvest_date=date.fromisoformat(plant_row[6]) if plant_row[6] else None,
                        soil_type=SoilType(plant_row[7]),
                        sun_exposure=SunExposure(plant_row[8]),
                        watering_frequency=plant_row[9],
                        last_watering=date.fromisoformat(plant_row[10]) if plant_row[10] else None,
                        notes=plant_row[11],
                        image_path=plant_row[12],
                    )
                    plants.append(plant)
                
                garden.plants = plants
                gardens.append(garden)
        return gardens
    
    def update_garden(self, garden: Garden) -> bool:
        """
        Met à jour un jardin dans la base de données.
        
        Args:
            garden: Jardin à mettre à jour.
            
        Returns:
            bool: True si la mise à jour a réussi, False sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE gardens SET
                    name = ?,
                    description = ?,
                    location = ?,
                    area = ?,
                    notes = ?
                WHERE id = ?
            """, (
                garden.name,
                garden.description,
                garden.location,
                garden.area,
                garden.notes,
                garden.id,
            ))
            
            # Mettre à jour les associations avec les plantes
            cursor.execute("DELETE FROM garden_plants WHERE garden_id = ?", (garden.id,))
            for plant in garden.plants:
                cursor.execute("""
                    INSERT INTO garden_plants (garden_id, plant_id)
                    VALUES (?, ?)
                """, (garden.id, plant.id))
            
            conn.commit()
            return cursor.rowcount > 0
    
    def delete_garden(self, garden_id: int) -> bool:
        """
        Supprime un jardin de la base de données.
        
        Args:
            garden_id: ID du jardin à supprimer.
            
        Returns:
            bool: True si la suppression a réussi, False sinon.
        """
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Supprimer les associations avec les plantes
            cursor.execute("DELETE FROM garden_plants WHERE garden_id = ?", (garden_id,))
            
            # Supprimer le jardin
            cursor.execute("DELETE FROM gardens WHERE id = ?", (garden_id,))
            conn.commit()
            return cursor.rowcount > 0
