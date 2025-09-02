from PySide6.QtCore import Qt
from PySide6.QtGui import QPainter, QPainterPath, QPen, QColor, QWheelEvent, QUndoStack, QPixmap
from PySide6.QtWidgets import QGraphicsView, QGraphicsScene, QGraphicsPathItem, QGraphicsSceneMouseEvent, QFileDialog, QGraphicsPixmapItem, QGraphicsProxyWidget, QPushButton, QWidget, QVBoxLayout, QGraphicsItem
from utils.logging_utils import logger


class StrokedPathItem(QGraphicsPathItem):
    def __init__(self, path, pen, parent=None):
        super().__init__(path, parent)
        self.setPen(pen)

    def boundingRect(self):
        return self.path().controlPointRect()

    def shape(self):
        return self.path()


class EditablePixmapItem(QGraphicsPixmapItem):
    def __init__(self, pixmap, parent=None):
        super().__init__(pixmap, parent)
        self.setFlag(QGraphicsItem.ItemIsMovable, True)
        self.setFlag(QGraphicsItem.ItemIsSelectable, True)
        self.delete_button_proxy = None

    def mouseDoubleClickEvent(self, event):
        if not self.delete_button_proxy:
            # Create a delete button
            delete_button = QPushButton("X")
            delete_button.setFixedSize(20, 20)
            delete_button.clicked.connect(self.delete_item)

            # Create a widget to hold the button
            container = QWidget()
            layout = QVBoxLayout(container)
            layout.addWidget(delete_button)
            layout.setContentsMargins(0, 0, 0, 0)
            container.setLayout(layout)

            # Create a proxy widget to embed the button in the scene
            self.delete_button_proxy = QGraphicsProxyWidget(self)
            self.delete_button_proxy.setWidget(container)

            # Position the button at the top-right corner of the pixmap item
            self.delete_button_proxy.setPos(self.boundingRect().topRight().x() - 25, self.boundingRect().topRight().y())
        else:
            self.delete_button_proxy.setVisible(not self.delete_button_proxy.isVisible())

    def delete_item(self):
        if self.scene():
            self.scene().removeItem(self)
            if self.delete_button_proxy:
                self.scene().removeItem(self.delete_button_proxy)
                self.delete_button_proxy = None


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
            self.current_path_item = StrokedPathItem(self.current_path, pen)
            self.addItem(self.current_path_item)

    def mouseMoveEvent(self, event: QGraphicsSceneMouseEvent):
        if event.buttons() & Qt.MouseButton.LeftButton and self.current_path_item:
            self.current_path.lineTo(event.scenePos())
            self.current_path_item.setPath(self.current_path)

    def mouseReleaseEvent(self, event: QGraphicsSceneMouseEvent):
        if event.button() == Qt.MouseButton.LeftButton and self.current_path_item:
            # Create and push the DrawCommand onto the undo stack
            from widgets.undo_commands import DrawCommand
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

    def insert_image(self):
        try:
            file_path, _ = QFileDialog.getOpenFileName(None, "Open Image", "",
                                                     "Image Files (*.png *.jpg *.jpeg *.bmp)")
            if file_path:
                pixmap = QPixmap(file_path)
                if not pixmap.isNull():
                    item = EditablePixmapItem(pixmap)
                    # Center the item in the current view
                    view = self.views()[0]
                    center_point = view.mapToScene(view.viewport().rect().center())
                    item.setPos(center_point)
                    self.addItem(item)
                else:
                    logger.warning(f"Failed to load image: {file_path}")
        except Exception as e:
            logger.error(f"Error inserting image: {e}", exc_info=True)
            try:
                from PySide6.QtWidgets import QMessageBox
                QMessageBox.critical(None, "Image Error", f"Could not insert image: {e}")
            except Exception:
                pass
    # --- Dirty rectangle optimization stub for future performance ---
    def invalidate_dirty_rect(self, rect):
        # Invalidate only the changed region for redraw (future optimization)
        self.invalidate(rect)


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