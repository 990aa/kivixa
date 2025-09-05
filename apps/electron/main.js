const { app, BrowserWindow, ipcMain, globalShortcut } = require('electron');
const path = require('path');
const fs = require('fs');

const isDev = process.env.NODE_ENV !== 'production';

function createWindow () {
  const mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    }
  });

  if (isDev) {
    mainWindow.loadURL('http://localhost:3000');
    mainWindow.webContents.openDevTools();
  } else {
    const indexPath = path.join(__dirname, '..', '..', 'web', 'out', 'index.html');
    mainWindow.loadFile(indexPath);
  }

  // IPC for window controls
  ipcMain.on('minimize-window', () => mainWindow.minimize());
  ipcMain.on('maximize-window', () => {
    if (mainWindow.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow.maximize();
    }
  });
  ipcMain.on('close-window', () => mainWindow.close());

  // IPC for filesystem
  ipcMain.handle('fs-read', (event, filePath) => {
    // Add security checks here for production
    return fs.readFileSync(filePath, 'utf-8');
  });
  ipcMain.handle('fs-write', (event, filePath, content) => {
    // Add security checks here for production
    return fs.writeFileSync(filePath, content);
  });
}

app.whenReady().then(() => {
  createWindow();

  // Register a low-level shortcut
  globalShortcut.register('CommandOrControl+X', () => {
    console.log('CommandOrControl+X is pressed');
  })

  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit();
});

app.on('will-quit', () => {
  // Unregister all shortcuts.
  globalShortcut.unregisterAll()
})