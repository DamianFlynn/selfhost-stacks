#!/usr/bin/env python3
"""Run on LXC 100: inspect DVR playback, or --configure-library after mounting storage."""
import argparse
import json
from pathlib import Path
import shlex
import subprocess
import urllib.parse
import urllib.request


def command(*args):
    return subprocess.check_output(args, text=True, timeout=30).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--configure-library', action='store_true')
    parser.add_argument('--scan-recordings', action='store_true',
                        help='Refresh only the TV Recordings library')
    args = parser.parse_args()
    secret = Path('/mnt/fast/secrets/jellyfin-deercrest.env')
    assert secret.stat().st_uid == 0 and secret.stat().st_mode & 0o777 == 0o600
    token = None
    for line in secret.read_text().splitlines():
        parts = shlex.split(line, comments=True)
        for part in parts:
            if part.startswith('JELLYFIN_API_KEY='):
                token = part.split('=', 1)[1]
    assert token, 'Jellyfin credential missing'
    inspect = json.loads(command('docker', 'inspect', 'jellyfin'))[0]
    address = inspect['NetworkSettings']['Networks']['t3_proxy']['IPAddress']

    def api(path, body=None, method='GET'):
        request = urllib.request.Request(
            f'http://{address}:8096{path}',
            data=json.dumps(body).encode() if body is not None else None,
            headers={'Authorization': f'MediaBrowser Token="{token}"',
                     'Content-Type': 'application/json'}, method=method)
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read()
            return json.loads(data) if data else None

    sessions = api('/Sessions')
    active = [s for s in sessions if s.get('NowPlayingItem')]
    print('Jellyfin active playback sessions:', len(active))
    encoding = api('/System/Configuration/encoding')
    print('HardwareAccelerationType:', encoding.get('HardwareAccelerationType'))
    print('EnableHardwareEncoding:', encoding.get('EnableHardwareEncoding'))
    libraries = api('/Library/VirtualFolders')
    matches = [v for v in libraries if v['Name'] == 'TV Recordings']
    assert len(matches) <= 1, 'Duplicate TV Recordings libraries'
    if args.configure_library:
        mounts = inspect['Mounts']
        assert any(m['Destination'] == '/recordings' and
                   m['Source'] == '/mnt/tank/media/Recordings' and not m['RW']
                   for m in mounts), 'Jellyfin read-only recording mount missing'
        source = command('findmnt', '-n', '-o', 'SOURCE', '-T', '/mnt/tank/media/Recordings')
        assert all(s == 'tank/media/Recordings' for s in source.splitlines()), source
        if not matches:
            query = urllib.parse.urlencode({'name': 'TV Recordings',
                                            'collectionType': 'homevideos',
                                            'refreshLibrary': 'true'})
            api('/Library/VirtualFolders?' + query, {'LibraryOptions': {
                'PathInfos': [{'Path': '/recordings'}],
                'EnableRealtimeMonitor': True,
                'SaveLocalMetadata': False,
                'EnableInternetProviders': False,
                'EnableAutomaticSeriesGrouping': False,
            }}, 'POST')
            libraries = api('/Library/VirtualFolders')
            matches = [v for v in libraries if v['Name'] == 'TV Recordings']
        assert len(matches) == 1 and matches[0]['Locations'] == ['/recordings']
        assert matches[0]['CollectionType'] == 'homevideos'
        opts = matches[0]['LibraryOptions']
        assert not opts['SaveLocalMetadata'] and not opts['EnableInternetProviders']
        assert opts['EnableRealtimeMonitor']
        assert api('/System/Configuration/encoding') == encoding, 'Encoding settings changed'
    if args.scan_recordings:
        assert len(matches) == 1, 'TV Recordings library missing'
        query = urllib.parse.urlencode({'Recursive': 'true',
            'MetadataRefreshMode': 'Default', 'ImageRefreshMode': 'Default',
            'ReplaceAllMetadata': 'false', 'ReplaceAllImages': 'false'})
        api('/Items/' + matches[0]['ItemId'] + '/Refresh?' + query, method='POST')
    print('TV Recordings library:', json.dumps([
        {k: v.get(k) for k in ('Name', 'Locations', 'CollectionType', 'ItemId')}
        for v in matches]))
    print('Library scan tasks:', json.dumps([
        {k: t.get(k) for k in ('Name', 'State', 'CurrentProgressPercentage')}
        for t in api('/ScheduledTasks') if t.get('Key') == 'RefreshLibrary']))
    if matches:
        query = urllib.parse.urlencode({'ParentId': matches[0]['ItemId'],
            'Recursive': 'true', 'Fields': 'Path'})
        items = api('/Items?' + query)
        print('Recorded videos:', json.dumps([
            {k: item.get(k) for k in ('Id', 'Name', 'Type', 'Path', 'RunTimeTicks')}
            for item in items['Items'] if not item.get('IsFolder')]))


if __name__ == '__main__':
    main()
