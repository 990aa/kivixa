#pragma once

class StrokeEngine {
public:
    StrokeEngine();
    ~StrokeEngine();

    void beginStroke(float x, float y, float pressure);
    void addPoint(float x, float y, float pressure);
    void endStroke();
};
