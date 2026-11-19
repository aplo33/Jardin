"""
Éditeur graphique de plan de potager.

Permet de dessiner des parcelles, de placer des plantes et d'exporter
le plan en PNG ou en JSON.
"""

import json

from jardin_desktop.models.plan import (
    DEFAULT_MARKER_SIZE,
    TYPE_COLORS,
    GardenPlan,
    PlanMarker,
    PlanPlot,
)
from jardin_desktop.models.plant import PlantType
from PyQt6.QtCore import QPointF, QRectF, Qt, pyqtSignal
from PyQt6.QtGui import QBrush, QColor, QKeySequence, QPainter, QPen, QPixmap
from PyQt6.QtWidgets import (
    QComboBox,
    QFileDialog,
    QGraphicsEllipseItem,
    QGraphicsRectItem,
    QGraphicsScene,
    QGraphicsSimpleTextItem,
    QGraphicsView,
    QHBoxLayout,
    QInputDialog,
    QLabel,
    QLineEdit,
    QListWidget,
    QListWidgetItem,
    QMessageBox,
    QPushButton,
    QToolButton,
    QVBoxLayout,
    QWidget,
)

# Échelle du plan : 1 mètre = 50 pixels
PX_PER_METER = 50

# Taille minimale d'une parcelle en mètres
MIN_PLOT_SIZE = 0.25

# Affichage des marqueurs
MARKER_PEN_WIDTH = 2
HANDLE_MARGIN = 10  # marge de prise des poignées, en pixels

# Couleurs en campagnes (valeur entière RGB) proposées pour une parcelle
PLOT_COLORS = [0x8D6E63, 0x4CAF50, 0xF9A825, 0x0288D1, 0x7B1FA2]

# Palette de départ de l'éditeur
DEFAULT_PLANTS = [
    ("Tomate", PlantType.LEGUME),
    ("Carotte", PlantType.LEGUME),
    ("Salade", PlantType.LEGUME),
    ("Radis", PlantType.LEGUME),
    ("Basilic", PlantType.AROMATIQUE),
    ("Ciboulette", PlantType.AROMATIQUE),
    ("Lavande", PlantType.FLEUR),
    ("Rosier", PlantType.FLEUR),
    ("Fraisier", PlantType.FRUITIER),
    ("Pommier", PlantType.ARBRE),
]


class EditorMode:
    """Modes d'édition disponibles pour la scène."""

    SELECT = "select"
    DRAW_PLOT = "plot"
    PLACE_MARKER = "marker"


class PlotItem(QGraphicsRectItem):
    """
    Parcelle dessinée sur le plan (rectangle déplaçable et redimensionnable).
    """

    def __init__(self, plot: PlanPlot, on_changed):
        super().__init__(
            QRectF(
                plot.x * PX_PER_METER,
                plot.y * PX_PER_METER,
                plot.width * PX_PER_METER,
                plot.height * PX_PER_METER,
            )
        )
        self.plot = plot
        self.on_changed = on_changed
        self._resize_corner: str | None = None

        self.setFlags(
            QGraphicsRectItem.GraphicsItemFlag.ItemIsMovable
            | QGraphicsRectItem.GraphicsItemFlag.ItemIsSelectable
            | QGraphicsRectItem.GraphicsItemFlag.ItemSendsGeometryChanges
        )
        self._apply_style()

    def _apply_style(self) -> None:
        """Applique la couleur et le style de la parcelle."""
        color = QColor(self.plot.color)
        self.setBrush(QBrush(QColor(color.red(), color.green(), color.blue(), 100)))
        self.setPen(QPen(color.darker(130), 2))
        self.setToolTip(self.plot.name if self.plot.name else "Parcelle")

    def refresh(self) -> None:
        """Met à jour le rectangle depuis le modèle."""
        self.prepareGeometryChange()
        self.setRect(
            QRectF(
                self.plot.x * PX_PER_METER,
                self.plot.y * PX_PER_METER,
                self.plot.width * PX_PER_METER,
                self.plot.height * PX_PER_METER,
            )
        )
        self._apply_style()

    def paint(self, painter, option, widget=None) -> None:
        super().paint(painter, option, widget)

        if self.isSelected():
            painter.setBrush(QBrush(QColor(255, 255, 255)))
            painter.setPen(QPen(QColor(40, 40, 40), 1))
            for corner in self._corners():
                painter.drawRect(QRectF(corner.x() - 5, corner.y() - 5, 10, 10))

    def _corners(self) -> dict[str, QPointF]:
        """Retourne les coins du rectangle en coordonnées locales."""
        r = self.rect()
        return {
            "tl": r.topLeft(),
            "tr": r.topRight(),
            "bl": r.bottomLeft(),
            "br": r.bottomRight(),
        }

    def _corner_at(self, pos: QPointF) -> str | None:
        """Retourne le coin situé sous la position donnée, s'il existe."""
        for name, corner in self._corners().items():
            if (
                abs(pos.x() - corner.x()) <= HANDLE_MARGIN
                and abs(pos.y() - corner.y()) <= HANDLE_MARGIN
            ):
                return name
        return None

    def mousePressEvent(self, event) -> None:
        if event.button() == Qt.MouseButton.LeftButton:
            self._resize_corner = self._corner_at(event.pos())
        super().mousePressEvent(event)

    def mouseMoveEvent(self, event) -> None:
        if self._resize_corner:
            self._resize_to(event.scenePos())
        else:
            super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event) -> None:
        if self._resize_corner:
            self._resize_corner = None
            self._sync_model()
            self.on_changed()
        super().mouseReleaseEvent(event)

    def _resize_to(self, scene_pos: QPointF) -> None:
        """Redimensionne la parcelle depuis le coin tenu."""
        scene_rect = self.sceneBoundingRect()
        x1, y1 = scene_rect.left(), scene_rect.top()
        x2, y2 = scene_rect.right(), scene_rect.bottom()

        if "l" in self._resize_corner:
            x1 = scene_pos.x()
        else:
            x2 = scene_pos.x()
        if "t" in self._resize_corner:
            y1 = scene_pos.y()
        else:
            y2 = scene_pos.y()

        self.prepareGeometryChange()
        self.setRect(QRectF(QPointF(x1, y1), QPointF(x2, y2)).normalized())
        self._sync_model(pixels=True)

    def _sync_model(self, pixels: bool = False) -> None:
        """Synchronise le modèle avec la géométrie de l'item."""
        if pixels:
            rect = self.rect()
            origin = self.mapToScene(rect.topLeft())
            x_px, y_px = origin.x(), origin.y()
        else:
            rect = self.sceneBoundingRect()
            x_px, y_px = rect.left(), rect.top()

        self.plot.x = round(x_px / PX_PER_METER, 2)
        self.plot.y = round(y_px / PX_PER_METER, 2)
        self.plot.width = max(round(rect.width() / PX_PER_METER, 2), MIN_PLOT_SIZE)
        self.plot.height = max(round(rect.height() / PX_PER_METER, 2), MIN_PLOT_SIZE)

    def itemChange(self, change, value):
        if change == QGraphicsRectItem.GraphicsItemChange.ItemPositionHasChanged:
            self._sync_model(pixels=False)
            self.on_changed()
        return super().itemChange(change, value)

    def keyPressEvent(self, event) -> None:
        if event.key() == Qt.Key.Key_F2:
            self._rename()
        else:
            super().keyPressEvent(event)

    def mouseDoubleClickEvent(self, event) -> None:
        self._rename()

    def _rename(self) -> None:
        """Demande un nouveau nom et une nouvelle couleur pour la parcelle."""
        name, ok = QInputDialog.getText(
            None, "Nom de la parcelle", "Nom :", text=self.plot.name
        )
        if not ok:
            return
        self.plot.name = name.strip()
        self.setToolTip(self.plot.name if self.plot.name else "Parcelle")
        self.update()
        self.on_changed()


class MarkerItem(QGraphicsEllipseItem):
    """
    Marqueur de plante (cercle coloré déplaçable avec un libellé).
    """

    def __init__(self, marker: PlanMarker, on_changed):
        size_px = marker.size * PX_PER_METER
        super().__init__(0, 0, size_px, size_px)
        self.marker = marker
        self.on_changed = on_changed

        self.setFlags(
            QGraphicsEllipseItem.GraphicsItemFlag.ItemIsMovable
            | QGraphicsEllipseItem.GraphicsItemFlag.ItemIsSelectable
            | QGraphicsEllipseItem.GraphicsItemFlag.ItemSendsGeometryChanges
        )

        r, g, b = marker.get_color()
        self.setBrush(QBrush(QColor(r, g, b)))
        self.setPen(QPen(QColor(30, 30, 30), MARKER_PEN_WIDTH))
        self.setZValue(10)
        self._update_label()
        self.refresh_position()

    def _update_label(self) -> None:
        """Met à jour le libellé et l'infobulle du marqueur."""
        self.setToolTip(f"{self.marker.label} ({self.marker.plant_type})")
        if hasattr(self, "label_item") and self.label_item is not None:
            self.label_item.setText(self.marker.label)
        else:
            self.label_item = QGraphicsSimpleTextItem(self.marker.label, self)
            self.label_item.setBrush(QBrush(QColor(20, 20, 20)))
            self.label_item.setPos(
                (self.marker.size * PX_PER_METER) / 2
                - self.label_item.boundingRect().width() / 2,
                self.marker.size * PX_PER_METER + 2,
            )

    def refresh_position(self) -> None:
        """Replace le marqueur selon le modèle."""
        self.setPos(self.marker.x * PX_PER_METER, self.marker.y * PX_PER_METER)

    def mouseDoubleClickEvent(self, event) -> None:
        text, ok = QInputDialog.getText(
            None, "Libellé de la plante", "Nom :", text=self.marker.label
        )
        if ok:
            self.marker.label = text.strip()
            self._update_label()
            self.on_changed()

    def itemChange(self, change, value):
        if change == QGraphicsEllipseItem.GraphicsItemChange.ItemPositionHasChanged:
            pos = self.pos()
            self.marker.x = round(
                (pos.x() + self.marker.size * PX_PER_METER / 2) / PX_PER_METER, 2
            )
            self.marker.y = round(
                (pos.y() + self.marker.size * PX_PER_METER / 2) / PX_PER_METER, 2
            )
            self.on_changed()
        return super().itemChange(change, value)


class PlanScene(QGraphicsScene):
    """
    Scène du plan de potager : grille, dessin de parcelles, placement de plantes.
    """

    plan_changed = pyqtSignal()
    status_message = pyqtSignal(str)
    cursor_moved = pyqtSignal(float, float)

    def __init__(self, plan: GardenPlan, parent=None):
        super().__init__(parent)
        self.plan = plan
        self.mode = EditorMode.SELECT
        self.current_plant_label = ""
        self.current_plant_type = PlantType.LEGUME.value
        self._temp_rect: QGraphicsRectItem | None = None
        self._plot_counter = 0

        self.setBackgroundBrush(QBrush(QColor(0xF5, 0xF1, 0xE8)))
        self.load_plan(plan)
        self.setSceneRect(
            -2 * PX_PER_METER, -2 * PX_PER_METER, 32 * PX_PER_METER, 32 * PX_PER_METER
        )

    def set_mode(self, mode: str) -> None:
        """Change le mode d'édition."""
        self.mode = mode
        self.clearSelection()

    def load_plan(self, plan: GardenPlan) -> None:
        """Charge (ou recharge) entièrement le plan."""
        self.plan = plan
        self.clear()
        for plot in plan.plots:
            self.addItem(PlotItem(plot, self._emit_changed))
        for marker in plan.markers:
            self.addItem(MarkerItem(marker, self._emit_changed))
        self._plot_counter = len(plan.plots)

    def delete_selection(self) -> None:
        """Supprime tous les éléments sélectionnés."""
        count = 0
        for item in list(self.selectedItems()):
            if isinstance(item, PlotItem):
                self.plan.plots.remove(item.plot)
                self.removeItem(item)
                count += 1
            elif isinstance(item, MarkerItem):
                self.plan.markers.remove(item.marker)
                self.removeItem(item)
                count += 1
        if count:
            self._emit_changed()
            self.status_message.emit(f"{count} élément(s) supprimé(s)")

    def snap(self, pos: QPointF) -> QPointF:
        """Accroche un point à la grille (en pixels)."""
        step = self.plan.grid_size * PX_PER_METER
        return QPointF(round(pos.x() / step) * step, round(pos.y() / step) * step)

    def snap_m(self, pos: QPointF) -> QPointF:
        """Accroche un point à la grille et le convertit en mètres."""
        scene_pos = self.snap(pos)
        return QPointF(
            round(scene_pos.x() / PX_PER_METER, 2),
            round(scene_pos.y() / PX_PER_METER, 2),
        )

    def _emit_changed(self) -> None:
        self.plan_changed.emit()

    def mousePressEvent(self, event) -> None:
        if event.button() != Qt.MouseButton.LeftButton:
            super().mousePressEvent(event)
            return

        scene_pos = event.scenePos()

        if self.mode == EditorMode.DRAW_PLOT:
            snapped = self.snap(scene_pos)
            self._temp_rect = QGraphicsRectItem(QRectF(snapped, snapped))
            self._temp_rect.setPen(QPen(QColor(60, 60, 60), 2, Qt.PenStyle.DashLine))
            self.addItem(self._temp_rect)
        elif self.mode == EditorMode.PLACE_MARKER:
            pos_m = self.snap_m(scene_pos)
            marker = PlanMarker(
                label=self.current_plant_label or "Plante",
                plant_type=self.current_plant_type,
                x=pos_m.x(),
                y=pos_m.y(),
                size=DEFAULT_MARKER_SIZE,
            )
            self.plan.markers.append(marker)
            self.addItem(MarkerItem(marker, self._emit_changed))
            self._emit_changed()
        else:
            super().mousePressEvent(event)

    def mouseMoveEvent(self, event) -> None:
        scene_pos = event.scenePos()
        pos_m = QPointF(
            round(scene_pos.x() / PX_PER_METER, 2),
            round(scene_pos.y() / PX_PER_METER, 2),
        )
        self.cursor_moved.emit(pos_m.x(), pos_m.y())

        if self.mode == EditorMode.DRAW_PLOT and self._temp_rect is not None:
            self._temp_rect.setRect(
                QRectF(
                    self.snap(self._temp_rect.rect().topLeft()), self.snap(scene_pos)
                ).normalized()
            )
        else:
            super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event) -> None:
        if self.mode == EditorMode.DRAW_PLOT and self._temp_rect is not None:
            rect = self._temp_rect.rect()
            self.removeItem(self._temp_rect)
            self._temp_rect = None

            width_m = round(rect.width() / PX_PER_METER, 2)
            height_m = round(rect.height() / PX_PER_METER, 2)

            if width_m >= MIN_PLOT_SIZE and height_m >= MIN_PLOT_SIZE:
                top_left = self.snap(rect.topLeft())
                self._plot_counter += 1
                plot = PlanPlot(
                    name=f"Parcelle {self._plot_counter}",
                    x=round(top_left.x() / PX_PER_METER, 2),
                    y=round(top_left.y() / PX_PER_METER, 2),
                    width=width_m,
                    height=height_m,
                )
                self.plan.plots.append(plot)
                item = PlotItem(plot, self._emit_changed)
                self.addItem(item)
                item.setSelected(True)
                self._emit_changed()
                self.status_message.emit(
                    f"Parcelle créée : {width_m} m × {height_m} m "
                    f"({plot.width * plot.height:.2f} m²) — double-clic pour renommer"
                )
            else:
                self.status_message.emit("Parcelle trop petite")
            return

        super().mouseReleaseEvent(event)

    def keyPressEvent(self, event) -> None:
        if event.key() == Qt.Key.Key_Delete:
            self.delete_selection()
        else:
            super().keyPressEvent(event)

    def drawBackground(self, painter: QPainter, rect: QRectF) -> None:
        super().drawBackground(painter, rect)

        step = self.plan.grid_size * PX_PER_METER
        pen_light = QPen(QColor(0xE0, 0xDA, 0xCE))
        pen_heavy = QPen(QColor(0xD0, 0xC8, 0xB8))

        x_start = int(rect.left() // step) * step
        y_start = int(rect.top() // step) * step

        painter.setPen(pen_light)
        x = x_start
        while x < rect.right():
            if round(x / PX_PER_METER) == x / PX_PER_METER:
                painter.setPen(pen_heavy)
            painter.drawLine(QPointF(x, rect.top()), QPointF(x, rect.bottom()))
            painter.setPen(pen_light)
            x += step

        painter.setPen(pen_light)
        y = y_start
        while y < rect.bottom():
            if round(y / PX_PER_METER) == y / PX_PER_METER:
                painter.setPen(pen_heavy)
            painter.drawLine(QPointF(rect.left(), y), QPointF(rect.right(), y))
            painter.setPen(pen_heavy)
            y += step


class PlanView(QGraphicsView):
    """
    Vue graphique avec zoom à la molette.
    """

    def __init__(self, scene: PlanScene, parent=None):
        super().__init__(scene, parent)
        self.setRenderHint(QPainter.RenderHint.Antialiasing)
        self.setDragMode(QGraphicsView.DragMode.RubberBandDrag)
        self.setTransformationAnchor(QGraphicsView.ViewportAnchor.AnchorUnderMouse)
        self._zoom = 1.0

    def wheelEvent(self, event) -> None:
        factor = 1.15 if event.angleDelta().y() > 0 else 1 / 1.15
        self._zoom = max(0.3, min(self._zoom * factor, 5.0))
        self.setTransform(self.transform().fromScale(self._zoom, self._zoom))

    def fit_plan(self) -> None:
        """Ajuste la vue sur l'emprise du plan."""
        _, _, w, h = self.scene().plan.bounds()
        self.setSceneRect(
            -1 * PX_PER_METER,
            -1 * PX_PER_METER,
            (w + 2) * PX_PER_METER + 50,
            (h + 2) * PX_PER_METER + 50,
        )
        self.resetTransform()

    def zoom_in(self) -> None:
        self._apply_zoom(1.15)

    def zoom_out(self) -> None:
        self._apply_zoom(1 / 1.15)

    def _apply_zoom(self, factor: float) -> None:
        self._zoom = max(0.3, min(self._zoom * factor, 5.0))
        self.setTransform(self.transform().fromScale(self._zoom, self._zoom))


class PlanEditor(QWidget):
    """
    Widget principal de l'éditeur de plan de potager.
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self.plan = GardenPlan()
        scene = PlanScene(self.plan)
        self.scene = scene
        self.view = PlanView(scene)

        self.palette_plants: list[tuple[str, PlantType]] = list(DEFAULT_PLANTS)

        self._init_ui()
        self._reload_palette()
        self._update_info()
        self.view.fit_plan()

        self.scene.plan_changed.connect(self._update_info)
        self.scene.status_message.connect(lambda msg: self.info_label.setText(msg))
        self.scene.cursor_moved.connect(self._on_cursor_moved)

    def _init_ui(self) -> None:
        """Initialise l'interface utilisateur."""
        layout = QVBoxLayout(self)
        layout.setContentsMargins(10, 10, 10, 10)

        # Barre d'outils et boutons de fichier
        tools_layout = QHBoxLayout()
        tools_layout.setSpacing(5)
        layout.addLayout(tools_layout)

        self.btn_select = QToolButton()
        self.btn_select.setText("Sélection")
        self.btn_select.setCheckable(True)
        self.btn_select.setChecked(True)
        self.btn_select.setToolTip("Sélectionner / déplacer (Échap pour revenir ici)")

        self.btn_plot = QToolButton()
        self.btn_plot.setText("Nouvelle parcelle")
        self.btn_plot.setCheckable(True)
        self.btn_plot.setToolTip("Dessiner une parcelle en glissant la souris")

        self.btn_marker = QToolButton()
        self.btn_marker.setText("Placer une plante")
        self.btn_marker.setCheckable(True)
        self.btn_marker.setToolTip("Placer la plante sélectionnée dans la palette")

        for btn in [self.btn_select, self.btn_plot, self.btn_marker]:
            tools_layout.addWidget(btn)

        self.btn_delete = QToolButton()
        self.btn_delete.setText("Supprimer")
        self.btn_delete.setEnabled(False)
        self.btn_delete.clicked.connect(self.scene.delete_selection)
        tools_layout.addWidget(self.btn_delete)

        tools_layout.addWidget(QLabel("Grille (m) :"))
        self.grid_spin = QComboBox()
        for value in [0.25, 0.5, 1.0]:
            self.grid_spin.addItem(f"{value}")
        self.grid_spin.setCurrentText("0.5")
        self.grid_spin.currentTextChanged.connect(self._on_grid_changed)
        tools_layout.addWidget(self.grid_spin)

        btn_zoom_in = QToolButton()
        btn_zoom_in.setText("Zoom +")
        btn_zoom_in.clicked.connect(self.view.zoom_in)
        tools_layout.addWidget(btn_zoom_in)

        btn_zoom_out = QToolButton()
        btn_zoom_out.setText("Zoom -")
        btn_zoom_out.clicked.connect(self.view.zoom_out)
        tools_layout.addWidget(btn_zoom_out)

        btn_fit = QToolButton()
        btn_fit.setText("Ajuster")
        btn_fit.clicked.connect(self.view.fit_plan)
        tools_layout.addWidget(btn_fit)

        tools_layout.addStretch()

        btn_new = QPushButton("Nouveau")
        btn_new.clicked.connect(self._on_new_plan)
        tools_layout.addWidget(btn_new)

        btn_open = QPushButton("Ouvrir…")
        btn_open.clicked.connect(self._on_open)
        tools_layout.addWidget(btn_open)

        btn_save = QPushButton("Enregistrer…")
        btn_save.setShortcut(QKeySequence("Ctrl+Shift+S"))
        btn_save.clicked.connect(self._on_save)
        tools_layout.addWidget(btn_save)

        btn_png = QPushButton("Exporter en PNG…")
        btn_png.clicked.connect(self._on_export_png)
        tools_layout.addWidget(btn_png)

        # Corps : palette à gauche, vue au centre, infos à droite
        content_layout = QHBoxLayout()
        layout.addLayout(content_layout, stretch=1)

        # Palette de plantes
        palette_panel = QWidget()
        palette_layout = QVBoxLayout(palette_panel)
        palette_layout.addWidget(QLabel("<b>Palette de plantes</b>"))

        self.palette_list = QListWidget()
        self.palette_list.setSelectionMode(QListWidget.SelectionMode.SingleSelection)
        palette_layout.addWidget(self.palette_list)

        self.plant_name_edit = QLineEdit()
        self.plant_name_edit.setPlaceholderText("Nom de la plante")
        palette_layout.addWidget(self.plant_name_edit)

        self.plant_type_combo = QComboBox()
        for plant_type in PlantType:
            self.plant_type_combo.addItem(plant_type.value, plant_type)
        palette_layout.addWidget(self.plant_type_combo)

        btn_add_plant = QPushButton("Ajouter à la palette")
        btn_add_plant.clicked.connect(self._on_add_palette_plant)
        palette_layout.addWidget(btn_add_plant)

        btn_remove_plant = QPushButton("Retirer de la palette")
        btn_remove_plant.clicked.connect(self._on_remove_palette_plant)
        palette_layout.addWidget(btn_remove_plant)

        content_layout.addWidget(palette_panel, stretch=1)

        # Vue du plan
        content_layout.addWidget(self.view, stretch=4)

        # Barre d'état
        self.info_label = QLabel("Prêt")
        layout.addWidget(self.info_label)

        # Connexions des outils
        self.btn_select.clicked.connect(lambda: self._set_mode(EditorMode.SELECT))
        self.btn_plot.clicked.connect(lambda: self._set_mode(EditorMode.DRAW_PLOT))
        self.btn_marker.clicked.connect(lambda: self._set_mode(EditorMode.PLACE_MARKER))
        self.palette_list.currentRowChanged.connect(self._on_palette_selected)
        self.scene.selectionChanged.connect(self._on_selection_changed)

        self._set_mode(EditorMode.SELECT)
        self.palette_list.setCurrentRow(0)

    def _reload_palette(self) -> None:
        """Recharge la liste de la palette de plantes."""
        self.palette_list.clear()
        for label, plant_type in self.palette_plants:
            r, g, b = TYPE_COLORS.get(plant_type.value, (127, 140, 141))
            item = QListWidgetItem(label)
            item.setData(Qt.ItemDataRole.UserRole, (label, plant_type.value))
            item.setForeground(QColor(40, 40, 40))
            self.palette_list.addItem(item)
            item.setBackground(QColor(r, g, b, 60))

    def _on_add_palette_plant(self) -> None:
        """Ajoute une plante à la palette depuis les champs de saisie."""
        name = self.plant_name_edit.text().strip()
        if not name:
            QMessageBox.warning(
                self, "Ajout impossible", "Veuillez saisir un nom de plante."
            )
            return
        plant_type = self.plant_type_combo.currentData()
        self.palette_plants.append((name, plant_type))
        self.plant_name_edit.clear()
        self._reload_palette()
        self.palette_list.setCurrentRow(len(self.palette_plants) - 1)

    def _on_remove_palette_plant(self) -> None:
        """Retire la plante sélectionnée de la palette."""
        row = self.palette_list.currentRow()
        if 0 <= row < len(self.palette_plants):
            del self.palette_plants[row]
            self._reload_palette()

    def _on_palette_selected(self, row: int) -> None:
        """Sélectionne la plante courante pour le placement."""
        if 0 <= row < len(self.palette_plants):
            label, plant_type = self.palette_plants[row]
            self.scene.current_plant_label = label
            self.scene.current_plant_type = plant_type

    def _set_mode(self, mode: str) -> None:
        """Change l'outil actif de l'éditeur."""
        self.scene.set_mode(mode)
        for btn, btn_mode in [
            (self.btn_select, EditorMode.SELECT),
            (self.btn_plot, EditorMode.DRAW_PLOT),
            (self.btn_marker, EditorMode.PLACE_MARKER),
        ]:
            btn.setChecked(btn_mode == mode)

        if mode == EditorMode.SELECT:
            self.view.setDragMode(QGraphicsView.DragMode.RubberBandDrag)
            self.info_label.setText("Outil : Sélection")
        elif mode == EditorMode.DRAW_PLOT:
            self.view.setDragMode(QGraphicsView.DragMode.NoDrag)
            self.info_label.setText("Outil : Nouvelle parcelle — glissez sur la grille")
        else:
            plant = self.scene.current_plant_label or "plante"
            self.view.setDragMode(QGraphicsView.DragMode.NoDrag)
            self.info_label.setText(
                f"Outil : Placer une plante — cliquez pour poser « {plant} »"
            )

    def _on_selection_changed(self) -> None:
        self.btn_delete.setEnabled(bool(self.scene.selectedItems()))

    def _on_grid_changed(self, text: str) -> None:
        self.plan.grid_size = float(text)
        self.scene.update()

    def _on_cursor_moved(self, x: float, y: float) -> None:
        self.info_label.setText(f"Position : {x:.2f} m ; {y:.2f} m")

    def _update_info(self) -> None:
        """Met à jour les informations du plan."""
        area = self.plan.total_area()
        self.setToolTip(
            f"{len(self.plan.plots)} parcelle(s) — surface totale : {area:.2f} m²"
        )

    def _on_new_plan(self) -> None:
        """Crée un nouveau plan vide."""
        self.plan = GardenPlan()
        self.scene.load_plan(self.plan)
        self.view.fit_plan()
        self._update_info()

    def _on_open(self) -> None:
        """Charge un plan depuis un fichier JSON."""
        path, _ = QFileDialog.getOpenFileName(
            self, "Ouvrir un plan", "", "Plan de potager (*.json)"
        )
        if not path:
            return
        try:
            with open(path, encoding="utf-8") as f:
                self.plan = GardenPlan.from_dict(json.load(f))
            self.grid_spin.blockSignals(True)
            self.grid_spin.setCurrentText(str(self.plan.grid_size))
            self.grid_spin.blockSignals(False)
            self.scene.load_plan(self.plan)
            self.view.fit_plan()
            self._update_info()
        except (OSError, json.JSONDecodeError, KeyError) as exc:
            QMessageBox.critical(self, "Erreur", f"Ouverture impossible : {exc}")

    def _on_save(self) -> None:
        """Enregistre le plan dans un fichier JSON."""
        path, _ = QFileDialog.getSaveFileName(
            self, "Enregistrer le plan", "plan_potager.json", "Plan de potager (*.json)"
        )
        if not path:
            return
        try:
            with open(path, "w", encoding="utf-8") as f:
                json.dump(self.plan.to_dict(), f, indent=2, ensure_ascii=False)
            QMessageBox.information(self, "Enregistré", f"Plan enregistré dans {path}")
        except OSError as exc:
            QMessageBox.critical(self, "Erreur", f"Enregistrement impossible : {exc}")

    def _on_export_png(self) -> None:
        """Exporte le plan en image PNG."""
        path, _ = QFileDialog.getSaveFileName(
            self, "Exporter le plan en PNG", "plan_potager.png", "Image PNG (*.png)"
        )
        if not path:
            return

        bounds = QRectF(self.scene.itemsBoundingRect()).adjusted(-40, -40, 40, 40)
        image = QPixmap(int(bounds.width()), int(bounds.height()))
        image.fill(QColor(0xFF, 0xFF, 0xFF))

        painter = QPainter(image)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)
        self.scene.render(painter, source=bounds)
        painter.end()

        if image.save(path, "PNG"):
            QMessageBox.information(self, "Exporté", f"Plan exporté vers {path}")
        else:
            QMessageBox.critical(self, "Erreur", "Export impossible.")
