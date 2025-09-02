from PySide6.QtWidgets import QScrollArea, QWidget, QGridLayout
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

    def populate_and_connect(self, items):
        self.clear_view()
        col_count = max(1, self.width() // 200)
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
            self.connect_card_signals(card)

            col += 1
            if col >= col_count:
                col = 0
                row += 1

    def connect_card_signals(self, card):
        if isinstance(card, (FolderCard, NoteCard)):
            card.delete_requested.connect(self.parent().handle_delete_item)
            card.rename_requested.connect(self.parent().handle_rename_item)
            if isinstance(card, FolderCard):
                card.clicked.connect(lambda: self.parent().open_folder(card.folder_model.id))
            else:
                # Assuming NoteCard has a similar clicked signal for opening the note
                pass

    def repopulate_cards(self, items):
        self.clear_view()
        self.populate_and_connect(items)

    def clear_view(self):
        while self.layout.count():
            child = self.layout.takeAt(0)
            if child.widget():
                child.widget().deleteLater()
