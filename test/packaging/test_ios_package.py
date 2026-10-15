"""Check device/simulator discrimination and IPA layout without claiming an Xcode build."""
import importlib.util
from pathlib import Path
import plistlib
import struct
import tempfile
import unittest
import zipfile

source = Path(__file__).resolve().parents[2] / 'scripts/package_ios.py'
spec = importlib.util.spec_from_file_location('package_ios', source)
ios = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ios)


class IpaValidationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.bundle(self.root / 'Runner.app')
        self.widget = self.bundle(self.app / 'PlugIns/KuTodoWidgets.appex', extension=True)
        self.output = self.root / 'artifacts/test-only.ipa'

    def bundle(self, path, extension=False):
        path.mkdir(parents=True)
        info = {'CFBundleExecutable': 'Executable', 'CFBundleSupportedPlatforms': ['iPhoneOS'],
                'CFBundleShortVersionString': '0.2.0', 'CFBundleVersion': '6', 'MinimumOSVersion': '17.0'}
        if extension:
            info['NSExtension'] = {'NSExtensionPointIdentifier': 'com.apple.widgetkit-extension'}
        (path / 'Info.plist').write_bytes(plistlib.dumps(info))
        self.binary(path / 'Executable')
        return path

    def binary(self, path, platform=2, cpu=0x0100000c):
        # Minimal Mach-O test fixture: header + LC_BUILD_VERSION, not a runnable application.
        path.write_bytes(struct.pack('<8I', 0xfeedfacf, cpu, 0, 2, 1, 24, 0, 0) +
                         struct.pack('<6I', 0x32, 24, platform, 0x110000, 0x120000, 0))
        path.chmod(0o755)

    def test_payload_contains_device_app_and_widget(self):
        metadata = ios.package(self.app, self.output)
        with zipfile.ZipFile(self.output) as archive:
            self.assertIn('Payload/Runner.app/Executable', archive.namelist())
            self.assertIn('Payload/Runner.app/PlugIns/KuTodoWidgets.appex/Executable', archive.namelist())
        self.assertIn('UNSIGNED', metadata['signing'])
        self.assertTrue(self.output.with_suffix('.json').is_file())

    def test_rejects_arm64_simulator_even_with_device_plist(self):
        self.binary(self.app / 'Executable', platform=7)
        with self.assertRaisesRegex(ValueError, 'Not an iPhone device'):
            ios.package(self.app, self.output)
        self.assertFalse(self.output.exists())

    def test_rejects_simulator_plist(self):
        info = plistlib.loads((self.app / 'Info.plist').read_bytes())
        info['CFBundleSupportedPlatforms'] = ['iPhoneSimulator']
        (self.app / 'Info.plist').write_bytes(plistlib.dumps(info))
        with self.assertRaisesRegex(ValueError, 'simulator builds are rejected'):
            ios.package(self.app, self.output)

    def test_rejects_x86_64_and_non_executable_files(self):
        for content in [b'not a compiled app', struct.pack('<8I', 0xfeedfacf, 0x01000007, 0, 2, 0, 0, 0, 0)]:
            with self.subTest(content=content):
                (self.app / 'Executable').write_bytes(content)
                with self.assertRaises(ValueError):
                    ios.package(self.app, self.output)

    def test_rejects_missing_or_simulator_widget(self):
        self.binary(self.widget / 'Executable', platform=7)
        with self.assertRaises(ValueError):
            ios.package(self.app, self.output)
        self.widget.rename(self.app / 'PlugIns/KuTodoWidgets.disabled')
        with self.assertRaisesRegex(ValueError, 'WidgetKit extension is missing'):
            ios.package(self.app, self.output)

    def test_reads_arm64_device_slice_in_universal_binary(self):
        executable = self.app / 'Executable'
        thin = executable.read_bytes()
        executable.write_bytes(struct.pack('>II', 0xcafebabe, 1) +
                               struct.pack('>IIIII', 0x0100000c, 0, 32, len(thin), 0) + b'\0' * 4 + thin)
        ios.iphone_binary(executable)


if __name__ == '__main__':
    unittest.main()
