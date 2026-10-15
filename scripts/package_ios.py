"""Package a compiled iPhoneOS app for re-signing; never package a simulator as an IPA."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import stat
import struct
import subprocess
import sys
import tempfile
import zipfile


def iphone_binary(path):
    """Require an arm64 Mach-O built for iOS devices (arm64 alone also fits simulators)."""
    with path.open('rb') as binary:
        magic = binary.read(4)
        offset = 0
        if magic in (b'\xca\xfe\xba\xbe', b'\xca\xfe\xba\xbf'):
            count = struct.unpack('>I', binary.read(4))[0]
            if count > 32:
                raise ValueError('Invalid universal binary')
            for _ in range(count):
                record = binary.read(32 if magic[-1] == 0xbf else 20)
                cpu, _, location, *_ = struct.unpack('>IIQQII' if len(record) == 32 else '>IIIII', record)
                if cpu == 0x0100000c:
                    offset = location
                    break
            else:
                raise ValueError('No arm64 device binary')
        binary.seek(offset)
        header = binary.read(32)
        if len(header) != 32 or header[:4] != b'\xcf\xfa\xed\xfe':
            raise ValueError('Expected a compiled 64-bit Mach-O executable')
        _, cpu, _, _, count, size, _, _ = struct.unpack('<8I', header)
        if cpu != 0x0100000c or count > 4096 or size > 1024 * 1024:
            raise ValueError('Expected an arm64 executable with valid load commands')
        commands = binary.read(size)
        position = 0
        for _ in range(count):
            if position + 8 > len(commands):
                raise ValueError('Truncated Mach-O load commands')
            command, length = struct.unpack_from('<II', commands, position)
            if length < 8 or position + length > len(commands):
                raise ValueError('Invalid Mach-O load command')
            if command == 0x32 and length >= 24:  # LC_BUILD_VERSION
                platform = struct.unpack_from('<I', commands, position + 8)[0]
                if platform != 2:  # PLATFORM_IOS; simulator is 7, macOS is 1.
                    raise ValueError(f'Not an iPhone device binary (platform {platform})')
                return
            position += length
        raise ValueError('Device platform cannot be verified')


def validate_app(app):
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']:
        raise ValueError('Only an iPhoneOS build can become this IPA; simulator builds are rejected')
    executable = info.get('CFBundleExecutable', '')
    if not executable or Path(executable).name != executable:
        raise ValueError('Invalid executable name')
    iphone_binary(app / executable)
    return info


def prepare_for_sideload(app):
    """Retain App Group entitlements so AltStore can discover and re-sign them.

    Ad hoc signatures have no Apple identity/profile and do not enable installation.
    AltStore reads them to configure the real installer's provisioning profiles.
    """
    if sys.platform != 'darwin':
        raise ValueError('Entitlement preparation requires macOS codesign')
    info = validate_app(app)
    group = info.get('KuWidgetAppGroup', '')
    if not group.startswith('group.') or '$' in group:
        raise ValueError('Missing resolved App Group in the compiled Info.plist')
    widgets = list((app / 'PlugIns').glob('*.appex'))
    if not widgets:
        raise ValueError('Missing WidgetKit extension')
    for widget in widgets:
        if validate_app(widget).get('KuWidgetAppGroup') != group:
            raise ValueError('App and widget App Groups differ')
    with tempfile.TemporaryDirectory(prefix='ku-ipa-entitlements-') as directory:
        entitlements = Path(directory) / 'groups.plist'
        entitlements.write_bytes(plistlib.dumps({'com.apple.security.application-groups': [group]}))
        for framework in sorted(app.rglob('*.framework'), key=lambda path: len(path.parts), reverse=True):
            subprocess.run(['codesign', '--force', '--sign', '-', '--timestamp=none', str(framework)], check=True)
        for bundle in [*widgets, app]:
            subprocess.run(['codesign', '--force', '--sign', '-', '--timestamp=none',
                            '--generate-entitlement-der', '--entitlements', str(entitlements), str(bundle)], check=True)
            result = subprocess.run(['codesign', '--display', '--entitlements', ':-', str(bundle)],
                                    check=True, capture_output=True)
            if plistlib.loads(result.stdout).get('com.apple.security.application-groups') != [group]:
                raise ValueError('App Group entitlement was not preserved')


def package(app, output):
    info = validate_app(app)
    widgets = list((app / 'PlugIns').glob('*.appex'))
    if not widgets:
        raise ValueError('The requested WidgetKit extension is missing')
    for widget in widgets:
        extension = validate_app(widget)
        if extension.get('NSExtension', {}).get('NSExtensionPointIdentifier') != 'com.apple.widgetkit-extension':
            raise ValueError('Unexpected app extension')
        if extension.get('CFBundleVersion') != info.get('CFBundleVersion'):
            raise ValueError('App and widget build versions differ')
    output.parent.mkdir(parents=True, exist_ok=True)
    pending = output.with_suffix('.ipa.partial')
    try:
        with zipfile.ZipFile(pending, 'w', zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(app.rglob('*')):
                if path.is_symlink():
                    raise ValueError('Unexpected symlink in iOS bundle')
                if path.is_file():
                    archive.write(path, Path('Payload') / app.name / path.relative_to(app))
        with zipfile.ZipFile(pending) as archive:
            if archive.testzip() is not None:
                raise ValueError('IPA archive integrity failed')
            executable = archive.getinfo(f'Payload/{app.name}/{info["CFBundleExecutable"]}')
            if not stat.S_IMODE(executable.external_attr >> 16) & 0o111:
                raise ValueError('The built executable lost its execute permission')
        pending.replace(output)
    finally:
        pending.unlink(missing_ok=True)
    metadata = {'file': output.name, 'bytes': output.stat().st_size,
                'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
                'version': info.get('CFBundleShortVersionString'), 'build': info.get('CFBundleVersion'),
                'platform': 'iPhoneOS arm64', 'minimum_ios': info.get('MinimumOSVersion'),
                'signing': 'UNSIGNED for installation: ad hoc entitlement metadata only; AltStore must re-sign',
                'widget_extensions': [widget.name for widget in widgets]}
    output.with_suffix('.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
    return metadata


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--app', type=Path, default=Path('build/ios/iphoneos/Runner.app'))
    parser.add_argument('--output', type=Path, default=Path('build/downloads/KU-Todo-0.2.0-ios-arm64-unsigned.ipa'))
    parser.add_argument('--prepare-sideload', action='store_true', help='Preserve App Group metadata using macOS ad hoc codesign')
    args = parser.parse_args()
    if args.prepare_sideload:
        prepare_for_sideload(args.app)
    print(json.dumps(package(args.app, args.output), indent=2))
