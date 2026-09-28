from datetime import date

import pytest
from jardin_desktop.utils import helpers


@pytest.mark.parametrize(
    "test_date,expected_season",
    [
        (date(2024, 3, 21), "Printemps"),
        (date(2024, 6, 21), "Été"),
        (date(2024, 9, 21), "Automne"),
        (date(2024, 12, 21), "Hiver"),
    ],
)
def test_get_season(test_date, expected_season):
    assert helpers.get_season(test_date) == expected_season
