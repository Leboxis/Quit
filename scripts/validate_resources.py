#!/usr/bin/env python3
import json
from pathlib import Path
import plistlib

root = Path(__file__).resolve().parents[1]
lessons = json.loads((root / 'Quit/Resources/lessons.json').read_text())
assert [item['id'] for item in lessons] == list(range(1, 43)), 'Expected 42 uniquely ordered lessons'
for item in lessons:
    assert all(isinstance(item[field], str) and item[field].strip() for field in ['title', 'body', 'prompt', 'action', 'source'])
    assert item['source'].startswith('https://pubmed.ncbi.nlm.nih.gov/')
for file in root.glob('Quit/Resources/**/*.json'):
    json.loads(file.read_text())
with (root / 'Quit/Resources/PrivacyInfo.xcprivacy').open('rb') as file:
    privacy = plistlib.load(file)
assert privacy['NSPrivacyTracking'] is False
assert not privacy['NSPrivacyCollectedDataTypes']
print('Resources validated: 42 complete lessons, valid assets, no tracking declaration.')
