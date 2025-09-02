from PySide6.QtWidgets import QUndoCommand
from PySide6.QtGui import QPainterPath, QColor

class DrawCommand(QUndoCommand):
    def __init__(self, scene, item, description="Draw"):
        super().__init__(description)
        self.scene = scene
        self.item = item

    def undo(self):
        self.scene.removeItem(self.item)

    def redo(self):
        self.scene.addItem(self.item)
