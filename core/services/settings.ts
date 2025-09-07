// core/services/settings.ts

import { IDatabaseAdapter, UserSettings } from '../db';

export interface EditorUiState {
  theme: 'light' | 'dark';
  sidebarOpen: boolean;
  lastOpenedDocumentId?: number;
}

export interface ToolSelection {
  primaryTool: string;
  toolOptions: Record<string, any>;
}

export interface AppSettings {
  uiState: EditorUiState;
  toolSelection: ToolSelection;
}

const defaultSettings: AppSettings = {
  uiState: {
    theme: 'dark',
    sidebarOpen: true,
  },
  toolSelection: {
    primaryTool: 'pen',
    toolOptions: {
      pen: { color: '#000000', strokeWidth: 2 },
      eraser: { size: 10 },
    },
  },
};

export class SettingsService {
  private db: IDatabaseAdapter;

  constructor(dbAdapter: IDatabaseAdapter) {
    this.db = dbAdapter;
  }

  /**
   * Fetches the settings for a given user.
   * Returns default settings if none are found.
   */
  async getSettings(userId: string): Promise<AppSettings> {
    const userSettings = await this.db.userSettings.find({ user_id: userId });
    if (userSettings.length > 0) {
      try {
        return JSON.parse(userSettings[0].settings_json);
      } catch (e) {
        console.error('Failed to parse user settings, returning defaults:', e);
        return defaultSettings;
      }
    }
    return defaultSettings;
  }

  /**
   * Updates the settings for a given user.
   * The calling code is responsible for debouncing this function if needed.
   */
  async updateSettings(userId: string, settings: AppSettings): Promise<void> {
    const existingSettings = await this.db.userSettings.find({ user_id: userId });
    const settingsJson = JSON.stringify(settings);

    if (existingSettings.length > 0) {
      await this.db.userSettings.update(existingSettings[0].id, { settings_json: settingsJson });
    } else {
      await this.db.userSettings.create({ user_id: userId, settings_json: settingsJson });
    }
  }
}
