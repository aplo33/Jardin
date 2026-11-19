"""
Tests du modèle et de l'éditeur de plan de potager.
"""

import os

import pytest
from jardin_desktop.models.plan import GardenPlan, PlanMarker, PlanPlot
from jardin_desktop.models.plant import PlantType

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")


def _pyqt6_loadable() -> bool:
    """Indique si PyQt6 peut être chargé (dépend des librairies système)."""
    try:
        import PyQt6.QtWidgets  # noqa: F401

        return True
    except ImportError:
        return False


def test_plot_roundtrip():
    plot = PlanPlot(name="Planche tomates", x=1.0, y=2.0, width=3.5, height=1.2)
    data = plot.to_dict()
    loaded = PlanPlot.from_dict(data)
    assert loaded == plot


def test_marker_roundtrip_and_color():
    marker = PlanMarker(label="Tomate", plant_type=PlantType.LEGUME.value, x=2.5, y=3.0)
    data = marker.to_dict()
    loaded = PlanMarker.from_dict(data)
    assert loaded == marker
    r, g, b = loaded.get_color()
    assert (r, g, b) == (230, 126, 34)


def test_plan_bounds_and_area():
    plan = GardenPlan(
        plots=[
            PlanPlot(x=0, y=0, width=2, height=3),
            PlanPlot(x=4, y=0, width=1, height=1),
        ],
        markers=[PlanMarker(x=6, y=5)],
    )
    assert plan.total_area() == pytest.approx(7.0)
    assert plan.bounds() == (0.0, 0.0, 6.0, 5.0)


def test_plan_roundtrip():
    plan = GardenPlan(
        title="Mon potager",
        plots=[PlanPlot(name="P1", x=0.5, y=0.5, width=2.0, height=1.0)],
        markers=[PlanMarker(label="Tomate", x=1.0, y=1.0)],
        grid_size=0.25,
    )
    data = plan.to_dict()
    loaded = GardenPlan.from_dict(data)
    assert loaded == plan


@pytest.mark.skipif(not _pyqt6_loadable(), reason="PyQt6 indisponible")
def test_editor_widget_offscreen():
    from jardin_desktop.views.plan_editor import PlanEditor
    from PyQt6.QtWidgets import QApplication

    app = QApplication.instance() or QApplication([])
    editor = PlanEditor()
    assert editor.plan.title == "Plan du potager"
    assert editor.view.scene() is editor.scene
    assert len(editor.palette_plants) > 0
    app.processEvents()
