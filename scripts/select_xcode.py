#!/usr/bin/env python3
import os
from pathlib import Path
import plistlib
import subprocess

choices = []
for app in Path('/Applications').glob('Xcode*.app'):
    version_file = app / 'Contents/version.plist'
    if version_file.exists():
        with version_file.open('rb') as file:
            version = plistlib.load(file).get('CFBundleShortVersionString', '0')
        components = tuple(int(p) for p in version.split('.') if p.isdigit())
        if components and components[0] >= 26:
            choices.append((components, app))
if not choices:
    raise SystemExit('Xcode 26 or later is required for Liquid Glass.')
version, app = max(choices, key=lambda item: item[0])
subprocess.run(['sudo', 'xcode-select', '-s', str(app / 'Contents/Developer')], check=True)
subprocess.run(['xcodebuild', '-version'], check=True)
note = 'iOS 27 SDK selected.' if version[0] >= 27 else 'Xcode 27 unavailable on this runner; native iOS 26 SDK fallback selected. Native controls adapt on iOS 27.'
print(note)
if os.environ.get('GITHUB_STEP_SUMMARY'):
    with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as file:
        file.write(f'\n{note}\n')
