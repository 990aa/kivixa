
import sys
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout,
                               QPushButton, QInputDialog, QFrame, QHBoxLayout)
from PySide6.QtCore import Qt, QSize
from PySide6.QtGui import QIcon
from src.widgets.card_view import CardView
from src.utils.project_manager import ProjectManager
from src.models.data_models import FolderModel, NoteModel
from src.widgets.new_note_dialog import NewNoteDialog
from src.widgets.move_dialog import MoveDialog

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Kivixa")
        self.setGeometry(100, 100, 1200, 800)
        
        self.project_manager = ProjectManager()
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
            QPushButton#fab {
                border-radius: 28px;
                background-color: #DA4453; /* A modern reddish color */
                color: white;
                font-size: 24px;
                font-weight: bold;
                padding: 0px;
            }
            QPushButton#fab:hover {
                background-color: #E74C3C;
            }
        """)

        # Central Widget and Layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Toolbar
        toolbar = QFrame()
        toolbar_layout = QHBoxLayout(toolbar)
        new_folder_button = QPushButton("New Folder")
        new_folder_button.clicked.connect(self.handle_new_folder)
        toolbar_layout.addWidget(new_folder_button)
        toolbar_layout.addStretch()
        main_layout.addWidget(toolbar)

        # Main content area
        content_frame = QFrame()
        content_layout = QVBoxLayout(content_frame)
        content_layout.setContentsMargins(0,0,0,0)
        main_layout.addWidget(content_frame)

        self.card_view = CardView(self)
        content_layout.addWidget(self.card_view)

        # FAB Button
        self.fab = QPushButton("+", self)
        self.fab.setObjectName("fab")
        self.fab.setFixedSize(56, 56)
        self.fab.setIconSize(QSize(24, 24))
        self.fab.clicked.connect(self.handle_new_note)
        
        self.refresh_card_view()

    def resizeEvent(self, event):
        super().resizeEvent(event)
        fab_margin = 16
        self.fab.move(self.width() - self.fab.width() - fab_margin,
                      self.height() - self.fab.height() - fab_margin)

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

    def handle_duplicate_item(self, item_id):
        self.project_manager.duplicate_item(item_id)
        self.refresh_card_view()

    def handle_move_item(self, item_id):
        dialog = MoveDialog(self.project_manager.root_folder, item_id, self)
        if dialog.exec():
            new_parent_id = dialog.get_selected_folder_id()
            if new_parent_id:
                self.project_manager.move_item(item_id, new_parent_id)
                self.refresh_card_view()

    def handle_new_folder(self):
        name, ok = QInputDialog.getText(self, "New Folder", "Enter folder name:")
        if ok and name:
            self.project_manager.create_folder(name, self.current_folder_id)
            self.refresh_card_view()

    def handle_new_note(self):
        dialog = NewNoteDialog(self)
        if dialog.exec():
            details = dialog.get_details()
            self.project_manager.create_note(
                name=details['name'],
                parent_id=self.current_folder_id,
                page_size=details['page_size'],
                page_design=details['page_design'],
                page_color=details['page_color']
            )
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
