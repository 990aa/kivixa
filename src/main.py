
import sys
from PySide6.QtWidgets import (
    QApplication,
    QMainWindow,
    QWidget,
    QVBoxLayout,
    QScrollArea,
    QGridLayout,
    QLabel,
)
from PySide6.QtCore import Qt


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Kivixa")
        self.setGeometry(100, 100, 1200, 800)

        # Modern QSS Stylesheet
        self.setStyleSheet("""
            QWidget {
                background-color: #2e2e2e;
                color: #ffffff;
                font-family: "Segoe UI";
                font-size: 14px;
            }
            QMainWindow {
                background-color: #1e1e1e;
            }
            QScrollArea {
                border: none;
            }
            .card {
                background-color: #3c3c3c;
                border-radius: 10px;
                padding: 15px;
                margin: 10px;
                min-height: 150px;
                min-width: 200px;
                box-shadow: 5px 5px 10px #1e1e1e;
            }
            .card QLabel {
                font-size: 16px;
                font-weight: bold;
            }
            QPushButton {
                background-color: #5a5a5a;
                border: 1px solid #76797c;
                border-radius: 5px;
                padding: 5px 10px;
            }
            QPushButton:hover {
                background-color: #6a6a6a;
            }
            QPushButton:pressed {
                background-color: #7a7a7a;
            }
        """)

        # Central Widget and Layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Scroll Area for the Card Grid
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarAlwaysOff)
        main_layout.addWidget(scroll_area)

        # Grid Widget and Layout
        grid_widget = QWidget()
        scroll_area.setWidget(grid_widget)
        self.grid_layout = QGridLayout(grid_widget)
        self.grid_layout.setSpacing(10)
        self.grid_layout.setContentsMargins(20, 20, 20, 20)

        self.populate_cards()

    def populate_cards(self):
        """Populates the grid with placeholder cards."""
        for i in range(20):  # Create 20 placeholder cards
            card = QWidget()
            card.setObjectName("card")
            card.setProperty("class", "card")
            
            card_layout = QVBoxLayout(card)
            card_layout.addWidget(QLabel(f"Card {i + 1}"))
            card_layout.addStretch()

            row = i // 4
            col = i % 4
            self.grid_layout.addWidget(card, row, col)


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Kivixa")
    app.setApplicationVersion("1.0.0")
    app.setOrganizationName("Kivixa")

    window = MainWindow()
    window.showMaximized()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
