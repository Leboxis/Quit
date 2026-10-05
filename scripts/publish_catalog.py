#!/usr/bin/env python3
"""Publish a source with optimistic Contents API updates, no pushes to main."""
import base64
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import time
from distribution import make_source

repo = os.environ['GH_REPO']
commit = os.environ['GITHUB_SHA']
version = os.environ['QUIT_VERSION']
tag = f'v{version}'


def api(path, body=None, optional=False):
    command = ['gh', 'api', path]
    if body is not None:
        command += ['--method', 'PUT', '--input', '-']
    result = subprocess.run(command, input=json.dumps(body) if body is not None else None,
                            text=True, capture_output=True)
    if result.returncode:
        if optional and 'HTTP 404' in result.stderr:
            return None
        raise RuntimeError(f'GitHub API failed: {result.stderr.strip()}')
    return json.loads(result.stdout)


def main():
    for attempt in range(4):
        head = api(f'repos/{repo}/git/ref/heads/main')['object']['sha']
        if head != commit:
            print('Historical release published; main moved forward, so catalog remains unchanged.')
            return
        branch = api(f'repos/{repo}/git/ref/heads/catalog', optional=True)
        if branch is None:
            result = subprocess.run(['gh', 'api', f'repos/{repo}/git/refs', '--method', 'POST', '--input', '-'],
                                    input=json.dumps({'ref': 'refs/heads/catalog', 'sha': commit}), text=True, capture_output=True)
            if result.returncode and 'HTTP 422' not in result.stderr:
                raise RuntimeError(result.stderr)
        existing = api(f'repos/{repo}/contents/source.json?ref=catalog', optional=True)
        previous = json.loads(base64.b64decode(existing['content'])) if existing else None
        source = make_source(Path('build/Quit.ipa'), repo, tag, datetime.now(timezone.utc).date().isoformat(), previous)
        contents = json.dumps(source, ensure_ascii=False, indent=2) + '\n'
        body = {'message': f'chore: publish Quit {version} source', 'branch': 'catalog',
                'content': base64.b64encode(contents.encode()).decode()}
        if existing:
            body['sha'] = existing['sha']
        # Check again after fetching current catalog; concurrent writes reject stale blob SHAs.
        if api(f'repos/{repo}/git/ref/heads/main')['object']['sha'] != commit:
            print('Main advanced; skipped catalog mutation.')
            return
        try:
            api(f'repos/{repo}/contents/source.json', body)
        except RuntimeError as error:
            if attempt < 3 and ('HTTP 409' in str(error) or 'HTTP 422' in str(error)):
                time.sleep(2)
                continue
            raise
        Path('build/source.json').write_text(contents)
        subprocess.run(['gh', 'release', 'upload', tag, 'build/source.json', '--clobber'], check=True)
        subprocess.run(['gh', 'release', 'edit', tag, '--latest'], check=True)
        print(source['sourceURL'])
        return
    raise RuntimeError('Catalog publication failed after concurrent updates.')


if __name__ == '__main__':
    main()
