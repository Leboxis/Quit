import json
from pathlib import Path
import unittest


ASSETS = Path(__file__).parents[1] / 'Quit/Resources/Assets.xcassets'


def color(name, dark):
    entries = json.loads((ASSETS / f'{name}.colorset/Contents.json').read_text())['colors']
    entry = next(item for item in entries if bool(item.get('appearances')) == dark)
    return [float(entry['color']['components'][key]) for key in ('red', 'green', 'blue')]


def luminance(channels):
    linear = [v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in channels]
    return sum(v * weight for v, weight in zip(linear, (.2126, .7152, .0722)))


def contrast(a, b):
    bright, dim = sorted((luminance(a), luminance(b)), reverse=True)
    return (bright + .05) / (dim + .05)


class ThemeContrastTests(unittest.TestCase):
    def test_accent_text_is_readable_on_tinted_cards_in_every_appearance(self):
        for accent, soft in [('AccentColor', 'AccentSoft'), ('SlateAccent', 'SlateSoft'), ('SandAccent', 'SandSoft')]:
            for dark in (False, True):
                with self.subTest(theme=accent, dark=dark):
                    self.assertGreaterEqual(contrast(color(accent, dark), color(soft, dark)), 4.5)

    def test_primary_button_labels_meet_normal_text_contrast(self):
        for accent in ('AccentColor', 'SlateAccent', 'SandAccent'):
            for dark in (False, True):
                with self.subTest(theme=accent, dark=dark):
                    self.assertGreaterEqual(contrast(color('OnAccent', dark), color(accent, dark)), 4.5)
