// core/storage/index.ts

import { createHash } from 'crypto';
import { promises as fs } from 'fs';
import * as path from 'path';
import { IDatabaseAdapter } from '../db';
import { Asset } from '../db/types';

// This function would be platform-specific.
// For Electron, it might use app.getPath('userData').
// For Capacitor, it would use the appropriate Filesystem directory.
function getAppDataPath(): string {
    // Placeholder implementation
    // In a real Electron app, you'd get this path from the main process.
    // For now, let's use a local directory for testing.
    const p = path.join(__dirname, '..', '..', 'app_data');
    fs.mkdir(p, { recursive: true });
    return p;
}

export class StorageManager {
    private dbAdapter: IDatabaseAdapter;
    private assetsDir: string;
    private assetsCacheDir: string;

    constructor(dbAdapter: IDatabaseAdapter) {
        this.dbAdapter = dbAdapter;
        const appDataPath = getAppDataPath();
        this.assetsDir = path.join(appDataPath, 'assets');
        this.assetsCacheDir = path.join(appDataPath, 'assets_cache');
        this.init();
    }

    private async init() {
        await fs.mkdir(this.assetsDir, { recursive: true });
        await fs.mkdir(this.assetsCacheDir, { recursive: true });
    }

    private calculateHash(data: Buffer): string {
        return createHash('sha256').update(data).digest('hex');
    }

    async storeAsset(filename: string, data: Buffer, mimeType?: string): Promise<Asset> {
        const hash = this.calculateHash(data);
        const existingAsset = await this.dbAdapter.assets.findByHash(hash);

        if (existingAsset) {
            return existingAsset;
        }

        const assetPath = path.join(this.assetsDir, hash);
        await fs.writeFile(assetPath, data);
        const stats = await fs.stat(assetPath);

        const newAsset = await this.dbAdapter.assets.create({
            filename,
            mime_type: mimeType,
            size: stats.size,
            hash: hash,
        });

        return newAsset;
    }

    async getAssetPath(asset: Asset): Promise<string | null> {
        if (!asset.hash) return null;
        return path.join(this.assetsDir, asset.hash);
    }

    // Thumbnail pipeline - this is a simplified version.
    // A real implementation would involve an image processing library like sharp.
    async generateAndStoreThumbnail(pageId: number, pageContent: Buffer): Promise<void> {
        const thumbnailData = Buffer.from(`Thumbnail for page ${pageId}`); // Placeholder for actual thumbnail generation
        const thumbnailPath = path.join(this.assetsCacheDir, `${pageId}.png`);
        await fs.writeFile(thumbnailPath, thumbnailData);

        await this.dbAdapter.pageThumbnails.create({
            page_id: pageId,
            data: thumbnailData, // In a real scenario, you might store the path instead of the data blob
        });
    }
}
