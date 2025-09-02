from PySide6.QtWidgets import QDialog, QVBoxLayout, QLabel, QPushButton, QTextEdit, QProgressBar, QDialogButtonBox
from PySide6.QtCore import Qt

class UpdateNotificationDialog(QDialog):
    def __init__(self, changelog, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Update Available")
        self.setMinimumSize(400, 300)
        layout = QVBoxLayout(self)
        label = QLabel("A new update is available!")
        label.setAlignment(Qt.AlignCenter)
        layout.addWidget(label)
        changelog_box = QTextEdit()
        changelog_box.setReadOnly(True)
        changelog_box.setHtml(changelog)
        layout.addWidget(changelog_box)
        self.button_box = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        layout.addWidget(self.button_box)
        self.button_box.accepted.connect(self.accept)
        self.button_box.rejected.connect(self.reject)

class UpdateProgressDialog(QDialog):
    def __init__(self, title="Downloading Update", parent=None):
        super().__init__(parent)
        self.setWindowTitle(title)
        self.setMinimumSize(350, 120)
        layout = QVBoxLayout(self)
        self.label = QLabel("Starting...")
        layout.addWidget(self.label)
        self.progress = QProgressBar()
        self.progress.setRange(0, 100)
        layout.addWidget(self.progress)
        self.cancel_btn = QPushButton("Cancel")
        layout.addWidget(self.cancel_btn)
        self.cancel_btn.clicked.connect(self.reject)

class UpdateHistoryDialog(QDialog):
    def __init__(self, history_html, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Update History & Version Info")
        self.setMinimumSize(500, 400)
        layout = QVBoxLayout(self)
        label = QLabel("<b>Update History</b>")
        layout.addWidget(label)
        history_box = QTextEdit()
        history_box.setReadOnly(True)
        history_box.setHtml(history_html)
        layout.addWidget(history_box)
        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn)
