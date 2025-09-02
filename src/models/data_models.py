import uuid
from PySide6.QtCore import QObject, Signal, Property

class FolderModel(QObject):
    name_changed = Signal()
    child_added = Signal(object)
    child_removed = Signal(object)

    def __init__(self, name='Untitled', parent_id=None):
        super().__init__()
        self._id = uuid.uuid4()
        self._name = name
        self._parent_id = parent_id
        self._children_folders = []
        self._notes = []

    @Property(str, notify=name_changed)
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        if self._name != value:
            self._name = value
            self.name_changed.emit()

    @property
    def id(self):
        return self._id

    @property
    def parent_id(self):
        return self._parent_id

    @property
    def children_folders(self):
        return self._children_folders

    @property
    def notes(self):
        return self._notes

    def add_child_folder(self, folder):
        self._children_folders.append(folder)
        self.child_added.emit(folder)

    def remove_child_folder(self, folder):
        self._children_folders.remove(folder)
        self.child_removed.emit(folder)

    def add_note(self, note):
        self._notes.append(note)
        self.child_added.emit(note)

    def remove_note(self, note):
        self._notes.remove(note)
        self.child_removed.emit(note)

class NoteModel(QObject):
    name_changed = Signal()
    property_changed = Signal(str)

    def __init__(self, name='Untitled', parent_id=None):
        super().__init__()
        self._id = uuid.uuid4()
        self._name = name
        self._parent_id = parent_id
        self._page_size = 'A4'
        self._page_design = 'blank'
        self._page_color = '#FFFFFF'
        self._creation_date = ''
        self._modification_date = ''

    @Property(str, notify=name_changed)
    def name(self):
        return self._name

    @name.setter
    def name(self, value):
        if self._name != value:
            self._name = value
            self.name_changed.emit()

    @property
    def id(self):
        return self._id

    @property
    def parent_id(self):
        return self._parent_id

    @Property(str, notify=property_changed)
    def page_size(self):
        return self._page_size

    @page_size.setter
    def page_size(self, value):
        if self._page_size != value:
            self._page_size = value
            self.property_changed.emit('page_size')

    @Property(str, notify=property_changed)
    def page_design(self):
        return self._page_design

    @page_design.setter
    def page_design(self, value):
        if self._page_design != value:
            self._page_design = value
            self.property_changed.emit('page_design')

    @Property(str, notify=property_changed)
    def page_color(self):
        return self._page_color

    @page_color.setter
    def page_color(self, value):
        if self._page_color != value:
            self._page_color = value
            self.property_changed.emit('page_color')

    @property
    def creation_date(self):
        return self._creation_date

    @property
    def modification_date(self):
        return self._modification_date
