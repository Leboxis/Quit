#!/usr/bin/env python3
"""Package an unsigned device app and build an AltStore/SideStore source."""
import argparse
from datetime import date
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import struct
import zipfile

BUNDLE_ID = 'fr.leboxis.quit'


def _has_macho_signature(data):
    if data[:4] not in (b'\xcf\xfa\xed\xfe', b'\xce\xfa\xed\xfe'):
        return False
    header_size = 32 if data[:4] == b'\xcf\xfa\xed\xfe' else 28
    if len(data) < header_size:
        raise ValueError('Truncated Mach-O header')
    commands = struct.unpack_from('<I', data, 16)[0]
    offset = header_size
    for _ in range(commands):
        if offset + 8 > len(data):
            raise ValueError('Truncated Mach-O load commands')
        command, size = struct.unpack_from('<II', data, offset)
        if size < 8 or offset + size > len(data):
            raise ValueError('Invalid Mach-O load command')
        if command == 0x1D and size >= 16:
            if struct.unpack_from('<I', data, offset + 12)[0] > 0:
                return True
        offset += size
    return False


def inspect_ipa(ipa):
    with zipfile.ZipFile(ipa) as archive:
        # ZIP paths are POSIX on every host. Inspect the original spelling before
        # ZipInfo's Windows normalization can conceal malformed separators.
        names = [member.orig_filename for member in archive.infolist()]
        if len(names) != len(set(names)):
            raise ValueError('Duplicate paths inside IPA')
        for name in names:
            if name.startswith('/') or '\\' in name or '..' in PurePosixPath(name).parts:
                raise ValueError('Unsafe archive path')
            if '_CodeSignature' in PurePosixPath(name).parts or name.endswith('embedded.mobileprovision'):
                raise ValueError('Signed/provisioned bundle is not allowed')
            if '.appex/' in name or '/PlugIns/' in name:
                raise ValueError('Extensions are not supported by this LiveContainer build')
        if archive.testzip() is not None:
            raise ValueError('Corrupt ZIP member')
        infos = [n for n in names if n.startswith('Payload/') and n.endswith('.app/Info.plist') and len(PurePosixPath(n).parts) == 3]
        if len(infos) != 1:
            raise ValueError('IPA must contain exactly one application')
        info = plistlib.loads(archive.read(infos[0]))
        if info.get('CFBundleIdentifier') != BUNDLE_ID or info.get('CFBundlePackageType') != 'APPL':
            raise ValueError('Unexpected bundle identity')
        executable_name = info.get('CFBundleExecutable')
        if not isinstance(executable_name, str) or not executable_name or executable_name in ('.', '..') or '/' in executable_name or '\\' in executable_name:
            raise ValueError('Invalid app executable')
        executable = str(PurePosixPath(infos[0]).parent / executable_name)
        if executable not in names:
            raise ValueError('Missing app executable')
        for name in names:
            if not name.endswith('/') and _has_macho_signature(archive.read(name)):
                raise ValueError(f'Embedded Mach-O signature: {name}')
        for key in ('CFBundleShortVersionString', 'CFBundleVersion', 'MinimumOSVersion'):
            if not isinstance(info.get(key), str) or not info[key]:
                raise ValueError(f'Missing {key}')
        return info


def package_app(app, output):
    app = Path(app)
    output = Path(output)
    if not app.is_dir() or app.name != 'Quit.app':
        raise ValueError('Expected a built Quit.app directory')
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for file in sorted(app.rglob('*')):
            if file.is_file():
                archive.write(file, str(PurePosixPath('Payload') / app.name / file.relative_to(app).as_posix()))
    return inspect_ipa(output)


def make_source(ipa, repository, tag, release_date, previous=None):
    ipa = Path(ipa)
    info = inspect_ipa(ipa)
    version = info['CFBundleShortVersionString']
    if tag != f'v{version}':
        raise ValueError('Release tag must match the compiled app version')
    date.fromisoformat(release_date)
    if repository != 'Leboxis/Quit':
        raise ValueError('Unexpected release repository')
    download = f'https://github.com/{repository}/releases/download/{tag}/Quit.ipa'
    icon = f'https://raw.githubusercontent.com/{repository}/main/docs/design/icon.png'
    current = {'version': version, 'buildVersion': info['CFBundleVersion'], 'date': release_date,
               'localizedDescription': 'Quit V4-V6 : SOS personnalisé avec tes gestes utiles, habitudes concrètes dans Comprendre, et parcours recommandé selon tes difficultés. Journal, check-ins, plans Si → Alors et 42 exercices conservés.',
               'downloadURL': download, 'size': ipa.stat().st_size, 'minOSVersion': info['MinimumOSVersion']}
    history = []
    if previous:
        for app in previous.get('apps', []):
            if app.get('bundleIdentifier') == BUNDLE_ID:
                history = [v for v in app.get('versions', []) if v.get('version') != version]
                break
    app = {'name': 'Quit', 'bundleIdentifier': BUNDLE_ID, 'developerName': 'Leboxis',
           'subtitle': 'Reprendre le contrôle, un geste à la fois.',
           'localizedDescription': 'Un compagnon privé pour changer son usage de pornographie. Check-in, SOS, journal sans jugement, plans Si → Alors et 42 exercices. Données locales, aucune publicité. Ne remplace pas un professionnel. Cette build sans extensions ne bloque pas automatiquement les applications.',
           'iconURL': icon, 'tintColor': '346451', 'versions': [current] + history[:29],
           # Legacy fields support older source readers.
           'version': version, 'versionDate': release_date, 'versionDescription': current['localizedDescription'],
           'downloadURL': download, 'size': current['size'],
           'appPermissions': {'entitlements': [], 'privacy': {'NSFaceIDUsageDescription': 'Déverrouiller ton espace personnel Quit.'}}}
    return {'name': 'Quit', 'identifier': 'fr.leboxis.quit.source',
            'sourceURL': f'https://raw.githubusercontent.com/{repository}/catalog/source.json',
            'subtitle': 'Ton parcours, tes choix.', 'description': 'Source officielle de Quit pour SideStore et LiveContainer.',
            'iconURL': icon, 'website': f'https://github.com/{repository}', 'tintColor': '346451',
            'apps': [app], 'news': []}


def main():
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest='command', required=True)
    pack = sub.add_parser('pack')
    pack.add_argument('--app', required=True)
    pack.add_argument('--output', required=True)
    source = sub.add_parser('source')
    source.add_argument('--ipa', required=True)
    source.add_argument('--repository', required=True)
    source.add_argument('--tag', required=True)
    source.add_argument('--date', required=True)
    source.add_argument('--previous')
    source.add_argument('--output', required=True)
    args = parser.parse_args()
    if args.command == 'pack':
        info = package_app(args.app, args.output)
        print(f"Unsigned IPA verified: {info['CFBundleShortVersionString']} ({info['CFBundleVersion']})")
    else:
        previous = json.loads(Path(args.previous).read_text()) if args.previous and Path(args.previous).exists() else None
        result = make_source(args.ipa, args.repository, args.tag, args.date, previous)
        Path(args.output).write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
        sha = hashlib.sha256(Path(args.ipa).read_bytes()).hexdigest()
        Path(args.output).with_name('SHA256SUMS.txt').write_text(f'{sha}  Quit.ipa\n')
        print(f"Source generated: {result['apps'][0]['version']} / {result['apps'][0]['size']} bytes")


if __name__ == '__main__':
    main()
