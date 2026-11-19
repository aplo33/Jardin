#!/usr/bin/env python3
"""
Éditeur de plan de potager - lancement autonome.

Permet d'utiliser l'outil de dessin de plan sans lancer
le reste de l'application Jardin Desktop.
"""

import sys
from pathlib import Path

from PyQt6.QtWidgets import QApplication

sys.path.insert(0, str(Path(__file__).parent / "src"))

from jardin_desktop.views.plan_editor import PlanEditor


def main():
    """Point d'entrée de l'éditeur de plan."""
    app = QApplication(sys.argv)
    app.setApplicationName("Plan de potager")

    window = PlanEditor()
    window.resize(1280, 800)
    window.setWindowTitle("Plan de potager - Outil de dessin")
    window.show()

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
