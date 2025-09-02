from PySide6.QtWidgets import QDialog, QVBoxLayout, QCheckBox, QPushButton, QLabel, QComboBox
from PySide6.QtCore import Qt

class UpdateSettingsDialog(QDialog):
    def __init__(self, current_prefs=None, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Update Preferences")
        self.setMinimumSize(350, 200)
        layout = QVBoxLayout(self)
        self.auto_check = QCheckBox("Automatically check for updates")
        self.auto_check.setChecked(current_prefs.get('auto_check', True) if current_prefs else True)
        layout.addWidget(self.auto_check)
        self.auto_install = QCheckBox("Automatically install updates")
        self.auto_install.setChecked(current_prefs.get('auto_install', False) if current_prefs else False)
        layout.addWidget(self.auto_install)
        self.channel_label = QLabel("Update Channel:")
        layout.addWidget(self.channel_label)
        self.channel_combo = QComboBox()
        self.channel_combo.addItems(["Stable", "Beta", "Alpha"])
        self.channel_combo.setCurrentText(current_prefs.get('channel', 'Stable') if current_prefs else 'Stable')
        layout.addWidget(self.channel_combo)
        self.save_btn = QPushButton("Save Preferences")
        layout.addWidget(self.save_btn)
        self.save_btn.clicked.connect(self.accept)

    def get_prefs(self):
        return {
            'auto_check': self.auto_check.isChecked(),
            'auto_install': self.auto_install.isChecked(),
            'channel': self.channel_combo.currentText()
        }
