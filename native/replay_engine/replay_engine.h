#pragma once

class ReplayEngine {
public:
    ReplayEngine();
    ~ReplayEngine();

    void loadReplay(const char* filePath);
    void play();
    void pause();
    void stop();
    void seek(double timestamp);
};
