from PySide6.QtWidgets import QFrame, QLabel, QToolButton, QVBoxLayout, QMenu, QInputDialog
from PySide6.QtCore import Signal, Qt
from PySide6.QtGui import QFont, QAction

class NoteCard(QFrame):
    clicked = Signal()
    delete_requested = Signal(str)
    rename_requested = Signal(str, str)

    def __init__(self, note_model, parent=None):
        super().__init__(parent)
        self.note_model = note_model

        self.setFrameShape(QFrame.StyledPanel)
        self.setFrameShadow(QFrame.Raised)
        self.setCursor(Qt.PointingHandCursor)

        self.setStyleSheet("""
            NoteCard {
                background-color: #FFFFE0;
                border-radius: 10px;
                border: 1px solid #D0D0A0;
            }
            QLabel {
                color: #333333;
                background-color: transparent;
                border: none;
            }
        """)

        layout = QVBoxLayout(self)
        self.name_label = QLabel(note_model.name)
        self.name_label.setAlignment(Qt.AlignCenter)
        font = QFont("Arial", 11)
        self.name_label.setFont(font)
        layout.addWidget(self.name_label)

        self.page_style_label = QLabel(f"{note_model.page_size} - {note_model.page_design}")
        self.page_style_label.setAlignment(Qt.AlignCenter)
        font = QFont("Arial", 8)
        self.page_style_label.setFont(font)
        layout.addWidget(self.page_style_label)

        self.menu_button = QToolButton(self)
        self.menu_button.setText("...")
        self.menu_button.setStyleSheet("""
            QToolButton {
                border: none;
                background-color: transparent;
                font-size: 16px;
                padding: 5px;
            }
        """)
        self.menu_button.setPopupMode(QToolButton.InstantPopup)
        self.menu_button.move(self.width() - self.menu_button.width() - 5, 5)

        self.create_menu()

    def create_menu(self):
        menu = QMenu(self)
        delete_action = QAction("Delete", self)
        delete_action.triggered.connect(self._on_delete_action)
        menu.addAction(delete_action)

        rename_action = QAction("Rename", self)
        rename_action.triggered.connect(self._on_rename_action)
        menu.addAction(rename_action)

        menu.addAction(QAction("Move", self))
        menu.addAction(QAction("Duplicate", self))
        menu.addAction(QAction("Export", self))

        self.menu_button.setMenu(menu)

    def _on_delete_action(self):
        self.delete_requested.emit(str(self.note_model.id))

    def _on_rename_action(self):
        new_name, ok = QInputDialog.getText(self, "Rename Note", "Enter new name:", text=self.note_model.name)
        if ok and new_name:
            self.rename_requested.emit(str(self.note_model.id), new_name)

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton and not self.menu_button.geometry().contains(event.pos()):
            self.clicked.emit()
        super().mousePressEvent(event)

    def resizeEvent(self, event):
        self.menu_button.move(self.width() - self.menu_button.width() - 10, 5)
        super().resizeEvent(event)