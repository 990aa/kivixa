import sys
from functools import partial

from PySide6.QtCore import Qt, QSize, Signal
from PySide6.QtGui import QIcon, QAction, QActionGroup, QColor
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QPushButton, QInputDialog, 
    QFrame, QHBoxLayout, QStackedWidget, QToolBar, QColorDialog, QComboBox, QStyle
)

from src.widgets.card_view import CardView
from src.utils.project_manager import ProjectManager
from src.models.data_models import FolderModel, NoteModel
from src.widgets.new_note_dialog import NewNoteDialog
from src.widgets.move_dialog import MoveDialog
from src.widgets.canvas import CanvasView, CanvasScene


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Kivixa")
        self.setGeometry(100, 100, 1200, 800)
        self.project_manager = ProjectManager()
        self.current_folder_id = None  # Root
        self.canvas_view = None
        self.canvas_scene = None

        self._setup_styles()
        self._setup_ui()
        self._create_drawing_toolbar()

        self.refresh_card_view()

    def _setup_styles(self):
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
            QScrollArea, QGraphicsView {
                border: none;
            }
            QPushButton#fab {
                border-radius: 28px;
                background-color: #DA4453;
                color: white;
                font-size: 24px;
                font-weight: bold;
                padding: 0px;
            }
            QPushButton#fab:hover {
                background-color: #E74C3C;
            }
            QToolBar {
                background-color: #333;
                border: none;
                spacing: 5px;
                padding: 5px;
            }
            QToolButton, QPushButton#colorPickerButton {
                background-color: #444;
                border: 1px solid #555;
                border-radius: 4px;
                padding: 5px;
            }
            QToolButton:checked, QPushButton#colorPickerButton:pressed {
                background-color: #5a5a5a;
                border-color: #777;
            }
            QComboBox {
                background-color: #444;
                border: 1px solid #555;
                border-radius: 4px;
                padding: 3px;
            }
        """)

    def _setup_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Main content area with stacked widget for view switching
        self.main_stack = QStackedWidget()
        main_layout.addWidget(self.main_stack)

        # Card View (initial view)
        self.card_view = CardView(self)
        self.main_stack.addWidget(self.card_view)
        self.card_view.note_opened.connect(self.open_note_editor)

        # FAB Button
        self.fab = QPushButton("+", self)
        self.fab.setObjectName("fab")
        self.fab.setFixedSize(56, 56)
        self.fab.setIconSize(QSize(24, 24))
        self.fab.clicked.connect(self.handle_new_note)

    def _create_drawing_toolbar(self):
        self.drawing_toolbar = QToolBar("Drawing")
        self.drawing_toolbar.setIconSize(QSize(24, 24))
        self.addToolBar(Qt.ToolBarArea.TopToolBarArea, self.drawing_toolbar)

        # Back Action
        back_action = QAction(self.style().standardIcon(QStyle.StandardPixmap.SP_ArrowBack), "Back", self)
        back_action.triggered.connect(self.close_note_editor)
        self.drawing_toolbar.addAction(back_action)
        self.drawing_toolbar.addSeparator()

        # Tool Actions (Pen, Highlighter, Eraser)
        tools_group = QActionGroup(self)
        tools_group.setExclusive(True)
        pen_action = QAction(QIcon(':/icons/pen.png'), "Pen", self)
        pen_action.setCheckable(True)
        pen_action.setChecked(True)
        pen_action.triggered.connect(lambda: self.canvas_scene.set_tool('pen'))
        highlighter_action = QAction(QIcon(':/icons/highlighter.png'), "Highlighter", self)
        highlighter_action.setCheckable(True)
        highlighter_action.triggered.connect(lambda: self.canvas_scene.set_tool('highlighter'))
        eraser_action = QAction(QIcon(':/icons/eraser.png'), "Eraser", self)
        eraser_action.setCheckable(True)
        eraser_action.triggered.connect(lambda: self.canvas_scene.set_tool('eraser'))
        
        tools_group.addAction(pen_action)
        tools_group.addAction(highlighter_action)
        tools_group.addAction(eraser_action)
        self.drawing_toolbar.addActions(tools_group.actions())
        self.drawing_toolbar.addSeparator()

        # Size Selector
        self.size_combo = QComboBox()
        pen_sizes = ['2', '3', '5', '8', '13', '21']
        self.size_combo.addItems(pen_sizes)
        self.size_combo.currentTextChanged.connect(lambda w: self.canvas_scene.set_pen_width(int(w)))
        self.drawing_toolbar.addWidget(self.size_combo)

        # Color Picker
        self.color_button = QPushButton()
        self.color_button.setObjectName("colorPickerButton")
        self.color_button.setFixedSize(32, 32)
        self.color_button.clicked.connect(self._handle_color_button_click)
        self.drawing_toolbar.addWidget(self.color_button)
        self.drawing_toolbar.addSeparator()

        # Undo/Redo
        undo_action = QAction(self.style().standardIcon(QStyle.StandardPixmap.SP_DialogUndoButton), "Undo", self)
        undo_action.triggered.connect(lambda: self.canvas_scene.undo())
        self.drawing_toolbar.addAction(undo_action)
        redo_action = QAction(self.style().standardIcon(QStyle.StandardPixmap.SP_DialogRedoButton), "Redo", self)
        redo_action.triggered.connect(lambda: self.canvas_scene.redo())
        self.drawing_toolbar.addAction(redo_action)

        self.drawing_toolbar.hide()

    def open_note_editor(self, note: NoteModel):
        self.canvas_scene = CanvasScene()
        self.canvas_view = CanvasView(self.canvas_scene, self)
        
        # Set background color from note model
        bg_color = QColor(note.page_color)
        self.canvas_scene.update_background(bg_color)
        
        # Set initial pen color and update button
        self._update_color_button_style(self.canvas_scene.pen_color)

        self.main_stack.addWidget(self.canvas_view)
        self.main_stack.setCurrentWidget(self.canvas_view)
        self.drawing_toolbar.show()
        self.fab.hide()

    def close_note_editor(self):
        self.main_stack.setCurrentWidget(self.card_view)
        self.drawing_toolbar.hide()
        self.fab.show()
        if self.canvas_view:
            self.main_stack.removeWidget(self.canvas_view)
            self.canvas_view.deleteLater()
            self.canvas_view = None
            self.canvas_scene = None

    def _handle_color_button_click(self):
        if not self.canvas_scene: return
        
        initial_color = self.canvas_scene.pen_color
        dialog = QColorDialog(initial_color, self)
        if dialog.exec():
            color = dialog.currentColor()
            self.canvas_scene.set_pen_color(color)
            self._update_color_button_style(color)

    def _update_color_button_style(self, color: QColor):
        self.color_button.setStyleSheet(f"background-color: {color.name()}; border: 1px solid #555; border-radius: 4px;")

    def resizeEvent(self, event):
        super().resizeEvent(event)
        fab_margin = 16
        self.fab.move(self.width() - self.fab.width() - fab_margin,
                      self.height() - self.fab.height() - fab_margin)

    # --- Data Handling Methods ---
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
    window = MainWindow()
    window.showMaximized()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()