from PySide6.QtWidgets import QDialog, QVBoxLayout, QTreeView, QDialogButtonBox
from PySide6.QtGui import QStandardItemModel, QStandardItem
from models.data_models import FolderModel

class MoveDialog(QDialog):
    def __init__(self, root_folder, item_to_move_id, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Move Item")
        self.tree_view = QTreeView()
        self.model = QStandardItemModel()
        self.tree_view.setModel(self.model)
        self.tree_view.setHeaderHidden(True)

        self.populate_tree(root_folder, self.model.invisibleRootItem(), item_to_move_id)

        self.button_box = QDialogButtonBox(QDialogButtonBox.Ok | QDialogButtonBox.Cancel)
        self.button_box.accepted.connect(self.accept)
        self.button_box.rejected.connect(self.reject)

        layout = QVBoxLayout(self)
        layout.addWidget(self.tree_view)
        layout.addWidget(self.button_box)

    def populate_tree(self, folder, parent_item, item_to_move_id):
        # Don't show the item being moved or its children
        if str(folder.id) == item_to_move_id:
            return

        folder_item = QStandardItem(folder.name)
        folder_item.setData(str(folder.id), Qt.UserRole)
        parent_item.appendRow(folder_item)

        for sub_folder in folder.children_folders:
            self.populate_tree(sub_folder, folder_item, item_to_move_id)

    def get_selected_folder_id(self):
        selected_indexes = self.tree_view.selectedIndexes()
        if selected_indexes:
            return self.model.itemFromIndex(selected_indexes[0]).data(Qt.UserRole)
        return None
