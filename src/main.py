
import sys
from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout
from PySide6.QtCore import Qt
from src.widgets.card_view import CardView
from src.utils.project_manager import ProjectManager
from src.models.data_models import FolderModel, NoteModel

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Kivixa")
        self.setGeometry(100, 100, 1200, 800)
        
        self.project_manager = ProjectManager('projects') # Or your desired project root
        self.current_folder_id = None # Root

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
        """)

        # Central Widget and Layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Card View
        self.card_view = CardView(self)
        main_layout.addWidget(self.card_view)

        self.refresh_card_view()

    def refresh_card_view(self):
        items = self.project_manager.get_items_in_folder(self.current_folder_id)
        self.card_view.repopulate_cards(items)

    def open_folder(self, folder_id):
        self.current_folder_id = folder_id
        self.refresh_card_view()

    def handle_delete_item(self, item_id):
        self.project_manager.delete_item(item_id)
        self.refresh_card_view()

    def handle_rename_item(self, item_id, new_name):
        self.project_manager.rename_item(item_id, new_name)
        self.refresh_card_view()


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
