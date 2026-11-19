"""
Modèle pour le plan graphique d'un jardin potager.
"""

from dataclasses import dataclass, field

from .plant import PlantType

# Type de plante -> couleur d'affichage (R, G, B)
TYPE_COLORS: dict[str, tuple[int, int, int]] = {
    PlantType.LEGUME.value: (230, 126, 34),
    PlantType.FLEUR.value: (231, 76, 160),
    PlantType.AROMATIQUE.value: (39, 174, 96),
    PlantType.FRUITIER.value: (192, 57, 43),
    PlantType.ARBRE.value: (101, 67, 33),
    PlantType.AUTRE.value: (127, 140, 141),
}

# Largeur par défaut d'une parcelle en mètres
DEFAULT_PLOT_SIZE = 2.0

# Espacement par défaut d'une plante en mètres
DEFAULT_MARKER_SIZE = 0.5


@dataclass
class PlanPlot:
    """
    Représente une parcelle ou une planche de culture sur le plan.

    Attributes:
        name: Nom de la parcelle (ex: "Planche tomates").
        x: Position X en mètres.
        y: Position Y en mètres.
        width: Largeur en mètres.
        height: Hauteur en mètres.
        color: Couleur en valeur entière RGB (ex: 0x6a4f2d).
        notes: Notes supplémentaires.
    """

    name: str = ""
    x: float = 0.0
    y: float = 0.0
    width: float = DEFAULT_PLOT_SIZE
    height: float = DEFAULT_PLOT_SIZE
    color: int = 0x8D6E63
    notes: str = ""

    def contains_point(self, px: float, py: float) -> bool:
        """Indique si le point (px, py) en mètres est dans la parcelle."""
        return (
            self.x <= px <= self.x + self.width and self.y <= py <= self.y + self.height
        )

    def to_dict(self) -> dict:
        """Convertit la parcelle en dictionnaire pour la sauvegarde."""
        return {
            "name": self.name,
            "x": self.x,
            "y": self.y,
            "width": self.width,
            "height": self.height,
            "color": self.color,
            "notes": self.notes,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "PlanPlot":
        """Crée une parcelle à partir d'un dictionnaire."""
        return cls(
            name=data.get("name", ""),
            x=data.get("x", 0.0),
            y=data.get("y", 0.0),
            width=data.get("width", DEFAULT_PLOT_SIZE),
            height=data.get("height", DEFAULT_PLOT_SIZE),
            color=data.get("color", 0x8D6E63),
            notes=data.get("notes", ""),
        )


@dataclass
class PlanMarker:
    """
    Représente une plante positionnée sur le plan.

    Attributes:
        label: Libellé affiché (ex: "Tomate Cerise").
        plant_type: Type de plante (détermine la couleur du marqueur).
        x: Position X en mètres.
        y: Position Y en mètres.
        size: Diamètre en mètres.
    """

    label: str = ""
    plant_type: str = PlantType.LEGUME.value
    x: float = 0.0
    y: float = 0.0
    size: float = DEFAULT_MARKER_SIZE

    def get_color(self) -> tuple[int, int, int]:
        """Retourne la couleur (R, G, B) associée au type de plante."""
        return TYPE_COLORS.get(self.plant_type, TYPE_COLORS[PlantType.AUTRE.value])

    def to_dict(self) -> dict:
        """Convertit le marqueur en dictionnaire pour la sauvegarde."""
        return {
            "label": self.label,
            "plant_type": self.plant_type,
            "x": self.x,
            "y": self.y,
            "size": self.size,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "PlanMarker":
        """Crée un marqueur à partir d'un dictionnaire."""
        return cls(
            label=data.get("label", ""),
            plant_type=data.get("plant_type", PlantType.LEGUME.value),
            x=data.get("x", 0.0),
            y=data.get("y", 0.0),
            size=data.get("size", DEFAULT_MARKER_SIZE),
        )


@dataclass
class GardenPlan:
    """
    Représente le plan complet d'un potager.

    Attributes:
        title: Titre du plan.
        plots: Liste des parcelles.
        markers: Liste des plantes placées.
        grid_size: Taille de la grille en mètres (accrochage).
    """

    title: str = "Plan du potager"
    plots: list[PlanPlot] = field(default_factory=list)
    markers: list[PlanMarker] = field(default_factory=list)
    grid_size: float = 0.5

    def bounds(self) -> tuple[float, float, float, float]:
        """
        Calcule l'emprise du plan en mètres.

        Returns:
            tuple: (x_min, y_min, largeur, hauteur).
        """
        xs = [p.x for p in self.plots] + [m.x for m in self.markers]
        ys = [p.y for p in self.plots] + [m.y for m in self.markers]

        if not xs:
            return (0.0, 0.0, 10.0, 10.0)

        x_max_plots = [p.x + p.width for p in self.plots]
        y_max_plots = [p.y + p.height for p in self.plots]

        x_end = max(xs + x_max_plots)
        y_end = max(ys + y_max_plots)

        return (0.0, 0.0, x_end, y_end)

    def total_area(self) -> float:
        """Retourne la surface totale cultivée en m² (somme des parcelles)."""
        return sum(plot.width * plot.height for plot in self.plots)

    def to_dict(self) -> dict:
        """Convertit le plan en dictionnaire pour la sauvegarde."""
        return {
            "title": self.title,
            "grid_size": self.grid_size,
            "plots": [plot.to_dict() for plot in self.plots],
            "markers": [marker.to_dict() for marker in self.markers],
        }

    @classmethod
    def from_dict(cls, data: dict) -> "GardenPlan":
        """Crée un plan à partir d'un dictionnaire."""
        return cls(
            title=data.get("title", "Plan du potager"),
            plots=[PlanPlot.from_dict(d) for d in data.get("plots", [])],
            markers=[PlanMarker.from_dict(d) for d in data.get("markers", [])],
            grid_size=data.get("grid_size", 0.5),
        )
