// Window Controls
contextBridge.exposeInMainWorld('electron', {
    ...window.electron,
    windowControls: {
        minimize: () => ipcRenderer.send('window-minimize'),
        maximizeOrRestore: () => ipcRenderer.send('window-maximize-or-restore'),
        close: () => ipcRenderer.send('window-close')
    }
});
const { contextBridge, ipcRenderer } = require('electron');

const { app } = require('electron');
const appVersion = process.versions.electron ? require('electron').app.getVersion() : '1.0.0';

contextBridge.exposeInMainWorld('electron', {
    // Notes
    getNotes: (folder_id) => ipcRenderer.invoke('get-notes', folder_id),
    getNote: (id) => ipcRenderer.invoke('get-note', id),
    addNote: (note) => ipcRenderer.invoke('add-note', note),
    updateNote: (note) => ipcRenderer.invoke('update-note', note),
    updateNoteContent: (data) => ipcRenderer.invoke('update-note-content', data),
    deleteNote: (id) => ipcRenderer.invoke('delete-note', id),

    // Folders
    getFolders: () => ipcRenderer.invoke('get-folders'),
    addFolder: (folder) => ipcRenderer.invoke('add-folder', folder),
    deleteFolder: (id) => ipcRenderer.invoke('delete-folder', id),

    // Documentation
    getDocumentation: () => ipcRenderer.invoke('get-documentation'),

    // Load data from main process
    onLoadNotebook: (callback) => ipcRenderer.on('load-notebook', (event, data) => callback(data)),

    // Updater
    updater: {
        onUpdateStatus: (callback) => {
            ipcRenderer.on('update_status', (event, message) => callback(message));
        },
        restartApp: () => {
            ipcRenderer.send('restart_app');
        }
    },
    // About
    getAppVersion: () => appVersion
});