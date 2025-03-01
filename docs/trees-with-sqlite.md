# Trees with SQLite

/// tip
This example is available as a repository in:

  * [RyanGreenup/qml_sqlite_tree_example](https://github.com/RyanGreenup/qml_sqlite_tree_example)

Sections correspond to branches.
///

## Introduction
Here we show how to connect a QML Tree with a file. SQLite is used because it's typically the correct choice and working with trees in a relational database is a bit trickier than mere files, hence it serves as a good exemplar

## Create an Initial Application ( `read_sqlite`)
### Overview

First we create an initial GUI with SQLite, this will store some notes in a SQLite database in a hierarchical fashion where Subnotes < Notes < Folders.

### Main

Because the TreeModel will hold a database connection, it must now be passed in as a property not a type:

``` python
# Create the model and expose it to QML
tree_model = TreeModel(tree_data)
engine.rootContext().setContextProperty("treeModel", tree_model)
```

Here our main Function sets up a simple Schema and exposes the treeModel defined below:

```python
import os
import signal
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType, QQmlContext
from PySide6.QtWidgets import QApplication
from tree_model import TreeModel
from key_emitter import KeyEmitter
import sqlite3


def create_sqlite_database(conn: sqlite3.Connection):

    conn.execute('''PRAGMA journal_mode('WAL');''')
    conn.execute('''
    -- Folders table
    CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );''')
    conn.execute('''
    -- Notes table
    CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT,
        folder_id TEXT,
        parent_note_id TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

        -- Foreign key to folders table
        FOREIGN KEY (folder_id)
        REFERENCES folders (id)
        ON DELETE CASCADE,

        -- Foreign key to parent note (self-referencing)
        FOREIGN KEY (parent_note_id)
        REFERENCES notes (id)
        ON DELETE CASCADE
    );
                 ''')

    conn.execute('''
    -- Index for faster lookups
    CREATE INDEX idx_notes_folder_id ON notes (folder_id);
                 ''')

    conn.execute('''
    CREATE INDEX idx_notes_parent_note_id ON notes (parent_note_id);
                 ''')
    conn.commit()

def create_sqlite_data(conn: sqlite3.Connection):
    """Create test data with nested notes structure"""
    cursor = conn.cursor()

    # Clear existing data
    cursor.execute("DELETE FROM notes")
    cursor.execute("DELETE FROM folders")

    # Create a folder
    cursor.execute("INSERT INTO folders (id, name) VALUES (1, 'Test Folder')")

    # Create parent notes
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (1, 'Parent1', 'Parent1 description', 1, NULL)
    """)
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (2, 'Parent2', 'Parent2 description', 1, NULL)
    """)

    # Create child notes under Parent1
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (3, 'Child1', 'Child1 description', 1, 1)
    """)
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (4, 'Child2', 'Child2 description', 1, 1)
    """)

    # Create grandchild note under Child2
    cursor.execute("""
        INSERT INTO notes (id, title, body, folder_id, parent_note_id)
        VALUES (5, 'Grandchild1', 'Grandchild1 description', 1, 4)
    """)

    conn.commit()



def main():
    app = QApplication(sys.argv)
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    engine = QQmlApplicationEngine()

    # Set up the database
    db_path = Path("./exemplar_data.sqlite")
    if os.path.exists(db_path):
        os.remove(db_path)

    # Create a persistent connection to the database
    conn = sqlite3.connect(db_path)
    create_sqlite_database(conn)
    create_sqlite_data(conn)


    # Create the model with database connection and expose it to QML
    tree_model = TreeModel(conn)
    engine.rootContext().setContextProperty("treeModel", tree_model)

    # Create and expose the key emitter
    key_emitter = KeyEmitter()
    engine.rootContext().setContextProperty("keyEmitter", key_emitter)

    qml_file = Path(__file__).parent / "qml" / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()


```
### Model
#### Overview
The necessary methods for the TreeItem are:

- **Imports**
    Well, imports aren't a method but these are what's used below:

    ```python
    import sys
    import sqlite3
    from PySide6.QtCore import (
        QAbstractItemModel,
        QByteArray,
        QModelIndex,
        QObject,
        QPersistentModelIndex,
        Qt,
        Slot,
    )
    from typing import final, override
    from db_handler import Note, Folder, DatabaseHandler
    ```
- **Constructor**

    ``` python
    @final
    class TreeModel(QAbstractItemModel):
        def __init__(
            self, db_connection: sqlite3.Connection, parent: QObject | None = None
        ):
            super().__init__(parent)

            # Create database handler
            self.db_handler = DatabaseHandler(db_connection)

            # Create a dummy root item
            self.root_item = Folder(id="0", title="Root", parent=None)

            # Get folders with notes and set them as children of root
            self.tree_data: list[Folder] = self.db_handler.get_folders_with_notes()

            # Connect folders to the root item
            for folder in self.tree_data:
                folder.parent = self.root_item

            # Set the folders as children of the root item
            self.root_item.children = self.tree_data

    ```

- `ColumnCount`
    The column count provides the number of columns a given row may request. This may depend on the parent in some way and so that is provided as a parameter that can be used in the override
    ```python
    @override
    def columnCount(
        self, parent: QModelIndex | QPersistentModelIndex = QModelIndex() # pyright: ignore [reportCallInDefaultInitializer]
    ):
    ```


3. **Index Management: `index`**

    The `index` method is used to create and return the index for the specified row and column under the parent index.

    ```python
    @override
    def index(
        self,
        row: int,
        column: int,
        parent: QModelIndex | QPersistentModelIndex = QModelIndex(),  # pyright: ignore [reportCallInDefaultInitializer]
    ) -> QModelIndex:

    @override
    def parent(self, index: QModelIndex | QPersistentModelIndex):
    ```
3. **Index Management: `parent`**:
    The `parent` method, conversely to `index()`, returns the parent index for a given index, which helps in establishing the hierarchical structure.

    ```python
    @override
    def parent(self, index: QModelIndex | QPersistentModelIndex):
    ```

4. **Row Count:**

    This method determines the number of children a particular parent node has, effectively denoting the number of rows under a node.

    ```python
    @override
    def rowCount(self, parent: QModelIndex | QPersistentModelIndex = QModelIndex()):
    ```

5. **Data Retrieval:**

    The `data` method fetches the data to be displayed for each index, depending on the role.

    ```python
    @override
    def data(
        self,
        index: QModelIndex | QPersistentModelIndex,
        role: int = int(Qt.ItemDataRole.DisplayRole)
    ):
    ```

6. **Flags:**

    The `flags` method tells the view what kinds of operations can be performed on each item, like whether it can be selected or edited.

    ```python
    @override
    def flags(self, index: QModelIndex | QPersistentModelIndex):
        if not index.isValid():
            return Qt.ItemFlag.NoItemFlags
        return (
            Qt.ItemFlag.ItemIsEnabled
            | Qt.ItemFlag.ItemIsSelectable
            | Qt.ItemFlag.ItemIsEditable
        )
    ```

7. **Header Data:**

    This method provides header names for the columns.

    ```python
    @override
    def headerData(
        self,
        section: int,
        orientation: Qt.Orientation,
        role: int = int(Qt.ItemDataRole.DisplayRole)
    ):
        if orientation == Qt.Orientation.Horizontal and role == Qt.ItemDataRole.DisplayRole:
            if section == 0:
                return "Title"
        return None
    ```

8. **Role Names:**

    The `roleNames` method is used to define custom role names, making them recognisable in the model.

    ```python
    @override
    def roleNames(self):
        roles = {
            Qt.ItemDataRole.DisplayRole: QByteArray(b"display"),
            Qt.ItemDataRole.UserRole: QByteArray(b"userData"),
            Qt.ItemDataRole.EditRole: QByteArray(b"edit"),
        }
        return roles
    ```
#### Example

For this example, consider the following classes:

```python
from __future__ import annotations
import sqlite3
from datetime import datetime
from typing import final


@final
class Note:
    def __init__(
        self,
        id: str,
        title: str,
        body: str,
        folder_id: str,
        parent: Note | Folder | None = None,
        created_at: datetime | None = None,
        updated_at: datetime | None = None,
    ):
        self.id = id
        self.title = title
        self.body = body
        self.folder_id = folder_id
        self.parent = parent
        self.children: list["Note"] = []
        # If no timestamps are provided, set them to the current time
        self.created_at = created_at if created_at else datetime.now()
        self.updated_at = updated_at if updated_at else datetime.now()


@final
class Folder:
    def __init__(
        self,
        id: str,
        title: str,
        parent: Folder | None,
        created_at: datetime | None = None,
        updated_at: datetime | None = None,
    ):
        self.id = id
        self.title = title
        self.children: list[Folder | Note] = []
        self.parent = parent
        # If no timestamps are provided, set them to the current time
        self.created_at = created_at if created_at else datetime.now()
        self.updated_at = updated_at if updated_at else datetime.now()
```

Note that this classes store a reference to the children and parent of an item in the tree. This is required for the TreeModel and allows it to build the tree efficiently. I have tried and failed to build a tree efficiently with QT Widgets, you're better of using a Model and calling it a day. See generally [^1740816397] [^1740816424]  [^1740816431].

[^1740816431]: [Qt Core 6.8.2](https://doc.qt.io/qt-6/qtcore-index.html)

[^1740816424]: [PySide6.QtCore.QAbstractItemModel - Qt for Python](https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractItemModel.html#PySide6.QtCore.QAbstractItemModel.parent)

[^1740816397]: [TreeView QML Type | Qt Quick 6.8.2](https://doc.qt.io/qt-6/qml-qtquick-treeview.html)

We'll implement the logic to get this out of the database shortly, for now assume the following is already implemented:

```python
# Create database handler
self.db_handler = DatabaseHandler(db_connection)
# Get folders with notes and set them as children of root
self.tree_data: list[Folder] = self.db_handler.get_folders_with_notes()
```


Putting these together gives:

```python

import sys
import sqlite3
from PySide6.QtCore import (
    QAbstractItemModel,
    QByteArray,
    QModelIndex,
    QObject,
    QPersistentModelIndex,
    Qt,
    Slot,
)
from typing import final, override
from db_handler import Note, Folder, DatabaseHandler


@final
class TreeModel(QAbstractItemModel):
    def __init__(
        self, db_connection: sqlite3.Connection, parent: QObject | None = None
    ):
        super().__init__(parent)

        # Create database handler
        self.db_handler = DatabaseHandler(db_connection)

        # Create a dummy root item
        self.root_item = Folder(id="0", title="Root", parent=None)

        # Get folders with notes and set them as children of root
        self.tree_data: list[Folder] = self.db_handler.get_folders_with_notes()

        # Connect folders to the root item
        for folder in self.tree_data:
            folder.parent = self.root_item

        # Set the folders as children of the root item
        self.root_item.children = self.tree_data  # pyright: ignore [reportAttributeAccessIssue]

    @override
    def columnCount(
        self, parent: QModelIndex | QPersistentModelIndex = QModelIndex() # pyright: ignore [reportCallInDefaultInitializer]
    ):
        fixed_columns = 1
        if parent.isValid():
            # Assuming the parent has a .columnCount() method we could use
            # We may want to match
            # parent_item = self._get_item(parent)
            # return parent_item.columnCount()
            return fixed_columns

        # Change this if you want more columns
        return fixed_columns

    def _get_item(self, index: QModelIndex | QPersistentModelIndex) -> Folder | Note:
        untyped_item = index.internalPointer()  # pyright: ignore[reportAny]
        if not (isinstance(untyped_item, Folder) or isinstance(untyped_item, Note)):
            print("Error, Item in Tree has wrong type, this is a bug!", file=sys.stderr)
        item: Folder | Note = untyped_item
        return item

    @override
    def data(
        self,
        index: QModelIndex | QPersistentModelIndex,
        role: int = int(
            Qt.ItemDataRole.DisplayRole
        ),  # pyright: ignore [reportCallInDefaultInitializer]
    ):
        if not index.isValid():
            return None

        if (
            role != Qt.ItemDataRole.DisplayRole
            and role != Qt.ItemDataRole.UserRole
            and role != Qt.ItemDataRole.EditRole
        ):
            return None

        column: int = index.column()
        row: int = index.row()
        _ = row
        item = self._get_item(index)

        match column:
            case 0:
                return item.title
            case 1:
                return item.id
            case _:
                return None

    @override
    def flags(self, index: QModelIndex | QPersistentModelIndex):
        if not index.isValid():
            return Qt.ItemFlag.NoItemFlags

        return (
            Qt.ItemFlag.ItemIsEnabled
            | Qt.ItemFlag.ItemIsSelectable
            | Qt.ItemFlag.ItemIsEditable
        )

    # Section is the column
    @override
    def headerData(
        self,
        section: int,
        orientation: Qt.Orientation,
        role: int = int(Qt.ItemDataRole.DisplayRole),  # pyright: ignore [reportCallInDefaultInitializer]
    ):
        if (
            orientation == Qt.Orientation.Horizontal
            and role == Qt.ItemDataRole.DisplayRole
        ):
            match section:
                case 0:
                    return "Title"
                case _:
                    return None

        return None

    @override
    def index(
        self,
        row: int,
        column: int,
        parent: QModelIndex | QPersistentModelIndex = QModelIndex(),  # pyright: ignore [reportCallInDefaultInitializer]
    ) -> QModelIndex:
        if not self.hasIndex(row, column, parent):
            return QModelIndex()

        # Return the Root Item or the parent of the current item
        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = self._get_item(parent)

        # Get the children of the parent
        child_items = parent_item.children
        # Get the Specific child item
        child_item = child_items[row]
        # Create an index from that child item
        child_index = self.createIndex(row, column, child_item)

        # Return that index
        return child_index

    @override
    def parent(self, index: QModelIndex | QPersistentModelIndex):  # pyright: ignore [reportIncompatibleMethodOverride]
        # Note the ignore is likely a stubs error, docs suggests this is correct
        # https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractItemModel.html#PySide6.QtCore.QAbstractItemModel.parent
        if not index.isValid():
            return QModelIndex()

        child_item: Folder | Note = self._get_item(index)
        parent_item = child_item.parent

        if parent_item is None or parent_item == self.root_item:
            return QModelIndex()

        # Find the row of the parent in its parent's children
        if parent_item.parent is not None:
            parent_parent = parent_item.parent
            row = parent_parent.children.index(parent_item)  # pyright: ignore [reportArgumentType]
        else:
            # This should not happen with our structure, but just in case
            row = 0

        return self.createIndex(row, 0, parent_item)

    @override
    def rowCount(self,
                 parent: QModelIndex | QPersistentModelIndex = QModelIndex()  # pyright: ignore [reportCallInDefaultInitializer]
                 ):
        if parent.column() > 0:
            return 0

        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = self._get_item(parent)

        return len(parent_item.children)

    @override
    def roleNames(self):
        roles = {
            Qt.ItemDataRole.DisplayRole: QByteArray(b"display"),
            Qt.ItemDataRole.UserRole: QByteArray(b"userData"),
            Qt.ItemDataRole.EditRole: QByteArray(b"edit"),
        }
        r: dict[int, QByteArray] = roles  # pyright: ignore [reportAssignmentType]
        return r
```
### Database Handler

The database handler is a little naive. It would likely be more efficient to use a closure table in order to start with the root level items first, see generally [^1740816699].

[^1740816699]: [Hierarchical Data in SQL: The Ultimate Guide - Database Star](https://www.databasestar.com/hierarchical-data-sql/#Which_Method_Should_I_Use)

```python
@final
class DatabaseHandler:
    def __init__(self, connection: sqlite3.Connection):
        self.connection = connection
        self.cursor = connection.cursor()

    def get_notes_recursive(
        self, parent_id: str | None = None, parent: Note | Folder | None = None
    ) -> list[Note]:
        """
        Recursively get notes in a nested structure

        Args:
            parent_id: ID of the parent note (None for top-level notes)
            parent: Parent Note or Folder object

        Returns:
            List of Note objects with their children
        """
        # Get notes with the specified parent_id
        if parent_id is None:
            _ = self.cursor.execute(
                "SELECT id, title, body, folder_id FROM notes WHERE parent_note_id IS NULL"
            )
        else:
            _ = self.cursor.execute(
                "SELECT id, title, body, folder_id FROM notes WHERE parent_note_id = ?",
                (parent_id,),
            )

        result: list[Note] = []
        for row in self.cursor.fetchall():  # pyright: ignore[reportAny]
            note_id: str
            title: str
            folder_id: str
            body: str
            note_id, title, body, folder_id = row

            # Create a Note object
            note = Note(
                id=note_id, title=title, body=body, folder_id=folder_id, parent=parent
            )

            # Check if this note has children
            _ = self.cursor.execute(
                "SELECT COUNT(*) FROM notes WHERE parent_note_id = ?", (note_id,)
            )
            has_children: bool = self.cursor.fetchone()[0] > 0

            if has_children:
                # Get children recursively and attach them to the note
                note.children = self.get_notes_recursive(note_id, note)
                result.append(note)
            else:
                result.append(note)

        return result

    def get_folders_with_notes(self) -> list[Folder]:
        """
        Get all folders with their notes

        Returns:
            List of Folder objects with their notes
        """
        # Get all folders
        _ = self.cursor.execute("SELECT id, name FROM folders")

        result: list[Folder] = []
        for row in self.cursor.fetchall():  # pyright: ignore[reportAny]
            folder_id: str
            title: str
            folder_id, title = row

            # Create a Folder object
            folder = Folder(id=folder_id, title=title, parent=None)

            # Get top-level notes in this folder
            folder.children = []
            _ = self.cursor.execute(
                "SELECT id, title, body  FROM notes WHERE folder_id = ? AND parent_note_id IS NULL",
                (folder_id,),
            )

            for note_row in self.cursor.fetchall():  # pyright: ignore[reportAny]
                note_id: str
                body: str
                note_id, title, body = note_row

                # Create a Note object
                note = Note(
                    id=note_id,
                    title=title,
                    body=body,
                    folder_id=folder_id,
                    parent=folder,
                )

                # Check if this note has children
                _ = self.cursor.execute(
                    "SELECT COUNT(*) FROM notes WHERE parent_note_id = ?", (note_id,)
                )
                has_children: bool = self.cursor.fetchone()[0] > 0

                if has_children:
                    # Get children recursively
                    note.children = self.get_notes_recursive(note_id, note)

                folder.children.append(note)

            result.append(folder)

        return result
```
### QML
#### Overview
This is a simple application that displays a note tree and the corresponding content. Nothing is connected yet as we'll do that next.

Any components declared here will not be repeated, it's assumed they have been moved into separate files.
#### Code

```qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

ApplicationWindow {
    id: root
    // Custom handle component for SplitView
    width: 640
    height: 480
    visible: true
    title: "Animated Rectangle Demo"
    property int border_width

    // Menu with a delegate to show Keyboard Shortcuts
    component MenuWithKbd: Menu {
        id: my_menu
        delegate: MenuItem {
            id: control

            contentItem: Item {
                anchors.centerIn: parent

                function transformString(inputString) {
                    // Find the index of '&' in the input string
                    const ampIndex = inputString.indexOf('&');

                    if (ampIndex !== -1 && ampIndex + 1 < inputString.length) {
                        // Get the character following '&'
                        const charToUnderline = inputString.charAt(ampIndex + 1);

                        // Construct the new string with the character underlined
                        const transformedString = inputString.slice(0, ampIndex) + `<u>${charToUnderline}</u>` + inputString.slice(ampIndex + 2);

                        return transformedString;
                    }

                    // Return the original string if no '&' is present
                    return inputString;
                }

                Text {
                    text: transformString(control.text)
                    // text: "My <u>S</u>tring"
                    anchors.left: parent.left
                    // color: "white"
                }

                Text {
                    text: control.action.shortcut
                    anchors.right: parent.right
                    // color: "white"
                }
            }
        }
    }

    // Menu Bar
    menuBar: MenuBar {
        id: menuBar
        MenuWithKbd {
            id: contextMenu
            title: "&Help"

            Action {
                text: "&Usage guide"
                shortcut: "F1"
                onTriggered: console.log("Usage Guide")
            }
        }
        MenuWithKbd {
            id: menuEdit
            title: qsTr("&Edit")
            Action {
                text: qsTr("&Undo")
                shortcut: "Ctrl+U"
                onTriggered: console.log("Undo Triggered")
            }
        }
    }

    // Tree Delegate to display Tree Items
    component MyTreeDelegate: Item {
        id: tree_delegate
        implicitWidth: padding + label.x + label.implicitWidth + padding
        implicitHeight: label.implicitHeight * 1.5

        readonly property real indentation: 20
        readonly property real padding: 5

        // Assigned to by TreeView:
        required property TreeView treeView
        required property bool isTreeNode
        required property bool expanded
        required property bool hasChildren
        required property int depth
        required property int row
        required property int column
        required property bool current
        required property string display

        // Rotate indicator when expanded by the user
        // (requires TreeView to have a selectionModel)
        property Animation indicatorAnimation: NumberAnimation {
            target: indicator
            property: "rotation"
            from: tree_delegate.expanded ? 0 : 90
            to: tree_delegate.expanded ? 90 : 0
            duration: 200
            easing.type: Easing.OutQuart
        }
        TableView.onPooled: indicatorAnimation.complete()
        TableView.onReused: if (current)
            indicatorAnimation.start()
        onExpandedChanged: indicator.rotation = expanded ? 90 : 0

        function is_current_item() {
            return tree_delegate.row === tree_delegate.treeView.currentRow;
        }

        // Handle right-click to show context menu
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: function (eventPoint) {
                // tree_delegate.treeView.currentRow = tree_delegate.row;
                contextMenu.x = eventPoint.position.x;
                contextMenu.y = eventPoint.position.y;
                contextMenu.open();
            }
        }

        function item_opacity() {
            if (tree_delegate.is_current_item()) {
                return 1;
            }
            if (tree_delegate.treeView.alternatingRows && tree_delegate.row % 2 !== 0) {
                return 0.1;
            } else {
                return 0;
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: tree_delegate.is_current_item() ? palette.highlight : Universal.accent
            opacity: tree_delegate.item_opacity()
        }

        Label {
            id: indicator
            x: padding + (tree_delegate.depth * tree_delegate.indentation)
            anchors.verticalCenter: parent.verticalCenter
            visible: tree_delegate.isTreeNode && tree_delegate.hasChildren
            text: ""

            TapHandler {
                onSingleTapped: {
                    let index = tree_delegate.treeView.index(tree_delegate.row, tree_delegate.column);
                    tree_delegate.treeView.selectionModel.setCurrentIndex(index, ItemSelectionModel.NoUpdate);
                    tree_delegate.treeView.toggleExpanded(tree_delegate.row);
                }
            }
        }

        Label {
            id: label
            x: padding + (tree_delegate.isTreeNode ? (tree_delegate.depth + 1) * tree_delegate.indentation : 0)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - padding - x
            clip: true
            text: tree_delegate.display // model.display works but qmlls doesn't like it.
            font.pointSize: tree_delegate.is_current_item() ? 12 : 10

            // Animate font size changes
            Behavior on font.pointSize {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }
        }

        // Context menu for tree items
        MenuWithKbd {
            id: contextMenu

            Action {
                text: qsTr("&Expand")
                enabled: tree_delegate.isTreeNode && tree_delegate.hasChildren && !tree_delegate.expanded
                onTriggered: {
                    let index = tree_delegate.treeView.index(tree_delegate.row, tree_delegate.column);
                    tree_delegate.treeView.expand(tree_delegate.row);
                }
            }

            Action {
                text: qsTr("C&ollapse")
                enabled: tree_delegate.isTreeNode && tree_delegate.hasChildren && tree_delegate.expanded
                onTriggered: {
                    let index = tree_delegate.treeView.index(tree_delegate.row, tree_delegate.column);
                    tree_delegate.treeView.collapse(tree_delegate.row);
                }
            }

            MenuSeparator {}

            Action {
                text: qsTr("&Copy Text")
                onTriggered: {}
                shortcut: "C"
            }

        }
    }

    // Tree View to display Notes with some Default Keybindings
    component MyTreeView: TreeView {
        id: treeView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        // Signal to emit when the current item changes
        signal currentItemChanged(string statistics)

        // NOTE the getNoteBody function is not yet implemented.
        selectionModel: ItemSelectionModel {
            onCurrentChanged: {
                console.log("Current Item: {Row: " + row + ", Column: " + column + "}")
                // When current index changes, emit the signal with item statistics
                if (currentIndex.row >= 0) {
                    let stats = treeModel.getNoteBody(currentIndex.row, currentIndex.column);
                    treeView.currentItemChanged(stats);
                }
            }
        }

        // Connect to our Python model
        model: treeModel

        delegate: MyTreeDelegate {}

        // Connect to the KeyEmitter when the component is created
        Component.onCompleted: {
            keyEmitter.setView(treeView);
        }

        // Add keyboard shortcuts
        Keys.onPressed: function (event) {
            // 'j' key to move down (like Down arrow)
            if (event.key === Qt.Key_J) {
                // Use the KeyEmitter to simulate a Down key press
                keyEmitter.emitDownKey();
                event.accepted = true;
            } else
            // 'k' key to move up (like Up arrow)
            if (event.key === Qt.Key_K) {
                keyEmitter.emitUpKey();
                event.accepted = true;
            } else
            // 'h' key to collapse/move left
            if (event.key === Qt.Key_H) {
                keyEmitter.emitLeftKey();
                event.accepted = true;
            } else
            // 'l' key to expand/move right
            if (event.key === Qt.Key_L) {
                keyEmitter.emitRightKey();
                event.accepted = true;
            }
        }
    }


    // The Main View
    SplitView {
        orientation: Qt.Horizontal
        anchors.fill: parent
        Rectangle {
            id: rect_1
            SplitView.preferredWidth: parent.width * 0.39
            color: Universal.background
            border.color: Universal.accent

            // Make sure to only focus treeView
            border.width: treeView.activeFocus ? 10 : 0
            focus: false
            activeFocusOnTab: false

            MyTreeView {
                id: treeView
                anchors.fill: parent
                topMargin: root.border_width + 2
                leftMargin: root.border_width + 2

                // Connect to the signal to log statistics when item changes
                onCurrentItemChanged: function (note_body) {
                    console.log("Current item changed. Statistics:", note_body);
                }
            }
        }

        Rectangle {
            id: detailsRect
            SplitView.preferredWidth: parent.width * 0.61
            color: Universal.background

            // Allow Focus
            focus: true
            activeFocusOnTab: true
            border.width: activeFocus ? 10 : 0
            border.color: Universal.accent

            // Display area for the current Note
            Rectangle {
                anchors.centerIn: parent
                anchors.margins: 10

                Label {
                    text: "TODO Note Content"
                    font.bold: true
                    font.pointSize: 12
                }
            }
        }
    }
}
```

## Displaying Note Content With Signals
Currently the application does nothing, next we need to emit a signal that contains the note content.

### Create a Slot
#### TreeView
In the Treeview the SelectionModel has the `onCurrentChanged` field [^1740820703]

[^1740820703]: In fact, The treeView itself emits a `CurrentChanged` signal that the `ItemSelectionModel` is automatically connected to when assigned to the `selectionModel` field. We are emitting a new signal when we recieve that. This is another example of how QML differs from QTWidgets, it pushes you to create more signals and slots and helps limit dereferencing indicies that may not exist.

```qml
    selectionModel: ItemSelectionModel {
        onCurrentChanged: function(current, previous) {
            // `current` is expected to be of type QModelIndex
            if (current.valid) {
                // Get details from the model and emit the signal
                let details = treeModel.getItemDetails(current);
                treeView.currentItemChanged(details);
            }
        }
    }
```
Here we know the index, so in the TreeModel we need to create a slot that takes in the QModelIndex and returns a string `@Slot(QModelIndex, result=str)`, in this case:

```python
@Slot(QModelIndex, result=str)
def getItemDetails(self, index: QModelIndex) -> str:
    """Get details for the selected item (note body or folder info)"""
    if not index.isValid():
        return "No item selected"

    item = self._get_item(index)
    if item is None:
        return "Invalid item"

    if isinstance(item, Note):
        return item.body
    elif isinstance(item, Folder):
        # For folders, return some basic info
        child_count = len(item.children)
        return f"Folder: {item.title}\nContains {child_count} items"
    else:
        return "Unknown item type"
```

Now the second rectangle can be improved to display the content and respond to that signal:

```qml
Rectangle {
    id: detailsRect
    SplitView.preferredWidth: parent.width * 0.61
    color: Universal.background

    // Allow Focus
    focus: true
    activeFocusOnTab: true
    border.width: activeFocus ? 10 : 0
    border.color: Universal.accent

    // Display area for the current item statistics
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10

        Label {
            text: "TODO Note Title"
            font.bold: true
            font.pointSize: 12
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextArea {
                id: noteBody
                readOnly: true
                wrapMode: TextEdit.Wrap
                text: "Select an item in the tree to view statistics"

                background: Rectangle {
                    color: Universal.background
                    border.color: Universal.accent
                    border.width: 1
                    radius: 4
                }
            }
        }
    }

    // Connect to the tree view's signal
    Connections {
        target: treeView
        /**
         * Updates the text of the noteBody element with the provided note body text.
         *
         * @param {string} note_body_text - The text to be set as the note body.
         */
        function onCurrentItemChanged(note_body) {
            noteBody.text = note_body;
        }
    }
}
```

So overall the `main.qml` would be:


```qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts

ApplicationWindow {
    id: root
    // Custom handle component for SplitView
    width: 640
    height: 480
    visible: true
    title: "Animated Rectangle Demo"
    property int border_width
    property bool dark_mode
    Universal.theme: root.dark_mode ? Universal.Dark : Universal.Light

    // Menu Bar
    menuBar: AppMenu {}

    // The Main View
    SplitView {
        orientation: Qt.Horizontal
        anchors.fill: parent
        Rectangle {
            id: rect_1
            SplitView.preferredWidth: parent.width * 0.39
            color: Universal.background
            border.color: Universal.accent

            // Make sure to only focus treeView
            border.width: treeView.activeFocus ? 10 : 0
            focus: false
            activeFocusOnTab: false

            MyTreeView {
                id: treeView
                anchors.fill: parent
                topMargin: root.border_width + 2
                leftMargin: root.border_width + 2

                // Connect to the signal to log statistics when item changes
                onCurrentItemChanged: function (note_body) {
                    console.log("Current item changed. Statistics:", note_body);
                }
            }
        }

        Rectangle {
            id: detailsRect
            SplitView.preferredWidth: parent.width * 0.61
            color: Universal.background

            // Allow Focus
            focus: true
            activeFocusOnTab: true
            border.width: activeFocus ? 10 : 0
            border.color: Universal.accent

            // Display area for the current item statistics
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10

                Label {
                    text: "TODO Note Title"
                    font.bold: true
                    font.pointSize: 12
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        id: noteBody
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        text: "Select an item in the tree to view statistics"

                        background: Rectangle {
                            color: Universal.background
                            border.color: Universal.accent
                            border.width: 1
                            radius: 4
                        }
                    }
                }
            }

            // Connect to the tree view's signal
            Connections {
                target: treeView
                /**
                 * Updates the text of the noteBody element with the provided note body text.
                 *
                 * @param {string} note_body_text - The text to be set as the note body.
                 */
                function onCurrentItemChanged(note_body) {
                    noteBody.text = note_body;
                }
            }
        }
    }
}
```

See the full code on the `read_sqlite` branch of the git repository which corresponds to the code this far.





## Connecting to a File (Sqlite)
### Create a File
### Read an Existing File
### Update an Existing File
#### Create new Nodes
#### Rename Nodes
#### Move Nodes
#### Delete Nodes
