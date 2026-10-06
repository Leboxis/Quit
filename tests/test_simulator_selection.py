import importlib.util
from pathlib import Path
import unittest


class SimulatorSelectionTests(unittest.TestCase):
    def setUp(self):
        spec = importlib.util.spec_from_file_location('select_simulator', Path(__file__).parents[1] / 'scripts/select_simulator.py')
        self.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.module)

    def device(self, name, udid, available=True):
        return {'name': name, 'udid': udid, 'isAvailable': available}

    def test_compact_and_large_are_distinct_on_newest_runtime(self):
        devices = {
            'com.apple.CoreSimulator.SimRuntime.iOS-18-0': [self.device('iPhone SE (3rd generation)', 'old')],
            'com.apple.CoreSimulator.SimRuntime.iOS-26-0': [self.device('iPhone 17 Pro Max', 'large'), self.device('iPhone 17 Pro', 'compact')],
        }
        self.assertEqual(self.module.select_device(devices, 'compact')['udid'], 'compact')
        self.assertEqual(self.module.select_device(devices, 'large')['udid'], 'large')

    def test_compact_prefers_smaller_model_on_same_runtime(self):
        devices = {'runtime.iOS-18-0': [self.device('iPhone 16 Pro', 'pro'), self.device('iPhone SE (3rd generation)', 'se')]}
        self.assertEqual(self.module.select_device(devices, 'compact')['udid'], 'se')

    def test_ignores_unavailable_devices_and_non_ios_runtimes(self):
        devices = {'runtime.iOS-26-0': [self.device('iPhone 17', 'missing', False)],
                   'runtime.iOS-18-0': [self.device('iPhone 16', 'available')],
                   'runtime.tvOS-26-0': [self.device('iPhone 17', 'wrong')]}
        self.assertEqual(self.module.select_device(devices, 'compact')['udid'], 'available')

    def test_large_refuses_to_substitute_same_compact_device(self):
        with self.assertRaisesRegex(ValueError, 'large'):
            self.module.select_device({'runtime.iOS-26-0': [self.device('iPhone 17', 'compact')]}, 'large')

    def test_selection_is_stable_when_inventory_order_changes(self):
        entries = [self.device('iPhone 17 Pro', 'z'), self.device('iPhone 17', 'a')]
        first = self.module.select_device({'runtime.iOS-26-0': entries}, 'compact')
        second = self.module.select_device({'runtime.iOS-26-0': list(reversed(entries))}, 'compact')
        self.assertEqual(first, second)


if __name__ == '__main__':
    unittest.main()
