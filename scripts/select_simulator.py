#!/usr/bin/env python3
import json
import os
import subprocess

devices = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json']))['devices']
candidates = []
for runtime, entries in devices.items():
    if '.iOS-' in runtime:
        version = tuple(int(x) for x in runtime.rsplit('.iOS-', 1)[1].split('-'))
        for device in entries:
            if device.get('isAvailable') and device['name'].startswith('iPhone'):
                candidates.append((version, device['udid']))
if not candidates:
    raise SystemExit('No available iPhone Simulator runtime; refusing to skip iOS tests.')
_, udid = max(candidates)
print(f'Simulator: {udid}')
subprocess.run(['xcrun', 'simctl', 'boot', udid], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
subprocess.run(['xcrun', 'simctl', 'bootstatus', udid, '-b'], check=True)
if os.environ.get('GITHUB_OUTPUT'):
    with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
        file.write(f'udid={udid}\n')
