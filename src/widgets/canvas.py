from PySide6.QtCore import Qt
from PySide6.QtGui import QPainter, QPainterPath, QPen, QColor, QWheelEvent, QUndoStack
from PySide6.QtWidgets import QGraphicsView, QGraphicsScene, QGraphicsPathItem, QGraphicsSceneMouseEvent
from src.widgets.undo_commands import DrawCommand


class CanvasScene(QGraphicsScene):
    """
    A QGraphicsScene for drawing, supporting a pen, highlighter, and eraser.
    It manages all the drawn items as QGraphicsPathItems and supports undo/redo.
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setSceneRect(0, 0, 3000, 2000)
        self.setBackgroundBrush(QColor(Qt.GlobalColor.white))

        # --- Drawing Properties ---
        self.tool = 'pen'
        self.pen_color = QColor(Qt.GlobalColor.black)
        self.pen_width = 3
        self.highlighter_color = QColor(255, 255, 0, 150)
        self.highlighter_width = 15
        self.eraser_width = 20

        # --- Drawing State ---
        self.current_path_item = None
        self.current_path = None

        # --- Undo/Redo Stack ---
        self.undo_stack = QUndoStack(self)
        self.undo_stack.setUndoLimit(5)

    def set_tool(self, tool: str):
        self.tool = tool

    def set_pen_color(self, color: QColor):
        self.pen_color = color

    def set_pen_width(self, width: int):
        self.pen_width = width

    def update_background(self, color: QColor):
        self.setBackgroundBrush(color)

    def mousePressEvent(self, event: QGraphicsSceneMouseEvent):
        if event.button() == Qt.MouseButton.LeftButton:
            self.current_path = QPainterPath()
            self.current_path.moveTo(event.scenePos())
            pen = self._get_current_pen()
            self.current_path_item = self.addPath(self.current_path, pen)

    def mouseMoveEvent(self, event: QGraphicsSceneMouseEvent):
        if event.buttons() & Qt.MouseButton.LeftButton and self.current_path_item:
            self.current_path.lineTo(event.scenePos())
            self.current_path_item.setPath(self.current_path)

    def mouseReleaseEvent(self, event: QGraphicsSceneMouseEvent):
        if event.button() == Qt.MouseButton.LeftButton and self.current_path_item:
            # Create and push the DrawCommand onto the undo stack
            command = DrawCommand(self, self.current_path_item)
            self.undo_stack.push(command)

            self.current_path_item = None
            self.current_path = None

    def _get_current_pen(self):
        if self.tool == 'pen':
            return QPen(self.pen_color, self.pen_width, Qt.PenStyle.SolidLine, Qt.PenCapStyle.RoundCap,
                        Qt.PenJoinStyle.RoundJoin)
        elif self.tool == 'highlighter':
            return QPen(self.highlighter_color, self.highlighter_width, Qt.PenStyle.SolidLine,
                        Qt.PenCapStyle.RoundCap, Qt.PenJoinStyle.RoundJoin)
        elif self.tool == 'eraser':
            return QPen(self.backgroundBrush().color(), self.eraser_width, Qt.PenStyle.SolidLine,
                        Qt.PenCapStyle.RoundCap, Qt.PenJoinStyle.RoundJoin)
        return QPen()

    def clear_canvas(self):
        self.clear()
        self.undo_stack.clear()


class CanvasView(QGraphicsView):
    """
    A QGraphicsView that displays the CanvasScene, providing zoom and pan functionality.
    """

    def __init__(self, scene: CanvasScene, parent=None):
        super().__init__(scene, parent)
        self.setRenderHint(QPainter.RenderHint.Antialiasing)
        self.setDragMode(QGraphicsView.DragMode.ScrollHandDrag)
        self.setTransformationAnchor(QGraphicsView.ViewportAnchor.AnchorUnderMouse)
        self.setResizeAnchor(QGraphicsView.ViewportAnchor.AnchorViewCenter)

    def wheelEvent(self, event: QWheelEvent):
        zoom_in_factor = 1.15
        zoom_out_factor = 1 / zoom_in_factor
        if event.angleDelta().y() > 0:
            self.scale(zoom_in_factor, zoom_in_factor)
        else:
            self.scale(zoom_out_factor, zoom_out_factor)
