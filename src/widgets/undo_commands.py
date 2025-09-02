from PyQt5.QtWidgets import QUndoCommand
from PyQt5.QtGui import QPainterPath, QColor

class DrawCommand(QUndoCommand):
    def __init__(self, canvas_scene, path, path_properties, description="Draw"): # Added description parameter
        super().__init__(description)
        self.canvas_scene = canvas_scene
        self.path = path
        self.path_properties = path_properties

    def undo(self):
        if self.path in self.canvas_scene.permanent_paths:
            self.canvas_scene.permanent_paths.remove(self.path)
            self.canvas_scene.update()

    def redo(self):
        if self.path not in self.canvas_scene.permanent_paths:
            self.canvas_scene.permanent_paths.append(self.path)
            self.canvas_scene.update()