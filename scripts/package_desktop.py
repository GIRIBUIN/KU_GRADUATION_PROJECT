"""Package a verified Flutter release bundle, including its DLLs/assets and widget launchers."""
import argparse
import glob
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import time
import tempfile
import zipfile
import plistlib

parser = argparse.ArgumentParser()
parser.add_argument("platform", choices=["windows", "linux", "macos"])
parser.add_argument("--version", default="0.2.0")
parser.add_argument("--output", type=Path)
arguments = parser.parse_args()
root = Path(__file__).resolve().parents[1]
output = arguments.output or root / "build" / "downloads"
output.mkdir(parents=True, exist_ok=True)
stage = root / "build" / "packages" / f"{arguments.platform}-{time.time_ns()}"
stage.mkdir(parents=True, exist_ok=False)
name = f"KU-Todo-{arguments.version}-{arguments.platform}-x64"

if arguments.platform == "macos":
    apps = list((root / "build/macos/Build/Products/Release").glob("*.app"))
    if len(apps) != 1:
        raise SystemExit("Expected one built .app")
    with (apps[0] / 'Contents/Info.plist').open('rb') as info:
        executable_name = plistlib.load(info)['CFBundleExecutable']
    architectures = subprocess.check_output(['lipo', '-archs', str(apps[0] / 'Contents/MacOS' / executable_name)], text=True).split()
    architecture = 'universal' if {'arm64', 'x86_64'}.issubset(architectures) else ('arm64' if 'arm64' in architectures else 'x64')
    name = f'KU-Todo-{arguments.version}-macos-{architecture}'
    subprocess.run(["ditto", str(apps[0]), str(stage / apps[0].name)], check=True)
    os.symlink("/Applications", stage / "Applications")
    subprocess.run(["hdiutil", "create", "-volname", "KU Todo", "-srcfolder", str(stage),
                    "-format", "UDZO", str(output / f"{name}.dmg")], check=True)
    print(output / f"{name}.dmg")
    raise SystemExit(0)

source = root / ("build/windows/x64/runner/Release" if arguments.platform == "windows" else "build/linux/x64/release/bundle")
executable = "ku_task_management.exe" if arguments.platform == "windows" else "ku_task_management"
if not (source / executable).is_file():
    raise SystemExit(f"Build the release app first: {source / executable}")
bundle = stage / name
shutil.copytree(source, bundle)

readme = """KU Todo 0.2.0 — 일정 위젯 테스트 버전

Windows: ZIP 전체를 압축 해제하고 ku_task_management.exe를 실행하세요.
Linux: 압축 해제 후 ./ku_task_management를 실행하거나 .deb 파일을 설치하세요.
오늘/이번 주/캘린더 위젯 실행 파일로 독립 위젯을 띄울 수 있습니다.
앱 오른쪽 위 위젯 메뉴에서도 각각 열 수 있습니다.

기본 위젯은 일정만 표시합니다. 누르면 추가·편집 패널로 확대됩니다.
패널 바깥의 다른 창/바탕화면을 누르면 원래 크기로 돌아갑니다.
작성 중인 내용이 있으면 패널을 유지하며 닫기에서 버리기를 확인합니다.
창의 모서리로 크기 조절, 목록/제목 드래그로 이동, 더 보기 → 필터·설정에서 테마를 바꿉니다.
창을 완전히 종료하려면 더 보기 → 위젯 종료를 사용하세요.

이 버전의 Windows/Linux 위젯은 독립 바탕화면 창입니다.
Windows 위젯 보드 / GNOME 확장 / KDE Plasmoid에 등록되는 형식은 아닙니다.
PC/휴대폰 사이의 클라우드 데이터 동기화 기능은 없습니다.
Linux 예약 알림과 Linux e-campus WebView 로그인은 지원하지 않습니다.
Linux는 glibc 2.35 이상과 GTK3 런타임이 필요하며, 한국어가 네모로 보이면 Noto CJK 글꼴을 설치하세요.
"""
(bundle / "사용 방법.txt").write_text(readme, encoding="utf-8")

for kind, label in [("today", "오늘 위젯"), ("week", "이번 주 위젯"), ("calendar", "캘린더 위젯")]:
    if arguments.platform == "windows":
        (bundle / f"{label}.cmd").write_bytes(f'@echo off\r\nstart "" "%~dp0{executable}" --widget={kind}\r\n'.encode("utf-8"))
    else:
        launcher = bundle / f"widget-{kind}.sh"
        launcher.write_text(f'#!/bin/sh\ncd "$(dirname "$0")"\nexec ./{executable} --widget={kind}\n', encoding="utf-8")
        launcher.chmod(0o755)

if arguments.platform == "windows":
    # App-local Visual C++ runtime avoids requiring developer tools on the test PC.
    candidates = sorted(glob.glob("C:/Program Files/Microsoft Visual Studio/2022/*/VC/Redist/MSVC/*/x64/Microsoft.VC143.CRT"))
    if candidates:
        for library in Path(candidates[-1]).glob("*.dll"):
            shutil.copy2(library, bundle / library.name)
    archive = output / f"{name}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as target:
        for path in bundle.rglob("*"):
            if path.is_file():
                target.write(path, path.relative_to(stage))
    print(archive)
else:
    (bundle / executable).chmod(0o755)
    archive = output / f"{name}.tar.gz"
    def normalize_permissions(info):
        info.uid = info.gid = 0
        info.uname = info.gname = "root"
        info.mode = 0o755 if info.isdir() or Path(info.name).name == executable or info.name.endswith('.sh') or '.so' in Path(info.name).suffixes else 0o644
        return info
    with tarfile.open(archive, "w:gz") as target:
        target.add(bundle, arcname=name, filter=normalize_permissions)
    print(archive)
    # NTFS mounts don't preserve Unix modes; build the Debian control tree on a native filesystem.
    deb = Path(tempfile.mkdtemp(prefix="ku-todo-deb-"))
    deb.chmod(0o755)
    (deb / "DEBIAN").mkdir(parents=True)
    shutil.copytree(bundle, deb / "usr/lib/ku-todo")
    (deb / "usr/bin").mkdir(parents=True)
    command = deb / "usr/bin/ku-todo"
    command.write_text('#!/bin/sh\nexec /usr/lib/ku-todo/ku_task_management "$@"\n')
    command.chmod(0o755)
    applications = deb / "usr/share/applications"
    applications.mkdir(parents=True)
    for kind, label in [(None, "KU Todo"), ("today", "KU Todo 오늘 위젯"), ("week", "KU Todo 이번 주 위젯"), ("calendar", "KU Todo 캘린더 위젯")]:
        (applications / f"ku-todo-{kind or 'app'}.desktop").write_text(
            f"[Desktop Entry]\nType=Application\nName={label}\nExec=ku-todo{' --widget=' + kind if kind else ''}\nIcon=view-calendar\nTerminal=false\nCategories=Office;Calendar;\n", encoding="utf-8")
    (deb / "DEBIAN/control").write_text(
        f"Package: ku-todo\nVersion: {arguments.version}\nArchitecture: amd64\nMaintainer: KU Todo Team\n"
        "Depends: libc6 (>= 2.35), libgtk-3-0, libstdc++6, libglib2.0-0\nRecommends: fonts-noto-cjk\n"
        "Description: KU Todo desktop task and calendar widgets\n", encoding="utf-8")
    for path in deb.rglob('*'):
        path.chmod(0o755 if path.is_dir() or path.name in (executable, 'ku-todo') or path.suffix == '.sh' or '.so' in path.suffixes else 0o644)
    subprocess.run(["dpkg-deb", "--build", "--root-owner-group", str(deb), str(output / f"{name}.deb")], check=True)
    print(output / f"{name}.deb")
