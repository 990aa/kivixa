@echo off
REM Build script for Kivixa Windows release
setlocal

REM Check for Python and PyInstaller
where python >nul 2>nul || (echo Python not found! & exit /b 1)
python -m pip show pyinstaller >nul 2>nul || (echo PyInstaller not installed! & exit /b 1)

REM Clean previous build
if exist dist rmdir /s /q dist
if exist build\__pycache__ rmdir /s /q build\__pycache__
if exist build\logs rmdir /s /q build\logs

REM Build with PyInstaller
python -m PyInstaller pyinstaller.spec --noconfirm
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo Build complete. Output in dist\Kivixa
endlocal
