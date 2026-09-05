# Jardin App - Gestion de Jardin

Une application Flutter complète pour la gestion de votre jardin d'agrément et potager. Fonctionne sur mobile (Android, iOS) et desktop (Windows, Mac, Linux).

## Fonctionnalités

### 🌱 Gestion des Plantes
- **Création et gestion** des fiches plantes complètes
- **Types de plantes** : Légumes, Fruits, Plantes aromatiques, Fleurs, Arbres, Arbustes
- **Catégories détaillées** : Légumineuses, Aromatiques, Salades, Racines, etc.
- **Caractéristiques** : Exposition au soleil, besoin en eau, type de sol, pH idéal
- **Informations de plantation** : Dates, espacement, profondeur, jours jusqu'à maturité
- **Associations** : Plantes compagnes et plantes à éviter
- **Conseils** : Instructions de soin et de récolte
- **Favoris** : Marquez vos plantes préférées
- **Statut** : Active/Inactive

### 📋 Gestion des Tâches
- **Création et suivi** des tâches du jardin
- **Types** : Arrosage, Taille, Fertilisation, Récolte, Plantation, Désherbage, Lutte contre les nuisibles
- **Priorités** : Faible, Moyenne, Haute, Urgente
- **Statuts** : En attente, En cours, Terminée, Annulée
- **Notifications** : Rappels automatiques pour les tâches
- **Tâches récurrentes** : Configuration de répétition
- **Association** : Liaison avec des plantes et jardins spécifiques

### 🍅 Gestion des Récoltes
- **Enregistrement** des récoltes avec quantité et unité
- **Qualité** : Évaluation de la qualité (Excellente, Bonne, Moyenne, Faible)
- **Historique** : Suivi complet par plante et par jardin
- **Statistiques** : Totaux, moyennes, dernières récoltes

### 🏡 Gestion des Jardins
- **Création** de plusieurs jardins
- **Types** : Potager, Jardin d'agrément, Verger, Serre, Mixte
- **Informations** : Surface, emplacement
- **Sélection** : Choix du jardin actuel

### 📅 Calendrier
- **Visualisation** des événements du jardin
- **Types d'événements** : Tâches, Récoltes, Plantations
- **Filtres** : Par date, mois, année
- **Indicateurs visuels** : Couleurs par type d'événement

### ⚙️ Paramètres
- **Statistiques globales** : Nombre de plantes, tâches, récoltes, jardins
- **Gestion des jardins** : Ajout, modification, suppression
- **Sauvegarde** : Export des données (à venir)
- **Restauration** : Import des données (à venir)
- **Notifications** : Configuration des alertes
- **À propos** : Informations sur l'application

## Installation

### Prérequis
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.0.0 ou supérieur
- Android Studio / Xcode (pour le développement mobile)
- Un émulateur ou un appareil physique

### Étapes

1. **Cloner le dépôt**
```bash
git clone https://github.com/aplo33/Jardin.git
cd Jardin/jardin_app
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Exécuter l'application**
```bash
# Pour Android
flutter run -d android

# Pour iOS
flutter run -d ios

# Pour Windows
flutter run -d windows

# Pour Mac
flutter run -d macos

# Pour Linux
flutter run -d linux

# Pour Web
flutter run -d chrome
```

## Structure du Projet

```
jardin_app/
├── lib/
│   ├── main.dart                    # Point d'entrée
│   ├── models/                      # Modèles de données
│   │   ├── plant.dart               # Plante
│   │   ├── task.dart                # Tâche
│   │   ├── harvest.dart             # Récolte
│   │   └── garden.dart              # Jardin
│   ├── providers/                   # Gestion d'état
│   │   ├── plant_provider.dart      # Fournisseur Plantes
│   │   ├── task_provider.dart       # Fournisseur Tâches
│   │   ├── harvest_provider.dart    # Fournisseur Récoltes
│   │   └── garden_provider.dart     # Fournisseur Jardins
│   ├── services/                    # Services
│   │   └── notification_service.dart # Notifications
│   ├── screens/                     # Écrans
│   │   ├── home_screen.dart         # Accueil
│   │   ├── plants_screen.dart       # Liste Plantes
│   │   ├── tasks_screen.dart        # Liste Tâches
│   │   ├── calendar_screen.dart     # Calendrier
│   │   ├── harvests_screen.dart     # Liste Récoltes
│   │   ├── plant_detail_screen.dart # Détails Plante
│   │   ├── add_edit_plant_screen.dart # Ajout/Édition Plante
│   │   ├── add_edit_task_screen.dart # Ajout/Édition Tâche
│   │   └── settings_screen.dart     # Paramètres
│   ├── utils/                       # Utilitaires
│   │   └── theme.dart                # Thème et styles
│   └── widgets/                     # Widgets réutilisables
├── assets/                         # Ressources
│   ├── images/                      # Images
│   └── data/                        # Données
├── pubspec.yaml                     # Dépendances
└── README.md                        # Documentation
```

## Technologies Utilisées

- **[Flutter](https://flutter.dev/)** - Framework UI multiplateforme
- **[Hive](https://pub.dev/packages/hive)** - Base de données locale NoSQL
- **[Provider](https://pub.dev/packages/provider)** - Gestion d'état
- **[Go Router](https://pub.dev/packages/go_router)** - Navigation
- **[flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)** - Notifications locales
- **[table_calendar](https://pub.dev/packages/table_calendar)** - Calendrier interactif
- **[flutter_slidable](https://pub.dev/packages/flutter_slidable)** - Actions glissables
- **[intl](https://pub.dev/packages/intl)** - Internationalisation
- **[fl_chart](https://pub.dev/packages/fl_chart)** - Graphiques
- **[uuid](https://pub.dev/packages/uuid)** - Génération d'IDs uniques

## Captures d'écran

*(À ajouter après les tests)*

## Roadmap

### Version 1.1 (À venir)
- [ ] Statistiques avancées avec graphiques
- [ ] Export/Import des données (JSON)
- [ ] Synchronisation cloud (Firebase)
- [ ] Recherche avancée
- [ ] Tri personnalisable des listes

### Version 1.2
- [ ] Reconnaissance d'images des plantes
- [ ] Conseils personnalisés basés sur la météo
- [ ] Intégration avec des API météorologiques
- [ ] Base de données de plantes pré-remplie
- [ ] Partage de jardin entre utilisateurs

### Version 1.3
- [ ] Mode hors ligne amélioré
- [ ] Sauvegarde automatique
- [ ] Historique des modifications
- [ ] Multi-langues
- [ ] Thème personnalisable

## Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créez une branche de fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commitez vos modifications (`git commit -m 'Add some AmazingFeature'`)
4. Poussez vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## Licence

Ce projet est sous licence MIT - voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Contact

Pour toute question ou suggestion, n'hésitez pas à ouvrir une issue sur GitHub.

---

**Jardin App** - Votre compagnon numérique pour un jardin réussi ! 🌱🍅🌸
