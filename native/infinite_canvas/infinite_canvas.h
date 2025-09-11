#pragma once

class InfiniteCanvas {
public:
    InfiniteCanvas();
    ~InfiniteCanvas();

    void pan(double dx, double dy);
    void zoom(double factor, double centerX, double centerY);
    void drawStroke(const float* points, int count);
};
