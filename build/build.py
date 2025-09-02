import os, shutil, subprocess, sys, logging, datetime

APP_NAME = "Kivixa"
VERSION_FILE = "../build/version.txt"
DIST_DIR = "dist"
BUILD_DIR = "build"
LOG_FILE = "build/build.log"
PYINSTALLER_SPEC = "../pyinstaller.spec"
INNO_SETUP_SCRIPT = "installer.iss"

logging.basicConfig(filename=LOG_FILE, level=logging.INFO, format="%(asctime)s %(levelname)s: %(message)s")

def log(msg): print(msg); logging.info(msg)

def clean():
    log("Cleaning build and dist directories...")
    for d in [DIST_DIR, "build/temp"]:
        if os.path.exists(d): shutil.rmtree(d)
    os.makedirs(DIST_DIR, exist_ok=True)

def update_version(new_version):
    log(f"Updating version to {new_version}...")
    with open(VERSION_FILE, "w") as f: f.write(new_version)
    # Optionally update version in other files (installer.iss, etc.)

def run_tests():
    log("Running automated tests...")
    result = subprocess.run([sys.executable, "-m", "pytest", "../tests"], capture_output=True, text=True)
    log(result.stdout)
    if result.returncode != 0:
        log("Tests failed! Aborting build.")
        sys.exit(1)

def build_pyinstaller(config="release"):
    log(f"Building with PyInstaller ({config})...")
    cmd = [sys.executable, "-m", "PyInstaller", PYINSTALLER_SPEC]
    if config == "debug": cmd.append("--debug")
    result = subprocess.run(cmd, capture_output=True, text=True)
    log(result.stdout)
    if result.returncode != 0:
        log("PyInstaller build failed!")
        sys.exit(1)

def sign_executable():
    log("Preparing for code signing (placeholder)...")

def build_installer():
    log("Building installer with Inno Setup...")
    result = subprocess.run([
        r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        INNO_SETUP_SCRIPT
    ], capture_output=True, text=True, cwd=BUILD_DIR)
    log(result.stdout)
    if result.returncode != 0:
        log("Inno Setup build failed!")
        sys.exit(1)

def organize_artifacts():
    log("Organizing build artifacts...")
    # Move installer, logs, etc. to dist/
    for f in os.listdir(BUILD_DIR):
        if f.endswith(".exe") or f.endswith(".log"):
            shutil.move(os.path.join(BUILD_DIR, f), DIST_DIR)

def main():
    try:
        clean()
        new_version = datetime.datetime.now().strftime("2.0.%Y%m%d")
        update_version(new_version)
        run_tests()
        for config in ["release", "debug"]:
            build_pyinstaller(config)
        sign_executable()
        build_installer()
        organize_artifacts()
        log("Build completed successfully.")
    except Exception as e:
        log(f"Build failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
