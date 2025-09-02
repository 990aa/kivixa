import os
import json
import uuid
from utils.logging_utils import logger
from PySide6.QtCore import QObject, QStandardPaths, QDir
from models.data_models import FolderModel, NoteModel

class ProjectManager(QObject):
    _instance = None
    DATA_FILE_NAME = "kivixa_data.json"

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(ProjectManager, cls).__new__(cls)
            cls._instance._initialized = False
        return cls._instance

    def __init__(self):
        if self._initialized:
            return
        super().__init__()
        self._root_folder = None
        app_data_path = QStandardPaths.writableLocation(QStandardPaths.AppDataLocation)
        self._save_path = os.path.join(app_data_path, 'kivixa', self.DATA_FILE_NAME)
        try:
            QDir().mkpath(os.path.dirname(self._save_path))
        except Exception as e:
            logger.error(f"Failed to create data directory: {e}")
        try:
            self.load()
        except Exception as e:
            logger.error(f"Failed to load project data: {e}", exc_info=True)
            self._show_file_error(f"Could not load project data: {e}")
            self._root_folder = FolderModel(name='Root')
        self._initialized = True

    def _model_to_dict(self, item):
        if isinstance(item, FolderModel):
            return {
                'type': 'folder',
                'id': str(item.id),
                'name': item.name,
                'parent_id': str(item.parent_id) if item.parent_id else None,
                'children_folders': [self._model_to_dict(child) for child in item.children_folders],
                'notes': [self._model_to_dict(note) for note in item.notes]
            }
        elif isinstance(item, NoteModel):
            return {
                'type': 'note',
                'id': str(item.id),
                'name': item.name,
                'parent_id': str(item.parent_id),
                'page_size': item.page_size,
                'page_design': item.page_design,
                'page_color': item.page_color,
                'creation_date': item.creation_date,
                'modification_date': item.modification_date
            }
        return None

    def _dict_to_model(self, data, parent_id=None):
        if not data:
            return None
        item_type = data.get('type')
        if item_type == 'folder':
            folder = FolderModel(name=data['name'], parent_id=uuid.UUID(data['parent_id']) if data['parent_id'] else None)
            folder._id = uuid.UUID(data['id'])
            for child_data in data.get('children_folders', []):
                folder.add_child_folder(self._dict_to_model(child_data, folder.id))
            for note_data in data.get('notes', []):
                folder.add_note(self._dict_to_model(note_data, folder.id))
            return folder
        elif item_type == 'note':
            note = NoteModel(name=data['name'], parent_id=uuid.UUID(data['parent_id']))
            note._id = uuid.UUID(data['id'])
            note._page_size = data['page_size']
            note._page_design = data['page_design']
            note._page_color = data['page_color']
            note._creation_date = data['creation_date']
            note._modification_date = data['modification_date']
            return note
        return None

    def load(self):
        """Loads the project data from the JSON file."""
        try:
            if os.path.exists(self._save_path):
                with open(self._save_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    self._root_folder = self._dict_to_model(data)
                    logger.info("Project data loaded successfully.")
            else:
                self._root_folder = FolderModel(name='Root')
                self.save()
        except (FileNotFoundError, json.JSONDecodeError, TypeError) as e:
            logger.error(f"Error loading data: {e}. Starting with a new root folder.")
            self._show_file_error(f"Could not load project data: {e}")
            self._root_folder = FolderModel(name='Root')

    def save(self):
        """Saves the project data to the JSON file."""
        if self._root_folder:
            try:
                data = self._model_to_dict(self._root_folder)
                with open(self._save_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=4)
                logger.info("Project data saved successfully.")
            except (IOError, TypeError) as e:
                logger.error(f"Error saving data: {e}")
                self._show_file_error(f"Could not save project data: {e}")
    def _show_file_error(self, msg):
        try:
            from PySide6.QtWidgets import QMessageBox
            QMessageBox.critical(None, "File Error", msg)
        except Exception:
            logger.error(f"Failed to show file error dialog: {msg}")

    def find_item(self, item_id, folder=None):
        if folder is None:
            folder = self._root_folder

        if str(folder.id) == item_id:
            return folder

        for note in folder.notes:
            if str(note.id) == item_id:
                return note

        for sub_folder in folder.children_folders:
            found = self.find_item(item_id, sub_folder)
            if found:
                return found
        return None

    def get_items_in_folder(self, folder_id):
        if folder_id is None:
            return self._root_folder.children_folders + self._root_folder.notes
        else:
            folder = self.find_item(folder_id)
            if folder and isinstance(folder, FolderModel):
                return folder.children_folders + folder.notes
        return []

    def create_folder(self, name, parent_id=None):
        parent_folder = self.find_item(parent_id) if parent_id else self._root_folder
        if parent_folder and isinstance(parent_folder, FolderModel):
            folder = FolderModel(name=name, parent_id=parent_folder.id)
            parent_folder.add_child_folder(folder)
            self.save()
            return folder
        return None

    def create_note(self, name, parent_id=None, page_size='A4', page_design='Blank', page_color='#FFFFFF'):
        parent_folder = self.find_item(parent_id) if parent_id else self._root_folder
        if parent_folder and isinstance(parent_folder, FolderModel):
            note = NoteModel(name=name, parent_id=parent_folder.id, page_size=page_size, page_design=page_design, page_color=page_color)
            parent_folder.add_note(note)
            self.save()
            return note
        return None

    def delete_item(self, item_id):
        item = self.find_item(item_id)
        if item:
            parent_folder = self.find_item(str(item.parent_id))
            if parent_folder and isinstance(parent_folder, FolderModel):
                if isinstance(item, FolderModel):
                    parent_folder.children_folders.remove(item)
                elif isinstance(item, NoteModel):
                    parent_folder.notes.remove(item)
                self.save()
                return True
        return False

    def rename_item(self, item_id, new_name):
        item = self.find_item(item_id)
        if item:
            item.name = new_name
            self.save()
            return True
        return False

    def duplicate_item(self, item_id):
        item = self.find_item(item_id)
        if not item:
            return None

        parent_folder = self.find_item(str(item.parent_id))
        if not parent_folder or not isinstance(parent_folder, FolderModel):
            return None

        if isinstance(item, NoteModel):
            new_note = NoteModel(
                name=f"{item.name} (Copy)",
                parent_id=item.parent_id,
                page_size=item.page_size,
                page_design=item.page_design,
                page_color=item.page_color
            )
            parent_folder.add_note(new_note)
            self.save()
            return new_note

        if isinstance(item, FolderModel):
            new_folder = self._deep_copy_folder(item, parent_folder.id)
            new_folder.name = f"{item.name} (Copy)"
            parent_folder.add_child_folder(new_folder)
            self.save()
            return new_folder

        return None

    def _deep_copy_folder(self, folder_to_copy, new_parent_id):
        new_folder = FolderModel(name=folder_to_copy.name, parent_id=new_parent_id)

        for note_to_copy in folder_to_copy.notes:
            new_note = NoteModel(
                name=note_to_copy.name,
                parent_id=new_folder.id,
                page_size=note_to_copy.page_size,
                page_design=note_to_copy.page_design,
                page_color=note_to_copy.page_color
            )
            new_folder.add_note(new_note)

        for sub_folder_to_copy in folder_to_copy.children_folders:
            new_sub_folder = self._deep_copy_folder(sub_folder_to_copy, new_folder.id)
            new_folder.add_child_folder(new_sub_folder)

        return new_folder

    def move_item(self, item_id, new_parent_id):
        item = self.find_item(item_id)
        if not item:
            return False

        old_parent_folder = self.find_item(str(item.parent_id))
        new_parent_folder = self.find_item(new_parent_id)

        if not old_parent_folder or not new_parent_folder or not isinstance(old_parent_folder, FolderModel) or not isinstance(new_parent_folder, FolderModel):
            return False

        # Remove from old parent
        if isinstance(item, FolderModel):
            old_parent_folder.children_folders.remove(item)
        elif isinstance(item, NoteModel):
            old_parent_folder.notes.remove(item)

        # Add to new parent
        item._parent_id = new_parent_folder.id
        if isinstance(item, FolderModel):
            new_parent_folder.add_child_folder(item)
        elif isinstance(item, NoteModel):
            new_parent_folder.add_note(item)

        self.save()
        return True

    @property
    def root_folder(self):
        return self._root_folder
