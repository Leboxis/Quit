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
    def test_content_colors_meet_normal_text_contrast(self):
        for foreground, soft in [('SlateAccent', 'SlateSoft'), ('PlumAccent', 'PlumSoft'), ('Amber', 'AmberSoft')]:
            for dark in (False, True):
                for background in (soft, 'Background', 'Surface', 'AccentSoft', 'SlateSoft', 'SandSoft'):
                    with self.subTest(foreground=foreground, background=background, dark=dark):
                        self.assertGreaterEqual(contrast(color(foreground, dark), color(background, dark)), 4.5)

    def test_body_and_secondary_text_are_readable_on_all_card_surfaces(self):
        for foreground in ('TextPrimary', 'TextSecondary'):
            for background in ('Background', 'Surface', 'AccentSoft', 'SlateSoft', 'SandSoft', 'PlumSoft', 'AmberSoft'):
                for dark in (False, True):
                    with self.subTest(foreground=foreground, background=background, dark=dark):
                        self.assertGreaterEqual(contrast(color(foreground, dark), color(background, dark)), 4.5)

    def test_calendar_symbols_and_chart_marks_have_sufficient_contrast(self):
        for dark in (False, True):
            self.assertGreaterEqual(contrast(color('OnAccent', dark), color('Amber', dark)), 4.5)
            self.assertGreaterEqual(contrast(color('OnAccent', dark), color('SlateAccent', dark)), 4.5)
            self.assertGreaterEqual(contrast(color('TextPrimary', dark), color('Border', dark)), 4.5)
            for mark in ('Amber', 'AccentColor', 'SlateAccent', 'SandAccent'):
                with self.subTest(mark=mark, dark=dark):
                    self.assertGreaterEqual(contrast(color(mark, dark), color('Surface', dark)), 3)

    def test_accent_text_is_readable_on_tinted_cards_in_every_appearance(self):
        for accent, soft in [('AccentColor', 'AccentSoft'), ('SlateAccent', 'SlateSoft'), ('SandAccent', 'SandSoft')]:
            for dark in (False, True):
                for background in (soft, 'Background', 'Surface', 'PlumSoft', 'AmberSoft'):
                    with self.subTest(theme=accent, background=background, dark=dark):
                        self.assertGreaterEqual(contrast(color(accent, dark), color(background, dark)), 4.5)

    def test_primary_button_labels_meet_normal_text_contrast(self):
        for accent in ('AccentColor', 'SlateAccent', 'SandAccent'):
            for dark in (False, True):
                with self.subTest(theme=accent, dark=dark):
                    self.assertGreaterEqual(contrast(color('OnAccent', dark), color(accent, dark)), 4.5)
