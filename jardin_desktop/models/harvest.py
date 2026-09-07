"""
Modèle pour les récoltes dans l'application Jardin.
"""
from dataclasses import dataclass
from typing import Optional
from datetime import date


@dataclass
class Harvest:
    """
    Représente une récolte dans le jardin.
    
    Attributes:
        id: Identifiant unique de la récolte.
        plant_id: ID de la plante associée.
        date: Date de la récolte.
        quantity: Quantité récoltée (en kg, unités, etc.).
        unit: Unité de mesure (kg, g, pièce, etc.).
        notes: Notes supplémentaires.
        image_path: Chemin vers une image de la récolte.
    """
    id: int
    plant_id: int
    date: date
    quantity: float
    unit: str = "kg"
    notes: str = ""
    image_path: Optional[str] = None
    
    def __post_init__(self):
        """Validation des données après initialisation."""
        if self.quantity <= 0:
            raise ValueError("La quantité récoltée doit être supérieure à 0.")
    
    def to_dict(self) -> dict:
        """
        Convertit l'objet Harvest en dictionnaire pour la sauvegarde.
        
        Returns:
            dict: Dictionnaire représentant la récolte.
        """
        return {
            "id": self.id,
            "plant_id": self.plant_id,
            "date": self.date.isoformat(),
            "quantity": self.quantity,
            "unit": self.unit,
            "notes": self.notes,
            "image_path": self.image_path,
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> "Harvest":
        """
        Crée une instance de Harvest à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire contenant les données de la récolte.
            
        Returns:
            Harvest: Instance de Harvest.
        """
        return cls(
            id=data["id"],
            plant_id=data["plant_id"],
            date=date.fromisoformat(data["date"]),
            quantity=data["quantity"],
            unit=data.get("unit", "kg"),
            notes=data.get("notes", ""),
            image_path=data.get("image_path"),
        )
