
import sys
import os
from functools import partial
from utils.logging_utils import logger, log_exception

from PySide6.QtCore import Qt, QSize, Signal
from PySide6.QtGui import QIcon, QAction, QActionGroup, QColor
from PySide6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QPushButton, QInputDialog, 
    QFrame, QHBoxLayout, QStackedWidget, QToolBar, QColorDialog, QComboBox, QStyle
)

from widgets.card_view import CardView
from utils.project_manager import ProjectManager
from models.data_models import FolderModel, NoteModel
from widgets.new_note_dialog import NewNoteDialog
from widgets.move_dialog import MoveDialog
from widgets.paged_canvas import PagedCanvasView, PagedCanvasScene
from widgets.help_dialog import HelpDialog
from widgets.update_dialogs import UpdateNotificationDialog, UpdateProgressDialog, UpdateHistoryDialog
from widgets.update_settings_dialog import UpdateSettingsDialog


class MainWindow(QMainWindow):
    def _setup_update_menu(self):
        # Add update actions to the menu bar
        update_menu = self.menuBar().addMenu("Updates")
        check_action = QAction("Check for Updates", self)
        check_action.triggered.connect(self.manual_check_for_updates)
        update_menu.addAction(check_action)
        settings_action = QAction("Update Preferences", self)
        settings_action.triggered.connect(self.show_update_settings)
        update_menu.addAction(settings_action)
        history_action = QAction("Update History", self)
        history_action.triggered.connect(self.show_update_history)
        update_menu.addAction(history_action)
        version_action = QAction("Version Info", self)
        version_action.triggered.connect(self.show_version_info)
        update_menu.addAction(version_action)

    def manual_check_for_updates(self):
        # Load update config
        import json
        config_path = os.path.join(os.path.dirname(__file__), '..', 'build', 'update_config.json')
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
        except Exception:
            config = {"update_channel": "stable", "offline_mode": False}
        channel = config.get("update_channel", "stable")
        offline = config.get("offline_mode", False)
        # Get current version
        version_path = os.path.join(os.path.dirname(__file__), '..', 'build', 'version.txt')
        try:
            with open(version_path, 'r', encoding='utf-8') as f:
                current_version = f.read().strip()
        except Exception:
            current_version = "0.0.0"
        # Start update check
        from utils.github_updater import GitHubUpdater
        self.update_progress = UpdateProgressDialog(parent=self)
        self.update_progress.label.setText("Checking for updates...")
        self.update_progress.progress.setValue(0)
        self.update_progress.show()
        self.updater_thread = GitHubUpdater(current_version, channel=channel, offline=offline)
        self.updater_thread.signals.progress.connect(self.update_progress.progress.setValue)
        self.updater_thread.signals.status.connect(self.update_progress.label.setText)
        self.updater_thread.signals.finished.connect(self._on_update_finished)
        self.update_progress.cancel_btn.clicked.connect(self.updater_thread.terminate)
        self.updater_thread.start()

    def _on_update_finished(self, success, msg):
        self.update_progress.accept()
        from PySide6.QtWidgets import QMessageBox
        if success and msg == "Update installed":
            QMessageBox.information(self, "Update Complete", "The application was updated and will now restart.")
        elif success:
            QMessageBox.information(self, "No Update", "You are already on the latest version.")
        else:
            QMessageBox.critical(self, "Update Error", msg)

    def show_update_settings(self):
        # Load current prefs from file or defaults
        import os, json
        prefs_path = os.path.join(os.path.dirname(__file__), '..', 'build', 'update_prefs.json')
        try:
            with open(prefs_path, 'r', encoding='utf-8') as f:
                prefs = json.load(f)
        except Exception:
            prefs = {}
        dlg = UpdateSettingsDialog(prefs, self)
        if dlg.exec():
            new_prefs = dlg.get_prefs()
            with open(prefs_path, 'w', encoding='utf-8') as f:
                json.dump(new_prefs, f, indent=2)

    def show_update_history(self):
        # Simulate update history
        history_html = """
        <b>v2.0.0</b> - 2025-09-01<br>Major update.<br><br>
        <b>v1.5.0</b> - 2025-06-10<br>Performance improvements.<br><br>
        <b>v1.0.0</b> - 2025-01-01<br>Initial release.<br>
        """
        dlg = UpdateHistoryDialog(history_html, self)
        dlg.exec()

    def show_version_info(self):
        from PySide6.QtWidgets import QMessageBox
        QMessageBox.information(self, "Version Info", "Kivixa v2.0.0\nBuild date: 2025-09-02")

    def check_network_connectivity(self):
        import socket
        try:
            # Try to connect to a public DNS server
            socket.create_connection(("8.8.8.8", 53), timeout=2)
            return True
        except Exception:
            return False

    def handle_export_note(self, note_id):
        """
        Export the note's canvas to a PDF file using vector graphics.
        Disable export for infinite canvas (if implemented).
        """
        from utils.logging_utils import logger
        try:
            from PySide6.QtPrintSupport import QPrinter
            from PySide6.QtWidgets import QFileDialog, QMessageBox
            # Find the note model by id
            note = self.project_manager.find_note_by_id(note_id)
            if not note:
                QMessageBox.warning(self, "Export Error", "Note not found.")
                return

            # Check for infinite canvas (if your NoteModel or CanvasScene has such a property)
            # Here, we assume page_size == 'Infinite' means infinite canvas
            if hasattr(note, 'page_size') and str(note.page_size).lower() == 'infinite':
                QMessageBox.information(self, "Export Disabled", "Export to PDF is not available for infinite canvas notes.")
                return

            # Ask user for PDF file path
            file_path, _ = QFileDialog.getSaveFileName(self, "Export Note as PDF", note.name + ".pdf", "PDF Files (*.pdf)")
            if not file_path:
                return

            # Create a QPrinter for PDF output
            printer = QPrinter(QPrinter.HighResolution)
            printer.setOutputFormat(QPrinter.PdfFormat)
            printer.setOutputFileName(file_path)

            # Set page size if available
            if hasattr(note, 'page_size') and str(note.page_size).upper() in ["A4", "LETTER", "LEGAL"]:
                from PySide6.QtPrintSupport import QPageSize
                size_map = {"A4": QPageSize.A4, "LETTER": QPageSize.Letter, "LEGAL": QPageSize.Legal}
                printer.setPageSize(QPageSize(size_map.get(str(note.page_size).upper(), QPageSize.A4)))

            # Find the canvas for this note (if open)
            # If the note is currently open, use self.canvas_view; otherwise, load from storage if possible
            canvas_view = None
            if self.canvas_view and hasattr(self.canvas_view, 'scene') and self.canvas_scene:
                # Check if the open note matches
                if hasattr(self.canvas_scene, 'note_model') and str(self.canvas_scene.note_model.id) == note_id:
                    canvas_view = self.canvas_view
            # Fallback: try to open the note in a temporary CanvasView/Scene (not implemented here)
            if not canvas_view:
                QMessageBox.warning(self, "Export Error", "Please open the note to export it.")
                return

            # Render the scene to the printer (vector)
            painter = None
            try:
                from PySide6.QtGui import QPainter
                painter = QPainter(printer)
                # Render the scene (vector)
                canvas_view.scene().render(painter)
            finally:
                if painter:
                    painter.end()

            QMessageBox.information(self, "Export Complete", f"Note exported to {file_path}")
        except Exception as e:
            logger.error(f"Export to PDF failed: {e}", exc_info=True)
            try:
                from PySide6.QtWidgets import QMessageBox
                QMessageBox.critical(self, "Export Error", f"Export failed: {e}")
            except Exception:
                pass
    def __init__(self):
        super().__init__()
        icon_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../build/icon.ico'))
        self.setWindowTitle("Kivixa")
        self.setGeometry(100, 100, 1200, 800)
        if os.path.exists(icon_path):
            self.setWindowIcon(QIcon(icon_path))
        self.icon_path = icon_path
        self.project_manager = ProjectManager()
        self.current_folder_id = None  # Root
        self.canvas_view = None
        self.canvas_scene = None

        # Delete all previous log files
        logs_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '../build/logs'))
        if os.path.exists(logs_dir):
            for f in os.listdir(logs_dir):
                if f.endswith('.txt') or f.endswith('.log'):
                    try:
                        os.remove(os.path.join(logs_dir, f))
                    except Exception:
                        pass
        self._setup_styles()
        self._setup_ui()
        self._create_drawing_toolbar()
        self.refresh_card_view()
        self._setup_update_menu()

    def show_loading_dialog(self, message="Loading...", timeout=10000):
        from widgets.loading_widget import LoadingDialog
        dlg = LoadingDialog(message, self, icon_path=self.icon_path)
        dlg.show_with_timeout(timeout)
        QApplication.processEvents()
        return dlg

    def _setup_styles(self):
        try:
            with open("resources/styles.qss", "r") as f:
                self.setStyleSheet(f.read())
        except FileNotFoundError:
            print("Stylesheet not found.")

    def _setup_ui(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Top bar with persistent back button and help button
        top_bar = QHBoxLayout()
        self.back_btn = QPushButton()
        self.back_btn.setIcon(QIcon('resources/icons/arrow-left.svg'))
        self.back_btn.setIconSize(QSize(28, 28))
        self.back_btn.setFixedSize(40, 40)
        self.back_btn.setToolTip("Back")
        self.back_btn.clicked.connect(self._handle_back)
        top_bar.addWidget(self.back_btn)
        top_bar.addStretch()
        help_btn = QPushButton()
        help_btn.setIcon(QIcon('resources/icons/help.svg') if os.path.exists('resources/icons/help.svg') else QIcon())
        help_btn.setToolTip("Open Help & User Manual")
        help_btn.setFixedSize(32, 32)
        help_btn.clicked.connect(self.show_help_dialog)
        top_bar.addWidget(help_btn)
        main_layout.addLayout(top_bar)

        # Main content area with stacked widget for view switching
        self.main_stack = QStackedWidget()
        main_layout.addWidget(self.main_stack)

        # Card View (initial view)
        self.card_view = CardView(self, self)
        self.main_stack.addWidget(self.card_view)
        self.card_view.note_opened.connect(self.open_note_editor)

        # FAB Button
        self.fab = QPushButton("+", self)
        self.fab.setObjectName("fab")
        self.fab.setFixedSize(56, 56)
        self.fab.setIconSize(QSize(24, 24))
        self.fab.setToolTip("Create a new note or folder")
        self.fab.clicked.connect(self.handle_new_note)
    def show_help_dialog(self):
        dlg = HelpDialog(self)
        dlg.exec()

    def _create_drawing_toolbar(self):
        self.drawing_toolbar = QToolBar("Drawing")
        self.drawing_toolbar.setIconSize(QSize(24, 24))
        self.addToolBar(Qt.ToolBarArea.TopToolBarArea, self.drawing_toolbar)

        # Back Action
        back_action = QAction(QIcon("resources/icons/arrow-left.svg"), "Back", self)
        back_action.triggered.connect(self.close_note_editor)
        self.drawing_toolbar.addAction(back_action)
        self.drawing_toolbar.addSeparator()

        # Tool Actions (Pen, Highlighter, Eraser) - icons only
        self.tools_group = QActionGroup(self)
        self.tools_group.setExclusive(True)
        self.pen_action = QAction(QIcon('resources/icons/pen.svg'), "", self)
        self.pen_action.setCheckable(True)
        self.pen_action.setChecked(True)
        self.pen_action.triggered.connect(lambda: self._set_active_tool('pen'))
        self.highlighter_action = QAction(QIcon('resources/icons/highlighter.svg'), "", self)
        self.highlighter_action.setCheckable(True)
        self.highlighter_action.triggered.connect(lambda: self._set_active_tool('highlighter'))
        self.eraser_action = QAction(QIcon('resources/icons/eraser.svg'), "", self)
        self.eraser_action.setCheckable(True)
        self.eraser_action.triggered.connect(lambda: self._set_active_tool('eraser'))
        self.tools_group.addAction(self.pen_action)
        self.tools_group.addAction(self.highlighter_action)
        self.tools_group.addAction(self.eraser_action)
        for action in self.tools_group.actions():
            action.setIconVisibleInMenu(True)
        self.drawing_toolbar.addActions(self.tools_group.actions())
        self.drawing_toolbar.addSeparator()

        # Insert Image Action
        insert_image_action = QAction(QIcon('resources/icons/image.svg'), "", self)
        insert_image_action.triggered.connect(lambda: self.canvas_scene.insert_image())
        self.drawing_toolbar.addAction(insert_image_action)
        self.drawing_toolbar.addSeparator()
        # Clear Canvas Action
        clear_canvas_action = QAction(QIcon('resources/icons/trash.svg'), "", self)
        clear_canvas_action.triggered.connect(lambda: self.canvas_scene.clear_canvas())
        self.drawing_toolbar.addAction(clear_canvas_action)
        self.drawing_toolbar.addSeparator()

        # Thickness Slider
        from PySide6.QtWidgets import QSlider, QLabel
        self.thickness_slider = QSlider(Qt.Horizontal)
        self.thickness_slider.setMinimum(1)
        self.thickness_slider.setMaximum(40)
        self.thickness_slider.setValue(2)
        self.thickness_slider.setFixedWidth(100)
        self.thickness_slider.valueChanged.connect(self._handle_thickness_change)
        self.thickness_label = QLabel("Thickness: 2")
        self.drawing_toolbar.addWidget(self.thickness_label)
        self.drawing_toolbar.addWidget(self.thickness_slider)

        # Color Picker
        self.color_button = QPushButton()
        self.color_button.setObjectName("colorPickerButton")
        self.color_button.setFixedSize(32, 32)
        self.color_button.clicked.connect(self._handle_color_button_click)
        self.drawing_toolbar.addWidget(self.color_button)
        self.drawing_toolbar.addSeparator()

        # Undo/Redo
        undo_action = QAction(QIcon('resources/icons/undo.svg'), "", self)
        undo_action.triggered.connect(lambda: self.canvas_scene.undo_stack.undo())
        self.drawing_toolbar.addAction(undo_action)
        redo_action = QAction(QIcon('resources/icons/redo.svg'), "", self)
        redo_action.triggered.connect(lambda: self.canvas_scene.undo_stack.redo())
        self.drawing_toolbar.addAction(redo_action)

    def _set_active_tool(self, tool):
        self.canvas_scene.set_tool(tool)
        # Visual feedback for active tool
        for action, name in zip([self.pen_action, self.highlighter_action, self.eraser_action], ['pen', 'highlighter', 'eraser']):
            if tool == name:
                action.setChecked(True)
                action.setStyleSheet("background-color: #d3d3d3;")
            else:
                action.setChecked(False)
                action.setStyleSheet("")

    def _handle_thickness_change(self, value):
        self.thickness_label.setText(f"Thickness: {value}")
        self.canvas_scene.set_pen_width(value)

    def _handle_back(self):
        # If in note editor, go back to card view; else, do nothing or implement further stack logic
        if self.main_stack.currentWidget() == self.canvas_view:
            self.close_note_editor()
        # Optionally, add more navigation stack logic here

        self.drawing_toolbar.hide()

    def open_note_editor(self, note: NoteModel):
        from widgets.paged_canvas import PagedCanvasScene
        self.canvas_scene = PagedCanvasScene()
        self.canvas_scene.note_model = note
        # Set initial page design and color
        self.canvas_scene.set_page_design(getattr(note, 'page_design', 'Blank'))
        self.canvas_scene.set_page_color(getattr(note, 'page_color', '#FFFFFF'))
        self.canvas_view = PagedCanvasView(self.canvas_scene, self)
        # Add page navigation toolbar
        self.page_toolbar = QToolBar("Pages")
        self.page_toolbar.setIconSize(QSize(24, 24))
        prev_action = QAction(QIcon('resources/icons/arrow-left.svg'), "Previous Page", self)
        prev_action.triggered.connect(self.canvas_scene.prev_page)
        self.page_toolbar.addAction(prev_action)
        next_action = QAction(QIcon('resources/icons/arrow-right.svg'), "Next Page", self)
        next_action.triggered.connect(self.canvas_scene.next_page)
        self.page_toolbar.addAction(next_action)
        # Add Page (no plus.svg fallback)
        add_action = QAction(QIcon(), "Add Page", self)
        add_action.triggered.connect(self.canvas_scene.add_page)
        self.page_toolbar.addAction(add_action)
        del_action = QAction(QIcon('resources/icons/trash.svg'), "Delete Page", self)
        del_action.triggered.connect(self.canvas_scene.remove_current_page)
        self.page_toolbar.addAction(del_action)
        self.addToolBar(Qt.TopToolBarArea, self.page_toolbar)
        # Set initial pen color and update button
        self._update_color_button_style(QColor(Qt.black))
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
    import traceback
    import gc
    import threading
    import time
    sys.excepthook = log_exception
    try:
        app = QApplication(sys.argv)
        window = MainWindow()
        window.showMaximized()
        exit_code = app.exec()
        logger.info("Application exited with code %s", exit_code)
        # Memory cleanup and leak detection
        gc.collect()
        logger.info("Memory usage after exit: %s objects", len(gc.get_objects()))
        sys.exit(exit_code)
    except Exception as e:
        logger.critical("Fatal error in main loop", exc_info=True)
        # Optionally, show user-friendly message
        try:
            from PySide6.QtWidgets import QMessageBox
            QMessageBox.critical(None, "Fatal Error", f"A fatal error occurred: {e}\nSee log for details.")
        except Exception:
            pass
        sys.exit(1)

if __name__ == "__main__":
    main()