"""
Fonctions utilitaires pour l'application Jardin.
"""
import random
from datetime import date
from typing import Optional


def generate_id() -> int:
    """
    Génère un ID unique aléatoire.
    
    Returns:
        int: Un ID unique.
    """
    return random.randint(1, 1000000)


def format_date(d: Optional[date], format_str: str = "%d/%m/%Y") -> str:
    """
    Formate une date en chaîne de caractères.
    
    Args:
        d: Date à formater (peut être None).
        format_str: Format de sortie (par défaut: JJ/MM/AAAA).
        
    Returns:
        str: Date formatée ou chaîne vide si d est None.
    """
    if d is None:
        return ""
    return d.strftime(format_str)


def format_date_french(d: Optional[date]) -> str:
    """
    Formate une date en français (ex: 15 janvier 2025).
    
    Args:
        d: Date à formater (peut être None).
        
    Returns:
        str: Date formatée en français ou chaîne vide si d est None.
    """
    if d is None:
        return ""
    
    months = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    ]
    return f"{d.day} {months[d.month - 1]} {d.year}"


def get_season(d: Optional[date] = None) -> str:
    """
    Détermine la saison en fonction d'une date.
    
    Args:
        d: Date à évaluer (par défaut: date actuelle).
        
    Returns:
        str: Saison (Printemps, Été, Automne, Hiver).
    """
    if d is None:
        d = date.today()
    
    month = d.month
    day = d.day
    
    if (month == 3 and day >= 21) or (month == 4 or month == 5) or (month == 6 and day <= 20):
        return "Printemps"
    elif (month == 6 and day >= 21) or (month == 7 or month == 8) or (month == 9 and day <= 20):
        return "Été"
    elif (month == 9 and day >= 21) or (month == 10 or month == 11) or (month == 12 and day <= 20):
        return "Automne"
    else:
        return "Hiver"


def get_watering_advice(plant_type: str, season: str) -> str:
    """
    Donne des conseils d'arrosage en fonction du type de plante et de la saison.
    
    Args:
        plant_type: Type de plante (ex: "Légume", "Fleur", etc.).
        season: Saison actuelle.
        
    Returns:
        str: Conseil d'arrosage.
    """
    advice = {
        "Légume": {
            "Printemps": "Arroser régulièrement pour favoriser la croissance.",
            "Été": "Arroser abondamment le matin ou le soir pour éviter l'évaporation.",
            "Automne": "Réduire l'arrosage progressivement.",
            "Hiver": "Arroser très peu, seulement si le sol est sec.",
        },
        "Fleur": {
            "Printemps": "Arroser modérément pour stimuler la floraison.",
            "Été": "Arroser régulièrement pour maintenir l'humidité.",
            "Automne": "Diminuer l'arrosage pour préparer l'hiver.",
            "Hiver": "Arroser très peu.",
        },
        "Aromatique": {
            "Printemps": "Arroser légèrement pour éviter l'excès d'eau.",
            "Été": "Arroser régulièrement, mais éviter de mouiller les feuilles.",
            "Automne": "Réduire l'arrosage.",
            "Hiver": "Arroser très peu.",
        },
        "Fruitier": {
            "Printemps": "Arroser régulièrement pendant la floraison.",
            "Été": "Arroser abondamment pendant la croissance des fruits.",
            "Automne": "Réduire l'arrosage après la récolte.",
            "Hiver": "Arroser très peu.",
        },
    }
    
    return advice.get(plant_type, {}).get(season, "Arroser selon les besoins de la plante.")
