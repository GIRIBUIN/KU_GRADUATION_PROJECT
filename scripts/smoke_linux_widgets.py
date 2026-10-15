"""Launch real release binaries in an isolated Xvfb desktop; never touch the user's task DB."""
from datetime import datetime
import os
from pathlib import Path
import sqlite3
import subprocess
import tempfile
import time
import atexit

import gi
gi.require_version("Gdk", "3.0")
from gi.repository import Gdk
Gdk.init([])

root = Path(__file__).resolve().parents[1]
binary = root / "build/linux/x64/release/bundle/ku_task_management"
previews = root / "build/widget-previews"
previews.mkdir(parents=True, exist_ok=True)
home = Path(tempfile.mkdtemp(prefix="ku-widget-smoke-"))
(home / "Documents").mkdir()
(home / ".config").mkdir()
(home / ".config/user-dirs.dirs").write_text(f'XDG_DOCUMENTS_DIR="{home}/Documents"\n')
environment = {**os.environ, "HOME": str(home), "XDG_CONFIG_HOME": str(home / ".config"),
               "XDG_DATA_HOME": str(home / ".local/share"), "GDK_BACKEND": "x11", "LIBGL_ALWAYS_SOFTWARE": "1"}
desktop_log = (previews / "virtual-desktop.log").open("w")
desktop = [subprocess.Popen(["openbox", "--sm-disable"], env=environment, stdout=desktop_log, stderr=desktop_log),
           subprocess.Popen(["xcompmgr", "-c"], env=environment, stdout=desktop_log, stderr=desktop_log)]
def stop_desktop():
    for process in reversed(desktop):
        if process.poll() is None: process.terminate()
atexit.register(stop_desktop)
time.sleep(1)
for kind in ["today", "week", "calendar"]:
    log_path = previews / f"linux-{kind}.log"
    with log_path.open("w") as log:
        process = subprocess.Popen([str(binary), f"--widget={kind}"], env=environment, stdout=log, stderr=log)
        try:
            time.sleep(4)
            if process.poll() is not None:
                raise RuntimeError(f"{kind} exited: {log_path.read_text()[-2000:]}")
            if kind == "today":
                databases = list(home.rglob("ku_task_management.sqlite"))
                for _ in range(20):
                    if databases: break
                    time.sleep(.5)
                    databases = list(home.rglob("ku_task_management.sqlite"))
                if len(databases) != 1:
                    pixels = Gdk.pixbuf_get_from_window(Gdk.get_default_root_window(), 0, 0, 800, 700)
                    pixels.savev(str(previews / "linux-startup-failure.png"), "png", [], [])
                    raise RuntimeError(f"Expected one isolated DB, found {databases}")
                now = datetime.now()
                with sqlite3.connect(databases[0]) as database:
                    if database.execute("PRAGMA user_version").fetchone()[0] != 5:
                        raise RuntimeError("Wrong schema version")
                    for index, title in enumerate(["프로젝트 미팅", "자료 정리", "과제 확인"]):
                        database.execute("INSERT INTO tasks(id,origin,status,title,due_date,created_at,updated_at,sort_order) VALUES(?, 'personal','active',?,?,?,?,?)",
                            [f"preview-{index}", title, int(now.replace(hour=23, minute=59).timestamp()), int(now.timestamp()), int(now.timestamp()), index])
                time.sleep(4)  # Cross-process SQL changes appear through the widget's polling refresh.
            window = Gdk.get_default_root_window()
            # AOT startup and software rendering can lag behind SQLite on a busy build host.
            for _ in range(60):
                if process.poll() is not None:
                    raise RuntimeError(f"{kind} exited before rendering")
                pixels = Gdk.pixbuf_get_from_window(window, 0, 0, 800, 700)
                if pixels is None:
                    raise RuntimeError("No rendered desktop")
                raw = pixels.get_pixels()
                colours = {raw[index:index+3] for index in range(0, len(raw), 33)}
                if len(colours) >= 10: break
                time.sleep(.5)
            pixels.savev(str(previews / f"linux-{kind}.png"), "png", [], [])
            if len(colours) < 10:
                tree = subprocess.run(["xwininfo", "-root", "-tree"], capture_output=True, text=True)
                (previews / f"linux-{kind}-windows.txt").write_text(tree.stdout)
                raise RuntimeError("The release window did not render")
            if kind == "today":
                def xdo(*arguments):
                    return subprocess.run(["xdotool", *map(str, arguments)], check=True, capture_output=True, text=True).stdout
                window_id = xdo("search", "--onlyvisible", "--pid", process.pid).splitlines()[0]
                xdo("windowmove", window_id, 600, 400)
                xdo("mousemove", "--window", window_id, 60, 25, "click", 1)
                time.sleep(1)
                geometry = dict(line.split("=", 1) for line in xdo("getwindowgeometry", "--shell", window_id).splitlines())
                x, y, width, height = (int(geometry[key]) for key in ["X", "Y", "WIDTH", "HEIGHT"])
                if x < 0 or y < 0 or x + width > window.get_width() or y + height > window.get_height():
                    raise RuntimeError("Expanded widget escaped the display work area")
                xdo("mousemove", "--window", window_id, 100, 76, "click", 1)
                time.sleep(.3)
                xdo("type", "--clearmodifiers", "--delay", 0, "Native widget saved")
                time.sleep(.3)
                form = Gdk.pixbuf_get_from_window(window, 0, 0, window.get_width(), window.get_height())
                form.savev(str(previews / "linux-expanded-add.png"), "png", [], [])
                raw, stride, channels = form.get_pixels(), form.get_rowstride(), form.get_n_channels()
                def blue(px, py):
                    offset = py * stride + px * channels
                    r, g, b = raw[offset:offset+3]
                    return b > r + 20 and b > g + 10 and r < 170
                rows = [row for row in range(y + height - 5, y + 80, -1)
                        if all(blue(x + width // 2 + delta, row) for delta in [-100, -50, 0, 50, 100])]
                if not rows: raise RuntimeError('Save button was not rendered inside the expanded widget')
                save_y = (max(rows) + min(rows)) // 2
                xdo("mousemove", "--window", window_id, width // 2, save_y - y, "click", 1)
                for _ in range(20):
                    with sqlite3.connect(databases[0]) as database:
                        saved = database.execute("SELECT COUNT(*) FROM tasks WHERE title='Native widget saved'").fetchone()[0]
                    if saved == 1: break
                    time.sleep(.5)
                if saved != 1: raise RuntimeError("Native widget add/save did not update the shared database")
                print("today: native header click, work-area bounds, input and save OK", flush=True)
        finally:
            process.terminate()
            try: process.wait(timeout=5)
            except subprocess.TimeoutExpired: process.kill(); process.wait()
    errors = log_path.read_text()
    if any(marker in errors for marker in ["Unhandled Exception", "MissingPluginException", "RenderFlex overflowed"]):
        raise RuntimeError(errors[-2500:])
    print(f"{kind}: release startup, rendering and shared database OK", flush=True)
