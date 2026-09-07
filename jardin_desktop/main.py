#!/usr/bin/env python3
"""
Application Jardin Desktop - Gestion de jardin d'agrément et potager.

Cette application permet de gérer vos plantes, tâches, récoltes et jardins
de manière simple et intuitive avec une interface native en PyQt6.
"""

import sys
from PyQt6.QtWidgets import QApplication
from views.main_window import MainWindow
from database.database_manager import DatabaseManager


def main():
    """Point d'entrée de l'application."""
    app = QApplication(sys.argv)
    app.setApplicationName("Jardin Desktop")
    app.setOrganizationName("JardinApp")
    
    # Initialiser la base de données
    db_manager = DatabaseManager()
    
    # Créer et afficher la fenêtre principale
    window = MainWindow(db_manager)
    window.showMaximized()
    
    # Démarrer l'application
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
