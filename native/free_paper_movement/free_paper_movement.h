#pragma once

class FreePaperMovement {
public:
    FreePaperMovement();
    ~FreePaperMovement();

    void startMove(double x, double y);
    void updateMove(double x, double y);
    void endMove();
};
