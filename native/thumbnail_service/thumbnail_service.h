#pragma once

class ThumbnailService {
public:
    ThumbnailService();
    ~ThumbnailService();

    void generateThumbnail(const char* filePath, const char* outputPath, int width, int height);
};
