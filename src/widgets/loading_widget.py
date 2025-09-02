from PySide6.QtWidgets import QDialog, QVBoxLayout, QLabel, QProgressBar, QApplication
from PySide6.QtCore import Qt, QTimer
from PySide6.QtGui import QMovie, QIcon
import os

class LoadingDialog(QDialog):
    def __init__(self, message="Loading...", parent=None, icon_path=None):
        super().__init__(parent)
        self.setWindowFlags(self.windowFlags() | Qt.CustomizeWindowHint | Qt.WindowTitleHint)
        self.setModal(True)
        self.setWindowTitle("Kivixa - Loading")
        if icon_path and os.path.exists(icon_path):
            self.setWindowIcon(QIcon(icon_path))
        self.setFixedSize(320, 180)
        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignCenter)
        # Animated GIF or fallback spinner
        gif_path = os.path.join(os.path.dirname(__file__), '../../resources/icons/loading.gif')
        if os.path.exists(gif_path):
            self.movie = QMovie(gif_path)
            self.label = QLabel()
            self.label.setAlignment(Qt.AlignCenter)
            self.label.setMovie(self.movie)
            self.movie.start()
            layout.addWidget(self.label)
        else:
            self.progress = QProgressBar()
            self.progress.setRange(0, 0)
            layout.addWidget(self.progress)
        self.text = QLabel(message)
        self.text.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.text)

    def set_message(self, msg):
        self.text.setText(msg)

    def show_with_timeout(self, ms=10000):
        self.show()
        QTimer.singleShot(ms, self.accept)
