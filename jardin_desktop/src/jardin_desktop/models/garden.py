"""
Modèle pour le jardin dans l'application Jardin.
"""
from dataclasses import dataclass, field
from typing import List, Optional
from .plant import Plant


@dataclass
class Garden:
    """
    Représente un jardin (ou une zone de culture).
    
    Attributes:
        id: Identifiant unique du jardin.
        name: Nom du jardin ou de la zone.
        description: Description du jardin.
        location: Emplacement (ex: "Jardin avant", "Potager arrière").
        area: Surface en m².
        plants: Liste des plantes dans ce jardin.
        notes: Notes supplémentaires.
    """
    id: int
    name: str
    description: str = ""
    location: str = ""
    area: float = 0.0  # en m²
    plants: List[Plant] = field(default_factory=list)
    notes: str = ""
    
    def __post_init__(self):
        """Validation des données après initialisation."""
        if self.area < 0:
            raise ValueError("La surface du jardin ne peut pas être négative.")
    
    def add_plant(self, plant: Plant) -> None:
        """
        Ajoute une plante au jardin.
        
        Args:
            plant: Plante à ajouter.
        """
        self.plants.append(plant)
    
    def remove_plant(self, plant_id: int) -> bool:
        """
        Retire une plante du jardin par son ID.
        
        Args:
            plant_id: ID de la plante à retirer.
            
        Returns:
            bool: True si la plante a été retirée, False sinon.
        """
        for i, plant in enumerate(self.plants):
            if plant.id == plant_id:
                self.plants.pop(i)
                return True
        return False
    
    def get_plant_by_id(self, plant_id: int) -> Optional[Plant]:
        """
        Récupère une plante par son ID.
        
        Args:
            plant_id: ID de la plante à récupérer.
            
        Returns:
            Plant ou None: La plante si trouvée, None sinon.
        """
        for plant in self.plants:
            if plant.id == plant_id:
                return plant
        return None
    
    def to_dict(self) -> dict:
        """
        Convertit l'objet Garden en dictionnaire pour la sauvegarde.
        
        Returns:
            dict: Dictionnaire représentant le jardin.
        """
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "location": self.location,
            "area": self.area,
            "plants": [plant.to_dict() for plant in self.plants],
            "notes": self.notes,
        }
    
    @classmethod
    def from_dict(cls, data: dict, plants: List[Plant]) -> "Garden":
        """
        Crée une instance de Garden à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire contenant les données du jardin.
            plants: Liste des plantes associées.
            
        Returns:
            Garden: Instance de Garden.
        """
        garden = cls(
            id=data["id"],
            name=data["name"],
            description=data.get("description", ""),
            location=data.get("location", ""),
            area=data.get("area", 0.0),
            notes=data.get("notes", ""),
        )
        garden.plants = plants
        return garden
