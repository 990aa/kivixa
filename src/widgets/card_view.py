from PySide6.QtWidgets import QScrollArea, QWidget, QGridLayout
from utils.logging_utils import logger
from PySide6.QtCore import Qt, Signal
from widgets.folder_card import FolderCard
from widgets.note_card import NoteCard
from models.data_models import FolderModel, NoteModel

class CardView(QScrollArea):
    note_opened = Signal(NoteModel)

    def __init__(self, main_window, parent=None):
        super().__init__(parent)
        self.main_window = main_window
        self.setWidgetResizable(True)
        self.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)

        self.container = QWidget()
        self.setWidget(self.container)

        self.layout = QGridLayout(self.container)
        self.layout.setAlignment(Qt.AlignmentFlag.AlignTop | Qt.AlignmentFlag.AlignLeft)

    def repopulate_cards(self, items):
        # Clear existing widgets before repopulating
        try:
            while self.layout.count():
                child = self.layout.takeAt(0)
                if child.widget():
                    child.widget().deleteLater()
            # Lazy loading: only load visible cards initially (future optimization)
            col_count = max(1, self.width() // 220) # Adjusted for better spacing
            row, col = 0, 0
            for item in items:
                try:
                    if isinstance(item, FolderModel):
                        card = FolderCard(item)
                    elif isinstance(item, NoteModel):
                        card = NoteCard(item)
                    else:
                        continue
                    card.setMinimumSize(180, 120)
                    self.layout.addWidget(card, row, col)
                    self._connect_card_signals(card)
                    col += 1
                    if col >= col_count:
                        col = 0
                        row += 1
                except Exception as e:
                    logger.error(f"Error creating card for item: {item}: {e}", exc_info=True)
        except Exception as e:
            logger.error(f"Error repopulating cards: {e}", exc_info=True)

    def _connect_card_signals(self, card):
        # Connect signals common to all cards
        card.delete_requested.connect(self.main_window.handle_delete_item)
        card.rename_requested.connect(self.main_window.handle_rename_item)
        card.duplicate_requested.connect(self.main_window.handle_duplicate_item)
        card.move_requested.connect(self.main_window.handle_move_item)

        # Connect type-specific signals
        if isinstance(card, FolderCard):
            card.clicked.connect(lambda: self.main_window.open_folder(card.folder_model.id))
        elif isinstance(card, NoteCard):
            # Use a lambda with a default argument to capture the correct model
            card.double_clicked.connect(lambda model=card.note_model: self.note_opened.emit(model))
            card.export_requested.connect(self.main_window.handle_export_note)

    def clear_view(self):
        while self.layout.count():
            child = self.layout.takeAt(0)
            if child.widget():
                child.widget().deleteLater()
