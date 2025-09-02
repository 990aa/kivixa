from PyQt5.QtWidgets import QWidget
from PyQt5.QtGui import QPainter, QPen, QColor, QPainterPath
from PyQt5.QtCore import Qt, QPoint

class Canvas(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.tool = 'pen'
        self.pen_color = QColor(Qt.black)
        self.pen_width = 3
        self.highlighter_color = QColor(255, 255, 0, 150)
        self.eraser_width = 20

        self.permanent_paths = []
        self.current_path_data = None

        self.background_color = QColor(Qt.white)
        self.setMouseTracking(True)

    def set_tool(self, tool):
        self.tool = tool

    def set_pen_color(self, color):
        self.pen_color = color

    def set_pen_width(self, width):
        self.pen_width = width

    def set_highlighter_color(self, color):
        self.highlighter_color = color
    
    def set_eraser_width(self, width):
        self.eraser_width = width

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            path = QPainterPath()
            path.moveTo(event.pos())
            
            if self.tool == 'pen':
                color = self.pen_color
                width = self.pen_width
            elif self.tool == 'highlighter':
                color = self.highlighter_color
                width = 20  # Fixed width for highlighter
            elif self.tool == 'eraser':
                color = self.background_color 
                width = self.eraser_width
            else:
                return

            self.current_path_data = {
                'path': path,
                'tool': self.tool,
                'color': color,
                'width': width
            }
            self.update()

    def mouseMoveEvent(self, event):
        if event.buttons() & Qt.LeftButton and self.current_path_data:
            self.current_path_data['path'].lineTo(event.pos())
            self.update()

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.LeftButton and self.current_path_data:
            self.permanent_paths.append(self.current_path_data)
            self.current_path_data = None
            self.update()

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)

        # Draw background
        painter.fillRect(self.rect(), self.background_color)

        # Draw permanent paths
        for path_data in self.permanent_paths:
            self.draw_path(painter, path_data)

        # Draw current path
        if self.current_path_data:
            self.draw_path(painter, self.current_path_data)

    def draw_path(self, painter, path_data):
        path = path_data['path']
        color = path_data['color']
        width = path_data['width']
        tool = path_data['tool']

        pen = QPen(color, width, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin)
        painter.setPen(pen)
        
        if tool == 'highlighter':
            painter.setCompositionMode(QPainter.CompositionMode_Multiply)
        else:
            painter.setCompositionMode(QPainter.CompositionMode_SourceOver)

        painter.drawPath(path)