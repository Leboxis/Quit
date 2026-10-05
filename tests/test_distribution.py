import importlib.util
import json
import plistlib
from pathlib import Path
import tempfile
import unittest
import zipfile


class DistributionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        spec = importlib.util.spec_from_file_location('distribution', Path(__file__).parents[1] / 'scripts/distribution.py')
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def ipa(self, **overrides):
        info = {'CFBundleIdentifier': 'fr.leboxis.quit', 'CFBundleShortVersionString': '0.1.42',
                'CFBundleVersion': '42', 'MinimumOSVersion': '18.0', 'CFBundleExecutable': 'Quit',
                'CFBundlePackageType': 'APPL'}
        info.update(overrides)
        file = self.root / 'Quit.ipa'
        with zipfile.ZipFile(file, 'w') as z:
            z.writestr('Payload/Quit.app/Info.plist', plistlib.dumps(info))
            z.writestr('Payload/Quit.app/Quit', b'fake mach-o')
        return file

    def test_catalog_uses_compiled_version_and_actual_bytes(self):
        ipa = self.ipa()
        source = self.module.make_source(ipa, 'Leboxis/Quit', 'v0.1.42', '2026-10-05')
        app = source['apps'][0]
        version = app['versions'][0]
        self.assertEqual(app['bundleIdentifier'], 'fr.leboxis.quit')
        self.assertEqual(version['version'], '0.1.42')
        self.assertEqual(version['size'], ipa.stat().st_size)
        self.assertEqual(version['downloadURL'], 'https://github.com/Leboxis/Quit/releases/download/v0.1.42/Quit.ipa')
        self.assertEqual(version['minOSVersion'], '18.0')
        self.assertEqual(app['version'], version['version'])

    def test_rejects_mismatched_release_tag(self):
        with self.assertRaises(ValueError):
            self.module.make_source(self.ipa(), 'Leboxis/Quit', 'v0.1.41', '2026-10-05')

    def test_rejects_profile_or_signature(self):
        for path in ('Payload/Quit.app/embedded.mobileprovision', 'Payload/Quit.app/_CodeSignature/CodeResources'):
            ipa = self.ipa()
            with zipfile.ZipFile(ipa, 'a') as z:
                z.writestr(path, 'forbidden')
            with self.assertRaises(ValueError):
                self.module.make_source(ipa, 'Leboxis/Quit', 'v0.1.42', '2026-10-05')

    def test_rejects_extensions_for_livecontainer(self):
        ipa = self.ipa()
        with zipfile.ZipFile(ipa, 'a') as z:
            z.writestr('Payload/Quit.app/PlugIns/Shield.appex/Info.plist', 'extension')
        with self.assertRaises(ValueError):
            self.module.make_source(ipa, 'Leboxis/Quit', 'v0.1.42', '2026-10-05')

    def test_rejects_wrong_bundle_identifier(self):
        with self.assertRaises(ValueError):
            self.module.make_source(self.ipa(CFBundleIdentifier='different.app'), 'Leboxis/Quit', 'v0.1.42', '2026-10-05')

    def test_version_history_is_newest_first_and_deduplicated(self):
        old = self.module.make_source(self.ipa(), 'Leboxis/Quit', 'v0.1.42', '2026-10-05')
        newest = self.module.make_source(self.ipa(CFBundleShortVersionString='0.1.43', CFBundleVersion='43'),
                                          'Leboxis/Quit', 'v0.1.43', '2026-10-06', previous=old)
        newest = self.module.make_source(self.ipa(CFBundleShortVersionString='0.1.43', CFBundleVersion='43'),
                                          'Leboxis/Quit', 'v0.1.43', '2026-10-06', previous=newest)
        self.assertEqual([v['version'] for v in newest['apps'][0]['versions']], ['0.1.43', '0.1.42'])


if __name__ == '__main__':
    unittest.main()
