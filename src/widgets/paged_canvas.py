from PySide6.QtWidgets import QGraphicsView, QGraphicsScene, QGraphicsRectItem, QToolBar, QAction, QVBoxLayout, QWidget
from PySide6.QtGui import QIcon, QPainter, QWheelEvent, QMouseEvent, QTouchEvent
from PySide6.QtCore import Qt, QRectF, QSizeF
import os

class PagedCanvasScene(QGraphicsScene):
    def __init__(self, page_size=QSizeF(210*4, 297*4), parent=None):
        super().__init__(parent)
        self.pages = []
        self.page_size = page_size
        self.current_page_index = 0
        self.add_page()

    def add_page(self):
        rect = QGraphicsRectItem(0, 0, self.page_size.width(), self.page_size.height())
        rect.setBrush(Qt.white)
        rect.setPen(Qt.gray)
        self.addItem(rect)
        self.pages.append(rect)
        self.set_current_page(len(self.pages)-1)

    def remove_current_page(self):
        if len(self.pages) > 1:
            page = self.pages.pop(self.current_page_index)
            self.removeItem(page)
            self.set_current_page(max(0, self.current_page_index-1))

    def set_current_page(self, index):
        self.current_page_index = max(0, min(index, len(self.pages)-1))
        for i, page in enumerate(self.pages):
            page.setVisible(i == self.current_page_index)

    def next_page(self):
        if self.current_page_index < len(self.pages)-1:
            self.set_current_page(self.current_page_index+1)

    def prev_page(self):
        if self.current_page_index > 0:
            self.set_current_page(self.current_page_index-1)

    def get_current_page(self):
        return self.pages[self.current_page_index]

class PagedCanvasView(QGraphicsView):
    def __init__(self, scene, parent=None):
        super().__init__(scene, parent)
        self.setRenderHint(QPainter.Antialiasing)
        self.setDragMode(QGraphicsView.ScrollHandDrag)
        self.setTransformationAnchor(QGraphicsView.AnchorUnderMouse)
        self.setResizeAnchor(QGraphicsView.AnchorViewCenter)
        self.setVerticalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        self._last_touch_points = None

    def wheelEvent(self, event: QWheelEvent):
        zoom_in_factor = 1.15
        zoom_out_factor = 1 / zoom_in_factor
        if event.angleDelta().y() > 0:
            self.scale(zoom_in_factor, zoom_in_factor)
        else:
            self.scale(zoom_out_factor, zoom_out_factor)

    def touchEvent(self, event: QTouchEvent):
        points = event.touchPoints()
        if len(points) == 2:
            # Pinch to zoom
            p1, p2 = points[0].pos(), points[1].pos()
            last_p1, last_p2 = points[0].lastPos(), points[1].lastPos()
            old_dist = (last_p1 - last_p2).manhattanLength()
            new_dist = (p1 - p2).manhattanLength()
            if old_dist != 0:
                scale_factor = new_dist / old_dist
                self.scale(scale_factor, scale_factor)
            # Two-finger pan
            delta = (p1 + p2 - last_p1 - last_p2) / 2
            self.translate(delta.x(), delta.y())
            event.accept()
        else:
            super().touchEvent(event)
