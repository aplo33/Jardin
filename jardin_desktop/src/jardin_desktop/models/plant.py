"""
Modèle pour les plantes dans l'application Jardin.
"""
from dataclasses import dataclass, field
from typing import Optional
from datetime import date
from enum import Enum


class PlantType(Enum):
    """Type de plante (légume, fleur, aromatique, etc.)."""
    LEGUME = "Légume"
    FLEUR = "Fleur"
    AROMATIQUE = "Aromatique"
    FRUITIER = "Fruitier"
    ARBRE = "Arbre"
    AUTRE = "Autre"


class SoilType(Enum):
    """Type de sol adapté à la plante."""
    ARGILEUX = "Argileux"
    SABLEUX = "Sableux"
    LIMONEUX = "Limoneux"
    CALCAIRE = "Calcaire"
    HUMIFERE = "Humifère"


class SunExposure(Enum):
    """Exposition au soleil."""
    PLEIN_SOLEIL = "Plein soleil"
    MI_OMBRE = "Mi-ombre"
    OMBRE = "Ombre"


@dataclass
class Plant:
    """
    Représente une plante dans le jardin.
    
    Attributes:
        id: Identifiant unique de la plante.
        name: Nom de la plante.
        description: Description de la plante.
        plant_type: Type de plante (Légume, Fleur, etc.).
        variety: Variété de la plante.
        planting_date: Date de plantation.
        harvest_date: Date de récolte prévue.
        soil_type: Type de sol adapté.
        sun_exposure: Exposition au soleil.
        watering_frequency: Fréquence d'arrosage (en jours).
        last_watering: Date du dernier arrosage.
        notes: Notes supplémentaires.
        image_path: Chemin vers une image de la plante.
    """
    id: int
    name: str
    description: str = ""
    plant_type: PlantType = PlantType.AUTRE
    variety: str = ""
    planting_date: Optional[date] = None
    harvest_date: Optional[date] = None
    soil_type: SoilType = SoilType.ARGILEUX
    sun_exposure: SunExposure = SunExposure.PLEIN_SOLEIL
    watering_frequency: int = 7  # En jours
    last_watering: Optional[date] = None
    notes: str = ""
    image_path: Optional[str] = None
    
    def __post_init__(self):
        """Validation des données après initialisation."""
        if self.watering_frequency <= 0:
            raise ValueError("La fréquence d'arrosage doit être supérieure à 0.")
    
    def needs_watering(self) -> bool:
        """
        Vérifie si la plante a besoin d'être arrosée.
        
        Returns:
            bool: True si la plante a besoin d'eau, False sinon.
        """
        if self.last_watering is None:
            return True
        
        from datetime import timedelta
        days_since_watering = (date.today() - self.last_watering).days
        return days_since_watering >= self.watering_frequency
    
    def to_dict(self) -> dict:
        """
        Convertit l'objet Plant en dictionnaire pour la sauvegarde.
        
        Returns:
            dict: Dictionnaire représentant la plante.
        """
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "plant_type": self.plant_type.value,
            "variety": self.variety,
            "planting_date": self.planting_date.isoformat() if self.planting_date else None,
            "harvest_date": self.harvest_date.isoformat() if self.harvest_date else None,
            "soil_type": self.soil_type.value,
            "sun_exposure": self.sun_exposure.value,
            "watering_frequency": self.watering_frequency,
            "last_watering": self.last_watering.isoformat() if self.last_watering else None,
            "notes": self.notes,
            "image_path": self.image_path,
        }
    
    @classmethod
    def from_dict(cls, data: dict) -> "Plant":
        """
        Crée une instance de Plant à partir d'un dictionnaire.
        
        Args:
            data: Dictionnaire contenant les données de la plante.
            
        Returns:
            Plant: Instance de Plant.
        """
        return cls(
            id=data["id"],
            name=data["name"],
            description=data.get("description", ""),
            plant_type=PlantType(data.get("plant_type", "Autre")),
            variety=data.get("variety", ""),
            planting_date=date.fromisoformat(data["planting_date"]) if data.get("planting_date") else None,
            harvest_date=date.fromisoformat(data["harvest_date"]) if data.get("harvest_date") else None,
            soil_type=SoilType(data.get("soil_type", "Argileux")),
            sun_exposure=SunExposure(data.get("sun_exposure", "Plein soleil")),
            watering_frequency=data.get("watering_frequency", 7),
            last_watering=date.fromisoformat(data["last_watering"]) if data.get("last_watering") else None,
            notes=data.get("notes", ""),
            image_path=data.get("image_path"),
        )
