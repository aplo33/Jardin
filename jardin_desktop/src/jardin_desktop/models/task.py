"""
Modèle pour les tâches dans l'application Jardin.
"""
from dataclasses import dataclass
from typing import Optional
from datetime import date, time
from enum import Enum


class TaskType(Enum):
    """Type de tâche."""
    ARROSAGE = "Arrosage"
    TAILLE = "Taille"
    DESHERBAGE = "Désherbage"
    FERTILISATION = "Fertilisation"
    RECOLTE = "Récolte"
    AUTRE = "Autre"


class TaskStatus(Enum):
    """Statut de la tâche."""
    A_FAIRE = "À faire"
    EN_COURS = "En cours"
    TERMINE = "Terminé"


@dataclass
class Task:
    """
    Représente une tâche dans le jardin.
    
    Attributes:
        id: Identifiant unique de la tâche.
        title: Titre de la tâche.
        description: Description de la tâche.
        task_type: Type de tâche.
        due_date: Date limite pour la tâche.
        due_time: Heure limite pour la tâche.
        status: Statut de la tâche.
        plant_id: ID de la plante associée (optionnel).
        notes: Notes supplémentaires.
        completed_date: Date de complétion.
    """
    id: int
    title: str
    description: str = ""
    task_type: TaskType = TaskType.AUTRE
    due_date: Optional[date] = None
    due_time: Optional[time] = None
    status: TaskStatus = TaskStatus.A_FAIRE
    plant_id: Optional[int] = None
    notes: str = ""
    completed_date: Optional[date] = None
    
    def is_overdue(self) -> bool:
        """
        Vérifie si la tâche est en retard.
        
        Returns:
            bool: True si la tâche est en retard, False sinon.
        """
        if self.due_date is None or self.status == TaskStatus.TERMINE:
            return False
        
        today = date.today()
        return today > self.due_date
    
    def to_dict(self) -> dict:
        """
        Convertit l'objet Task en dictionnaire pour la sauvegarde.
        
        Returns:
            dict: Dictionnaire représentant la tâche.
        """
        return {
            "id": self.id,
            "title": self.title,
            "description": self.description,
            "task_type": self.task_type.value,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "due_time": self.due_time.isoformat() if self.due_time else None,
            "status": self.status.value,
            "plant_id": self.plant_id,
            "notes": self.notes,
            "completed_date": self.completed_date.isoformat() if self.completed_date else None,
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> "Task":
        """
        Crée une instance de Task à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire contenant les données de la tâche.
            
        Returns:
            Task: Instance de Task.
        """
        return cls(
            id=data["id"],
            title=data["title"],
            description=data.get("description", ""),
            task_type=TaskType(data.get("task_type", "Autre")),
            due_date=date.fromisoformat(data["due_date"]) if data.get("due_date") else None,
            due_time=time.fromisoformat(data["due_time"]) if data.get("due_time") else None,
            status=TaskStatus(data.get("status", "À faire")),
            plant_id=data.get("plant_id"),
            notes=data.get("notes", ""),
            completed_date=date.fromisoformat(data["completed_date"]) if data.get("completed_date") else None,
        )
