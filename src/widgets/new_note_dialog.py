from PySide6.QtWidgets import (
    QDialog, QVBoxLayout, QLineEdit, QComboBox, QPushButton, QColorDialog, 
    QDialogButtonBox, QFormLayout
)
from PySide6.QtGui import QColor

class NewNoteDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Create New Note")

        self.layout = QVBoxLayout(self)
        form_layout = QFormLayout()

        self.name_edit = QLineEdit()
        form_layout.addRow("Name:", self.name_edit)

        self.page_size_combo = QComboBox()
        self.page_size_combo.addItems(["A4", "A3", "Infinite"])
        form_layout.addRow("Page Size:", self.page_size_combo)

        self.page_design_combo = QComboBox()
        self.page_design_combo.addItems(["Blank", "Ruled", "Dotted", "Grid", "Graph"])
        form_layout.addRow("Page Design:", self.page_design_combo)

        self.color_button = QPushButton("Choose Color")
        self.color_button.clicked.connect(self.choose_color)
        self._color = QColor("#FFFFFF") # Default white
        self.update_color_button_style()
        form_layout.addRow("Page Color:", self.color_button)

        self.layout.addLayout(form_layout)

        self.button_box = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.button_box.accepted.connect(self.accept)
        self.button_box.rejected.connect(self.reject)
        self.layout.addWidget(self.button_box)

    def choose_color(self):
        color = QColorDialog.getColor(self._color, self)
        if color.isValid():
            self._color = color
            self.update_color_button_style()

    def update_color_button_style(self):
        self.color_button.setStyleSheet(f"background-color: {self._color.name()};")

    def get_details(self):
        return {
            'name': self.name_edit.text(),
            'page_size': self.page_size_combo.currentText(),
            'page_design': self.page_design_combo.currentText(),
            'page_color': self._color.name()
        }
