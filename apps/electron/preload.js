const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  // Window controls
  minimizeWindow: () => ipcRenderer.send('minimize-window'),
  maximizeWindow: () => ipcRenderer.send('maximize-window'),
  closeWindow: () => ipcRenderer.send('close-window'),

  // Filesystem
  fsRead: (filePath) => ipcRenderer.invoke('fs-read', filePath),
  fsWrite: (filePath, content) => ipcRenderer.invoke('fs-write', filePath, content),
});