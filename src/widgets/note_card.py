from PySide6.QtWidgets import QFrame, QLabel, QToolButton, QVBoxLayout
from PySide6.QtCore import Signal, Qt
from PySide6.QtGui import QFont

class NoteCard(QFrame):
    clicked = Signal()

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
        self.menu_button.move(self.width() - self.menu_button.width() - 5, 5)

    def mousePressEvent(self, event):
        self.clicked.emit()
        super().mousePressEvent(event)

    def resizeEvent(self, event):
        self.menu_button.move(self.width() - self.menu_button.width() - 10, 5)
        super().resizeEvent(event)
