from PySide6.QtWidgets import QScrollArea, QWidget, QGridLayout, QFrame
from PySide6.QtCore import Qt
from src.widgets.folder_card import FolderCard
from src.widgets.note_card import NoteCard
from src.models.data_models import FolderModel, NoteModel

class CardView(QScrollArea):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWidgetResizable(True)
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)

        self.container = QWidget()
        self.setWidget(self.container)

        self.layout = QGridLayout(self.container)
        self.layout.setAlignment(Qt.AlignTop | Qt.AlignLeft)

    def populate_view(self, items):
        # Clear existing items
        for i in reversed(range(self.layout.count())):
            widget = self.layout.itemAt(i).widget()
            if widget is not None:
                widget.deleteLater()

        # Calculate number of columns based on width
        col_count = max(1, self.width() // 200) # Assuming card width of ~200px

        # Add new items
        row, col = 0, 0
        for item in items:
            if isinstance(item, FolderModel):
                card = FolderCard(item)
            elif isinstance(item, NoteModel):
                card = NoteCard(item)
            else:
                continue

            card.setMinimumSize(180, 120)
            self.layout.addWidget(card, row, col)

            col += 1
            if col >= col_count:
                col = 0
                row += 1

    def resizeEvent(self, event):
        super().resizeEvent(event)
        if self.layout.count() > 0:
            items = []
            for i in range(self.layout.count()):
                widget = self.layout.itemAt(i).widget()
                if isinstance(widget, (FolderCard, NoteCard)):
                    items.append(widget.folder_model if isinstance(widget, FolderCard) else widget.note_model)
            self.populate_view(items)
