from PySide6.QtWidgets import QGraphicsView, QGraphicsScene, QGraphicsRectItem, QToolBar, QVBoxLayout, QWidget
from PySide6.QtGui import QIcon, QPainter, QWheelEvent, QMouseEvent, QTouchEvent, QAction, QColor
from PySide6.QtCore import Qt, QRectF, QSizeF
import os

class PagedCanvasScene(QGraphicsScene):
    def set_page_design(self, design):
        self._page_design = design
        self.update()

    def set_page_color(self, color):
        self._page_color = QColor(color)
        self.update()

    def drawBackground(self, painter, rect):
        # Draw the page background (color, lines, grid, etc.)
        page_rect = QRectF(0, 0, self.page_size.width(), self.page_size.height())
        color = getattr(self, '_page_color', QColor(Qt.white))
        painter.fillRect(page_rect, color)
        design = getattr(self, '_page_design', 'Blank')
        if design == 'Lined':
            # Draw horizontal lines
            spacing = 32
            pen = QPainter().pen()
            pen.setColor(QColor('#B0B0B0'))
            pen.setWidth(1)
            painter.setPen(pen)
            y = spacing
            while y < self.page_size.height():
                painter.drawLine(0, y, self.page_size.width(), y)
                y += spacing
        elif design == 'Grid':
            # Draw grid lines
            spacing = 32
            pen = QPainter().pen()
            pen.setColor(QColor('#B0B0B0'))
            pen.setWidth(1)
            painter.setPen(pen)
            x = spacing
            while x < self.page_size.width():
                painter.drawLine(x, 0, x, self.page_size.height())
                x += spacing
            y = spacing
            while y < self.page_size.height():
                painter.drawLine(0, y, self.page_size.width(), y)
                y += spacing
        # else: Blank (just color)
        # Call base class
        super().drawBackground(painter, rect)
    def __init__(self, page_size=QSizeF(210*4, 297*4), parent=None):
        super().__init__(parent)
        self.pages = []
        self.page_size = page_size
        self.current_page_index = 0
        self.add_page()
        self._tool = 'pen'
        self._pen_color = QColor(Qt.black)
        self._pen_width = 2
        self._highlighter_color = QColor(255, 255, 0, 128)
        self._eraser_width = 20
        self._drawing = False
        self._last_point = None
        self._current_stroke = None
        self._strokes = [[] for _ in self.pages]
        self._undo_stack = []

    @property
    def pen_color(self):
        return self._pen_color

    def set_tool(self, tool):
        self._tool = tool

    def set_pen_width(self, width):
        self._pen_width = width

    def set_pen_color(self, color):
        self._pen_color = color

    def clear_canvas(self):
        for item in self.items():
            if hasattr(item, 'is_stroke') and item.is_stroke:
                self.removeItem(item)
        self._strokes[self.current_page_index] = []

    @property
    def undo_stack(self):
        class Undo:
            def __init__(self, scene):
                self.scene = scene
            def undo(self):
                if self.scene._strokes[self.scene.current_page_index]:
                    item = self.scene._strokes[self.scene.current_page_index].pop()
                    self.scene.removeItem(item)
            def redo(self):
                pass  # Not implemented
        return Undo(self)

    def insert_image(self):
        pass  # Not implemented

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            self._drawing = True
            self._last_point = event.scenePos()
            if self._tool == 'pen' or self._tool == 'highlighter':
                from PySide6.QtGui import QPen, QPainterPath
                path = QPainterPath(self._last_point)
                color = self._pen_color if self._tool == 'pen' else self._highlighter_color
                pen = QPen(color, self._pen_width if self._tool == 'pen' else 15, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin)
                stroke = self.addPath(path, pen)
                stroke.is_stroke = True
                self._current_stroke = stroke
                self._strokes[self.current_page_index].append(stroke)
            elif self._tool == 'eraser':
                self.erase_at(event.scenePos())
        super().mousePressEvent(event)

    def mouseMoveEvent(self, event):
        if self._drawing and (self._tool == 'pen' or self._tool == 'highlighter') and self._current_stroke:
            from PySide6.QtGui import QPainterPath
            path = self._current_stroke.path()
            path.lineTo(event.scenePos())
            self._current_stroke.setPath(path)
            self._last_point = event.scenePos()
        elif self._drawing and self._tool == 'eraser':
            self.erase_at(event.scenePos())
        super().mouseMoveEvent(event)

    def mouseReleaseEvent(self, event):
        self._drawing = False
        self._current_stroke = None
        self._last_point = None
        super().mouseReleaseEvent(event)

    def erase_at(self, pos):
        for item in self.items(pos):
            if hasattr(item, 'is_stroke') and item.is_stroke:
                self.removeItem(item)
                if item in self._strokes[self.current_page_index]:
                    self._strokes[self.current_page_index].remove(item)
    def __init__(self, page_size=QSizeF(210*4, 297*4), parent=None):
        super().__init__(parent)
        self.pages = []
        self.page_size = page_size
        self.current_page_index = 0
        self.add_page()

    def add_page(self):
        rect = QGraphicsRectItem(0, 0, self.page_size.width(), self.page_size.height())
        rect.setBrush(QColor(Qt.white))
        rect.setPen(QColor(Qt.gray))
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
        # Only zoom if Ctrl is pressed, otherwise scroll vertically
        if event.modifiers() & Qt.ControlModifier:
            zoom_in_factor = 1.15
            zoom_out_factor = 1 / zoom_in_factor
            if event.angleDelta().y() > 0:
                self.scale(zoom_in_factor, zoom_in_factor)
            else:
                self.scale(zoom_out_factor, zoom_out_factor)
        else:
            # Scroll vertically
            self.verticalScrollBar().setValue(self.verticalScrollBar().value() - event.angleDelta().y())

    def touchEvent(self, event: QTouchEvent):
        points = event.touchPoints()
        if len(points) == 2:
            p1, p2 = points[0].pos(), points[1].pos()
            last_p1, last_p2 = points[0].lastPos(), points[1].lastPos()
            old_dist = (last_p1 - last_p2).manhattanLength()
            new_dist = (p1 - p2).manhattanLength()
            # Pinch to zoom
            if abs(new_dist - old_dist) > 2:  # threshold to avoid accidental zoom
                if old_dist != 0:
                    scale_factor = new_dist / old_dist
                    self.scale(scale_factor, scale_factor)
            else:
                # Two-finger vertical scroll
                avg_y = (p1.y() + p2.y()) / 2
                last_avg_y = (last_p1.y() + last_p2.y()) / 2
                delta_y = avg_y - last_avg_y
                self.verticalScrollBar().setValue(self.verticalScrollBar().value() - delta_y)
            event.accept()
        else:
            super().touchEvent(event)
