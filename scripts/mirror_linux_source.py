"""Keep Linux pub/CMake outputs separate from the Windows build configuration."""
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
target = root / "build/linux-workspace"
target.mkdir(parents=True, exist_ok=True)
for name in ["lib", "test", "assets", "linux", "scripts"]:
    shutil.copytree(root / name, target / name, dirs_exist_ok=True,
        ignore=shutil.ignore_patterns("ephemeral", ".plugin_symlinks", "__pycache__"))
for name in ["pubspec.yaml", "pubspec.lock", "analysis_options.yaml"]:
    shutil.copy2(root / name, target / name)
print(target)
