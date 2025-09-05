// Window Controls IPC
ipcMain.on('window-minimize', () => {
    if (mainWindow) mainWindow.minimize();
});
ipcMain.on('window-maximize-or-restore', () => {
    if (mainWindow) {
        if (mainWindow.isMaximized()) {
            mainWindow.unmaximize();
        } else {
            mainWindow.maximize();
        }
    }
});
ipcMain.on('window-close', () => {
    if (mainWindow) mainWindow.close();
});
const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const log = require('electron-log');
const fs = require('fs');

// Configure electron-log
log.transports.file.level = 'info';
log.transports.file.resolvePath = () => require('path').join(app.getPath('userData'), 'logs/main.log');

// Additional log file for developer analysis (project root)
const devLogPath = require('path').join(__dirname, 'error.log');
const userLogPath = require('path').join(__dirname, 'user-errors.log');

function logToFile(filePath, message) {
    try {
        fs.appendFileSync(filePath, `[${new Date().toISOString()}] ${message}\n`);
        // If this is an error log, also copy the latest error logs from userData to project directory
        if (filePath === devLogPath || filePath === userLogPath) {
            const userDataLogDir = require('path').join(app.getPath('userData'), 'logs');
            const projectLogDir = __dirname;
            // Copy all .log files from userData/logs to project dir with a prefix
            fs.readdir(userDataLogDir, (err, files) => {
                if (!err && files) {
                    files.filter(f => f.endsWith('.log')).forEach(f => {
                        const src = require('path').join(userDataLogDir, f);
                        const dest = require('path').join(projectLogDir, 'userData_' + f);
                        fs.copyFile(src, dest, () => {});
                    });
                }
            });
        }
    } catch (e) {
        // If logging fails, ignore to avoid recursive errors
    }
}

// Global error/crash handling
process.on('uncaughtException', (error) => {
    const errorMsg = 'Uncaught Exception: ' + (error && error.stack ? error.stack : error);
    log.error(errorMsg);
    logToFile(devLogPath, errorMsg);
    logToFile(userLogPath, errorMsg);
    dialog.showErrorBox('A critical error occurred',
        'An unexpected error has occurred and has been logged. Please report this at https://github.com/990aa/kivixa/issues.\n\n' + (error && error.stack ? error.stack : error));
    app.exit(1);
});
process.on('unhandledRejection', (reason) => {
    const errorMsg = 'Unhandled Rejection: ' + (reason && reason.stack ? reason.stack : reason);
    log.error(errorMsg);
    logToFile(devLogPath, errorMsg);
    logToFile(userLogPath, errorMsg);
    dialog.showErrorBox('A critical error occurred',
        'An unexpected error has occurred and has been logged. Please report this at https://github.com/990aa/kivixa/issues.\n\n' + (reason && reason.stack ? reason.stack : reason));
    app.exit(1);
});
const { autoUpdater } = require('electron-updater');
const path = require('path');
const db = require('./database/database.js');

let mainWindow;
let splashWindow;
function createWindow() {
    try {
        splashWindow = new BrowserWindow({
            width: 400,
            height: 300,
            frame: false,
            alwaysOnTop: true,
            transparent: true,
            resizable: false,
            show: true,
            icon: path.join(__dirname, 'build/icon.ico'),
            webPreferences: {
                nodeIntegration: false,
                contextIsolation: true
            }
        });
        splashWindow.loadFile(path.join(__dirname, 'renderer/splash.html')).catch(err => {
            log.error('Splash load error:', err);
        });

        mainWindow = new BrowserWindow({
            width: 1200,
            height: 800,
            icon: path.join(__dirname, 'build/icon.ico'),
            webPreferences: {
                preload: path.join(__dirname, 'preload.js'),
                contextIsolation: true,
                enableRemoteModule: false,
                nodeIntegration: false
            },
            frame: false,
            titleBarStyle: 'hidden',
            backgroundColor: '#121212',
            show: false
        });
        mainWindow.once('ready-to-show', () => {
            setTimeout(() => {
                splashWindow.close();
                mainWindow.show();
            }, 1200); // Show splash for at least 1.2s
        });
        mainWindow.loadFile('renderer/index.html').catch(err => {
            log.error('Main window load error:', err);
            dialog.showErrorBox('Error loading main window', 'An error occurred while loading the main window. Please report this at https://github.com/990aa/kivixa/issues.\n\n' + (err && err.stack ? err.stack : err));
        });
    } catch (err) {
        log.error('Error in createWindow:', err);
        dialog.showErrorBox('Critical Error', 'A critical error occurred while starting the app. Please report this at https://github.com/990aa/kivixa/issues.\n\n' + (err && err.stack ? err.stack : err));
        app.exit(1);
    }
}


app.whenReady().then(() => {
    log.info('App starting...');
    createWindow();

    // Auto-update logic
    autoUpdater.checkForUpdatesAndNotify();

    autoUpdater.on('checking-for-update', () => {
        log.info('Checking for updates...');
        mainWindow.webContents.send('update_status', 'Checking for updates...');
    });
    autoUpdater.on('update-available', () => {
        log.info('Update available. Downloading...');
        mainWindow.webContents.send('update_status', 'Update available. Downloading...');
    });
    autoUpdater.on('update-not-available', () => {
        log.info('No update available.');
        mainWindow.webContents.send('update_status', 'No update available.');
    });
    autoUpdater.on('download-progress', (info) => {
        log.info(`Downloading update: ${info.percent.toFixed(2)}%`);
        mainWindow.webContents.send('update_status', 'Downloading update: ' + info.percent.toFixed(2) + '%');
    });
    autoUpdater.on('update-downloaded', () => {
        log.info('Update downloaded. Ready to install.');
        mainWindow.webContents.send('update_status', 'Update downloaded. Restart to install.');
    });
    autoUpdater.on('error', (err) => {
        log.error('Error during update:', err);
        let msg = 'Error during update: ' + (err && err.message ? err.message : err);
        if (err && err.message) {
            if (err.message.includes('net::ERR_INTERNET_DISCONNECTED')) {
                msg = 'Network error: Please check your internet connection.';
            } else if (err.message.includes('ENOTFOUND')) {
                msg = 'Network error: Update server not found.';
            } else if (err.message.includes('EACCES')) {
                msg = 'File system error: Permission denied.';
            } else if (err.message.includes('EIO')) {
                msg = 'File system error: I/O error occurred.';
            } else if (err.message.includes('No published versions on GitHub') || err.message.includes('Cannot parse releases feed') || err.message.includes('Unable to find latest version on GitHub')) {
                msg = 'Auto-update error: No valid release or latest.yml found on GitHub. Please ensure a production release exists with all required files (including latest.yml). See https://www.electron.build/auto-update for help.';
            } else if (err.message.includes('Cannot find latest.yml')) {
                msg = 'Auto-update error: latest.yml is missing from the latest GitHub release. Please publish using electron-builder and upload all artifacts.';
            }
        }
        mainWindow.webContents.send('update_status', msg + ' Please report at https://github.com/990aa/kivixa/issues');
        // Optionally show a dialog for critical update errors
        if (msg.startsWith('Auto-update error:')) {
            dialog.showErrorBox('Auto-update Error', msg);
        }
    });

    ipcMain.on('restart_app', () => {
        log.info('Restarting app to install update...');
        autoUpdater.quitAndInstall();
    });

    app.on('activate', function () {
        if (BrowserWindow.getAllWindows().length === 0) createWindow();
    });
});

app.on('window-all-closed', function () {
    log.info('All windows closed.');
    if (process.platform !== 'darwin') {
        db.close();
        log.info('Database closed. Quitting app.');
        app.quit();
    }
});

// Folders IPC
ipcMain.handle('get-folders', async () => {
  return new Promise((resolve, reject) => {
    db.all('SELECT * FROM folders ORDER BY name', [], (err, rows) => {
      if (err) {
    log.error('Database error (get-folders):', err);
    reject(err);
      }
      resolve(rows);
    });
  });
});

ipcMain.handle('add-folder', async (event, { name, parent_id }) => {
  return new Promise((resolve, reject) => {
    db.run('INSERT INTO folders (name, parent_id) VALUES (?, ?)', [name, parent_id], function (err) {
      if (err) {
    log.error('Database error (add-folder):', err);
    reject(err);
      }
      resolve({ id: this.lastID, name, parent_id });
    });
  });
});

ipcMain.handle('delete-folder', async (event, id) => {
    return new Promise((resolve, reject) => {
        db.run('DELETE FROM folders WHERE id = ?', [id], function(err) {
            if (err) {
                log.error('Database error (delete-folder):', err);
                reject(err);
            }
            resolve({ id });
        });
    });
});

ipcMain.handle('get-folder', async (event, id) => {
    return new Promise((resolve, reject) => {
        db.get('SELECT * FROM folders WHERE id = ?', [id], (err, row) => {
            if (err) {
                log.error('Database error (get-folder):', err);
                reject(err);
            }
            resolve(row);
        });
    });
});


// Notes IPC
ipcMain.handle('get-notes', async (event, folder_id) => {
  return new Promise((resolve, reject) => {
    let query = 'SELECT id, title, SUBSTR(content, 1, 50) as preview FROM notes';
    let params = [];
    if (folder_id) {
        query += ' WHERE folder_id = ?';
        params.push(folder_id);
    } else {
        query += ' WHERE folder_id IS NULL';
    }
    query += ' ORDER BY updated_at DESC';

    db.all(query, params, (err, rows) => {
      if (err) {
    log.error('Database error (get-notes):', err);
    reject(err);
      }
      resolve(rows);
    });
  });
});

ipcMain.handle('get-recent-notes', async () => {
    return new Promise((resolve, reject) => {
        db.all('SELECT id, title, SUBSTR(content, 1, 50) as preview FROM notes ORDER BY updated_at DESC LIMIT 10', [], (err, rows) => {
            if (err) {
                log.error('Database error (get-recent-notes):', err);
                reject(err);
            }
            resolve(rows);
        });
    });
});

ipcMain.handle('add-note', async (event, { title, content, folder_id }) => {
  return new Promise((resolve, reject) => {
    const now = new Date().toISOString();
    db.run('INSERT INTO notes (title, content, folder_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?)', [title, content, folder_id, now, now], function (err) {
      if (err) {
    log.error('Database error (add-note):', err);
    reject(err);
      }
      resolve({ id: this.lastID, title, content, folder_id });
    });
  });
});

ipcMain.handle('get-note', async (event, id) => {
    return new Promise((resolve, reject) => {
        db.get('SELECT * FROM notes WHERE id = ?', [id], (err, row) => {
            if (err) {
                log.error('Database error (get-note):', err);
                reject(err);
            }
            resolve(row);
        });
    });
});

ipcMain.handle('update-note', async (event, { id, title, content, folder_id }) => {
    return new Promise((resolve, reject) => {
        const now = new Date().toISOString();
        let query = 'UPDATE notes SET updated_at = ?';
        const params = [now];

        if (title !== undefined) {
            query += ', title = ?';
            params.push(title);
        }

        if (content !== undefined) {
            query += ', content = ?';
            params.push(content);
        }

        if (folder_id !== undefined) {
            query += ', folder_id = ?';
            params.push(folder_id);
        }

        query += ' WHERE id = ?';
        params.push(id);

        db.run(query, params, function(err) {
            if (err) {
                log.error('Database error (update-note):', err);
                reject(err);
            }
            resolve({ id });
        });
    });
});

ipcMain.handle('delete-note', async (event, id) => {
    return new Promise((resolve, reject) => {
        db.run('DELETE FROM notes WHERE id = ?', [id], function(err) {
            if (err) {
                log.error('Database error (delete-note):', err);
                reject(err);
            }
            resolve({ id });
        });
    });
});

ipcMain.handle('update-note-content', async (event, { id, content }) => {
    return new Promise((resolve, reject) => {
        const now = new Date().toISOString();
        db.run('UPDATE notes SET content = ?, updated_at = ? WHERE id = ?', [content, now, id], function(err) {
            if (err) {
                log.error('Database error (update-note-content):', err);
                reject(err);
            }
            resolve({ id });
        });
    });
});


const fs = require('fs');

// Search IPC

// Search IPC
ipcMain.handle('search-all', async (event, query) => {
    return new Promise((resolve, reject) => {
        const searchQuery = `%${query}%`;
        db.all('SELECT id, title, SUBSTR(content, 1, 50) as preview FROM notes WHERE title LIKE ? OR content LIKE ?', [searchQuery, searchQuery], (err, rows) => {
            if (err) {
                log.error('Database error (search-all):', err);
                reject(err);
            }
            resolve(rows);
        });
    });
});

// Tags IPC
ipcMain.handle('add-tag', async (event, name) => {
    return new Promise((resolve, reject) => {
        db.run('INSERT INTO tags (name) VALUES (?)', [name], function(err) {
            if (err) {
                // If the tag already exists, we can get it.
                if (err.code === 'SQLITE_CONSTRAINT') {
                    db.get('SELECT * FROM tags WHERE name = ?', [name], (err, row) => {
                        if (err) {
                            log.error('Database error (add-tag):', err);
                            reject(err);
                        }
                        else resolve(row);
                    });
                } else {
                    log.error('Database error (add-tag):', err);
                    reject(err);
                }
            } else {
                resolve({ id: this.lastID, name });
            }
        });
    });
});

ipcMain.handle('add-note-tag', async (event, { note_id, tag_id }) => {
    return new Promise((resolve, reject) => {
        db.run('INSERT INTO note_tags (note_id, tag_id) VALUES (?, ?)', [note_id, tag_id], function(err) {
            if (err) {
                log.error('Database error (add-note-tag):', err);
                reject(err);
            }
            resolve({ note_id, tag_id });
        });
    });
});

ipcMain.handle('get-note-tags', async (event, note_id) => {
    return new Promise((resolve, reject) => {
        db.all('SELECT t.id, t.name FROM tags t JOIN note_tags nt ON t.id = nt.tag_id WHERE nt.note_id = ?', [note_id], (err, rows) => {
            if (err) {
                log.error('Database error (get-note-tags):', err);
                reject(err);
            }
            resolve(rows);
        });
    });
});

ipcMain.handle('remove-note-tag', async (event, { note_id, tag_id }) => {
    return new Promise((resolve, reject) => {
        db.run('DELETE FROM note_tags WHERE note_id = ? AND tag_id = ?', [note_id, tag_id], function(err) {
            if (err) {
                log.error('Database error (remove-note-tag):', err);
                reject(err);
            }
            resolve({ note_id, tag_id });
        });
    });
});

// Documentation IPC
ipcMain.handle('get-documentation', async () => {
    return new Promise((resolve, reject) => {
        fs.readFile(path.join(__dirname, 'docs', 'DOCUMENTATION.md'), 'utf8', (err, data) => {
            if (err) {
                log.error('Documentation file read error:', err);
                reject(err);
            }
            resolve(data);
        });
    });
});
