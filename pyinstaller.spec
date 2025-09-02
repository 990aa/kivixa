# -*- mode: python ; coding: utf-8 -*-
import sys
from PyInstaller.utils.hooks import collect_data_files

datas = collect_data_files('resources', includes=['*.qss', '*.ico', '*.png', '*.svg'])
datas += collect_data_files('resources/icons', includes=['*.svg'])
datas += collect_data_files('resources', includes=['*.ttf', '*.otf'])

a = Analysis(
    ['src/main.py'],
    pathex=['.'],
    binaries=[],
    datas=datas,
    hiddenimports=[
        'PySide6.QtCore',
        'PySide6.QtGui',
        'PySide6.QtWidgets',
        'PySide6.QtPrintSupport',
        'PySide6.QtSvg',
        'PySide6.QtNetwork',
        'widgets.card_view',
        'widgets.note_card',
        'widgets.canvas',
        'widgets.move_dialog',
        'widgets.help_dialog',
        'widgets.update_dialogs',
        'widgets.update_settings_dialog',
        'models.data_models',
        'utils.project_manager',
        'utils.logging_utils',
    ],
    hookspath=[],
    runtime_hooks=[],
    excludes=['tkinter', 'unittest', 'test', 'pydoc', 'doctest', 'email', 'http', 'xml', 'xmlrpc', 'sqlite3', 'asyncio', 'concurrent', 'distutils', 'html', 'http', 'lib2to3', 'multiprocessing', 'pdb', 'unittest', 'wsgiref', 'xml', 'xmlrpc'],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=None,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Kivixa',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,  # Suppress console window
    icon='build/icon.ico',
    version='build/version.txt',
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Kivixa',
)
