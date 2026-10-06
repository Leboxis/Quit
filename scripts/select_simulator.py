#!/usr/bin/env python3
"""Select a reproducible iPhone size, refusing to skip missing coverage."""
import argparse
import json
import os
import re
import subprocess


def select_device(devices, size='compact'):
    if size not in ('compact', 'large'):
        raise ValueError(f'Unknown simulator size: {size}')
    candidates = []
    for runtime, entries in devices.items():
        if '.iOS-' not in runtime:
            continue
        version = tuple(int(x) for x in runtime.rsplit('.iOS-', 1)[1].split('-'))
        for device in entries:
            name = device['name']
            if not device.get('isAvailable') or not name.startswith('iPhone'):
                continue
            large = 'Max' in name or 'Plus' in name
            if large != (size == 'large'):
                continue
            # Prefer smaller models within the newest matching runtime.
            rank = (0 if 'SE' in name else 1 if 'mini' in name else
                    2 if re.search(r'\d+e\b', name) else 4 if 'Pro' in name else
                    5 if 'Air' in name else 3)
            candidates.append((version, rank, device))
    if not candidates:
        raise ValueError(f'No available {size} iPhone Simulator; refusing to skip iOS tests.')
    newest = max(version for version, _, _ in candidates)
    return min((entry for entry in candidates if entry[0] == newest),
               key=lambda entry: (entry[1], entry[2]['name'], entry[2]['udid']))[2]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--size', choices=['compact', 'large'], default='compact')
    args = parser.parse_args()
    devices = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json']))['devices']
    try:
        device = select_device(devices, args.size)
    except ValueError as error:
        raise SystemExit(str(error)) from error
    udid = device['udid']
    print(f"Simulator ({args.size}): {device['name']} / {udid}")
    # Start booting while the caller compiles; wait with bootstatus before tests.
    subprocess.run(['xcrun', 'simctl', 'boot', udid], check=False,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if os.environ.get('GITHUB_OUTPUT'):
        with open(os.environ['GITHUB_OUTPUT'], 'a') as file:
            file.write(f'udid={udid}\n')
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as file:
            file.write(f"\nV2.1 simulator ({args.size}): {device['name']} / `{udid}`\n")


if __name__ == '__main__':
    main()
