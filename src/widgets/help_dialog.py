from PySide6.QtWidgets import QDialog, QVBoxLayout, QLabel, QPushButton, QTextEdit
from PySide6.QtCore import Qt

HELP_TEXT = """
<b>Kivixa User Manual</b><br><br>
- <b>Creating Notes/Folders:</b> Use the + button to add new notes or folders.<br>
- <b>Exporting:</b> Use the context menu on a note card to export as PDF.<br>
- <b>Keyboard Navigation:</b> Use Tab/Shift+Tab to move between cards.<br>
- <b>Preferences:</b> Access from the settings menu.<br>
- <b>Accessibility:</b> Screen reader support and high-contrast mode available.<br>
- <b>Troubleshooting:</b> See the Troubleshooting tab for common issues.<br>
- <b>Performance:</b> See the Performance Guide for optimization tips.<br>
- <b>API:</b> See API documentation for extensibility.<br>
"""

class HelpDialog(QDialog):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Help & User Manual")
        self.setMinimumSize(600, 400)
        layout = QVBoxLayout(self)
        label = QLabel("<h2>Help & User Manual</h2>")
        label.setAlignment(Qt.AlignCenter)
        layout.addWidget(label)
        help_text = QTextEdit()
        help_text.setReadOnly(True)
        help_text.setHtml(HELP_TEXT)
        layout.addWidget(help_text)
        close_btn = QPushButton("Close")
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn)
