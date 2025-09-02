import os
import sys
import json
import requests
import shutil
import tempfile
from packaging import version
from PySide6.QtWidgets import QMessageBox, QApplication
from PySide6.QtCore import QThread, Signal, QObject

GITHUB_REPO = "990aa/kivixa"
API_URL = f"https://api.github.com/repos/{GITHUB_REPO}/releases"

class UpdateSignals(QObject):
    progress = Signal(int)
    status = Signal(str)
    finished = Signal(bool, str)

class GitHubUpdater(QThread):
    def __init__(self, current_version, channel="stable", offline=False, parent=None):
        super().__init__(parent)
        self.current_version = current_version
        self.channel = channel
        self.offline = offline
        self.signals = UpdateSignals()
        self.latest_release = None
        self.download_url = None
        self.temp_file = None
        self.backup_path = None
        self.error = None

    def run(self):
        try:
            if self.offline:
                self.signals.status.emit("Offline mode: update check skipped.")
                self.signals.finished.emit(False, "Offline mode")
                return
            self.signals.status.emit("Checking for updates...")
            releases = requests.get(API_URL, timeout=10).json()
            releases = [r for r in releases if not r.get("prerelease") or self.channel=="beta"]
            releases.sort(key=lambda r: version.parse(r["tag_name"].lstrip("v")), reverse=True)
            for rel in releases:
                rel_ver = rel["tag_name"].lstrip("v")
                if version.parse(rel_ver) > version.parse(self.current_version):
                    self.latest_release = rel
                    break
            if not self.latest_release:
                self.signals.status.emit("No updates available.")
                self.signals.finished.emit(True, "No update")
                return
            asset = next((a for a in self.latest_release["assets"] if a["name"].endswith(".exe")), None)
            if not asset:
                self.signals.status.emit("No installer found in release.")
                self.signals.finished.emit(False, "No installer")
                return
            self.download_url = asset["browser_download_url"]
            self.signals.status.emit(f"Downloading {asset['name']}...")
            self.temp_file = tempfile.mktemp(suffix=".exe")
            with requests.get(self.download_url, stream=True, timeout=30) as r:
                r.raise_for_status()
                total = int(r.headers.get('content-length', 0))
                with open(self.temp_file, 'wb') as f:
                    downloaded = 0
                    for chunk in r.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                            downloaded += len(chunk)
                            if total:
                                self.signals.progress.emit(int(downloaded*100/total))
            self.signals.status.emit("Download complete. Backing up current version...")
            exe_path = sys.argv[0]
            self.backup_path = exe_path + ".bak"
            shutil.copy2(exe_path, self.backup_path)
            self.signals.status.emit("Installing update...")
            shutil.copy2(self.temp_file, exe_path)
            self.signals.status.emit("Update installed. Restarting...")
            self.signals.finished.emit(True, "Update installed")
            QApplication.quit()
            os.execl(exe_path, exe_path, *sys.argv)
        except Exception as e:
            self.error = str(e)
            self.signals.status.emit(f"Update failed: {e}")
            # Rollback
            if self.backup_path and os.path.exists(self.backup_path):
                try:
                    shutil.copy2(self.backup_path, sys.argv[0])
                    self.signals.status.emit("Rolled back to previous version.")
                except Exception as re:
                    self.signals.status.emit(f"Rollback failed: {re}")
            self.signals.finished.emit(False, f"Update failed: {e}")

    @staticmethod
    def get_latest_version(channel="stable", offline=False):
        if offline:
            return None
        releases = requests.get(API_URL, timeout=10).json()
        releases = [r for r in releases if not r.get("prerelease") or channel=="beta"]
        releases.sort(key=lambda r: version.parse(r["tag_name"].lstrip("v")), reverse=True)
        if releases:
            return releases[0]["tag_name"].lstrip("v")
        return None
