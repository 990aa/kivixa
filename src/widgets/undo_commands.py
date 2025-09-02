from PySide6.QtGui import QUndoCommand


class DrawCommand(QUndoCommand):
    """An undo command for adding or removing a QGraphicsPathItem from the scene."""

    def __init__(self, scene, item, parent=None):
        super().__init__(parent)
        self.scene = scene
        self.item = item
        self.setText("Draw Item")

    def undo(self):
        """Removes the item from the scene."""
        self.scene.removeItem(self.item)

    def redo(self):
        """Adds the item back to the scene."""
        self.scene.addItem(self.item)
