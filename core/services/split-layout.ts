// core/services/split-layout.ts

import { IDatabaseAdapter } from '../db';

export interface SplitLayout {
  id: number;
  orientation: 'horizontal' | 'vertical';
  dividerPosition: number;
  pane_1_document_id: number | null;
  pane_2_document_id: number | null;
  created_at: string;
  updated_at: string;
}

export class SplitLayoutService {
  private db: IDatabaseAdapter;

  constructor(dbAdapter: IDatabaseAdapter) {
    this.db = dbAdapter;
  }

  async saveLayout(
    orientation: 'horizontal' | 'vertical',
    dividerPosition: number,
    paneDocumentIds: [number | null, number | null]
  ): Promise<void> {
    const layout = {
      orientation,
      dividerPosition,
      pane_1_document_id: paneDocumentIds[0],
      pane_2_document_id: paneDocumentIds[1],
    };

    await this.db.transaction(async () => {
      // There should only ever be one layout, so we update if exists, or create if not.
      const existingLayout = await this.db.userSettings.find({ key: 'split_layout_state' });
      if (existingLayout.length > 0) {
        await this.db.userSettings.update(existingLayout[0].id, { value: JSON.stringify(layout) });
      } else {
        await this.db.userSettings.create({ key: 'split_layout_state', value: JSON.stringify(layout) });
      }
    });
  }

  async restoreLayout(): Promise<SplitLayout | null> {
    const setting = await this.db.userSettings.find({ key: 'split_layout_state' });
    if (setting.length > 0) {
      return JSON.parse(setting[0].value as string) as SplitLayout;
    }
    return null;
  }

  async cleanupForDocument(documentId: number): Promise<void> {
    await this.db.transaction(async () => {
        const layout = await this.restoreLayout();
        if(layout){
            let changed = false;
            if(layout.pane_1_document_id === documentId){
                layout.pane_1_document_id = null;
                changed = true;
            }
            if(layout.pane_2_document_id === documentId){
                layout.pane_2_document_id = null;
                changed = true;
            }
            if(changed){
                await this.saveLayout(layout.orientation, layout.dividerPosition, [layout.pane_1_document_id, layout.pane_2_document_id]);
            }
        }
    });
  }
}
