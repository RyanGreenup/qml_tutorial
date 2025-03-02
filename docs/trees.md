# Trees

[TreeView QML Type | Qt Quick 6.8.2](https://doc.qt.io/qt-6/qml-qtquick-treeview.html)

> TreeView is a data bound control, so it cannot show anything without a data model. You cannot declare tree nodes in QML.
>   * **A data model**. TreeView can work with data models that derive from QAbstractItemModel.
>   * A **delegate**. A delegate is a template that specifies how the tree nodes are displayed in the UI.

TODO emit a signal when tree item is clicked

## Read Only
### Basic Example
#### Python Model
```python
from PySide6.QtCore import QAbstractItemModel, QByteArray, QModelIndex, Qt, QPersistentModelIndex, QModelIndex
from typing import override


class TreeItem:
    def __init__(self, data, parent=None):
        self.parent_item = parent
        self.item_data = data
        self.child_items = []

    def appendChild(self, item):
        self.child_items.append(item)

    def child(self, row):
        if row < 0 or row >= len(self.child_items):
            return None
        return self.child_items[row]

    def childCount(self):
        return len(self.child_items)

    def columnCount(self):
        return len(self.item_data)

    def data(self, column):
        if column < 0 or column >= len(self.item_data):
            return None
        return self.item_data[column]

    def row(self):
        if self.parent_item:
            return self.parent_item.child_items.index(self)
        return 0

    def parentItem(self):
        return self.parent_item


class TreeModel(QAbstractItemModel):
    def __init__(self, data, parent=None):
        super().__init__(parent)

        # Create root item
        self.root_item = TreeItem(["Title", "Summary"])
        self.setupModelData(data, self.root_item)

    def columnCount(self, parent=QModelIndex()):
        if parent.isValid():
            return parent.internalPointer().columnCount()
        return self.root_item.columnCount()

    def get_item(self, index: QModelIndex | QPersistentModelIndex) -> TreeItem:
        untyped_item = index.internalPointer()
        if not isinstance(untyped_item, TreeItem):
            print("Error, Item in Tree has wrong type, this is a bug!", file = sys.stderr)
        item: TreeItem = untyped_item
        return item



    def data(self, index: QModelIndex | QPersistentModelIndex, role=int(Qt.ItemDataRole.DisplayRole)):
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
        item = self.get_item(index)
        return item.data(column)

    def flags(self, index):
        if not index.isValid():
            return Qt.ItemFlag.NoItemFlags

        return Qt.ItemFlag.ItemIsEnabled | Qt.ItemFlag.ItemIsSelectable

    def headerData(self, section, orientation, role=Qt.ItemDataRole.DisplayRole):
        if (
            orientation == Qt.Orientation.Horizontal
            and role == Qt.ItemDataRole.DisplayRole
        ):
            return self.root_item.data(section)

        return None

    def index(self, row, column, parent=QModelIndex()):
        if not self.hasIndex(row, column, parent):
            return QModelIndex()

        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = parent.internalPointer()

        child_item = parent_item.child(row)
        if child_item:
            return self.createIndex(row, column, child_item)
        return QModelIndex()

    @override
    def parent(self, index):  # pyright: ignore [reportIncompatibleMethodOverride]
        # Note the ignore is likely a stubs error, docs suggests this is correct
        # https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractItemModel.html#PySide6.QtCore.QAbstractItemModel.parent
        if not index.isValid():
            return QModelIndex()

        child_item = index.internalPointer()
        parent_item = child_item.parentItem()

        if parent_item == self.root_item:
            return QModelIndex()

        return self.createIndex(parent_item.row(), 0, parent_item)

    def rowCount(self, parent=QModelIndex()):
        if parent.column() > 0:
            return 0

        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = parent.internalPointer()

        return parent_item.childCount()

    def roleNames(self):
        roles = {
            Qt.ItemDataRole.DisplayRole: QByteArray(b"display"),
            Qt.ItemDataRole.UserRole: QByteArray(b"userData"),
        }
        r: dict[int, QByteArray] = roles  # pyright: ignore [reportAssignmentType]
        return r

    def setupModelData(self, data, parent):
        # Example data structure:
        # [
        #   ["Parent1", "Parent1 description", [
        #       ["Child1", "Child1 description"],
        #       ["Child2", "Child2 description", [
        #           ["Grandchild1", "Grandchild1 description"]
        #       ]]
        #   ]],
        #   ["Parent2", "Parent2 description"]
        # ]

        for item_data in data:
            if len(item_data) >= 2:
                # Extract the item data (first two elements)
                item_values = item_data[:2]

                # Create the item
                item = TreeItem(item_values, parent)
                parent.appendChild(item)

                # If there are children (third element is a list)
                if len(item_data) > 2 and isinstance(item_data[2], list):
                    self.setupModelData(item_data[2], item)

```

#### Python Main
```python

import signal
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType, QQmlContext
from example_table_model import ExampleTableModel
from treeModel import TreeModel


def main():
    app = QGuiApplication(sys.argv)
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    qml_import_name = "TableManager"
    qmlRegisterType(ExampleTableModel, qml_import_name, 1, 0, "ExampleTableModel")  # pyright: ignore

    # Register the TreeModel
    qmlRegisterType(TreeModel, qml_import_name, 1, 0, "TreeModel")  # pyright: ignore

    engine = QQmlApplicationEngine()

    # Create sample tree data
    tree_data = [
        ["Documents", "User documents", [
            ["Work", "Work-related documents", [
                ["Project A", "Files for Project A"],
                ["Project B", "Files for Project B"]
            ]],
            ["Personal", "Personal documents"]
        ]],
        ["Pictures", "User pictures", [
            ["Vacation", "Vacation photos"],
            ["Family", "Family photos"]
        ]],
        ["Music", "Audio files"]
    ]

    # Create the model and expose it to QML
    tree_model = TreeModel(tree_data)
    engine.rootContext().setContextProperty("treeModel", tree_model)

    qml_file = Path(__file__).parent / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
```

#### QML
##### Basic Example

```qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: root
    // Custom handle component for SplitView
    width: 640
    height: 480
    visible: true
    title: "Animated Rectangle Demo"

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

        Rectangle {
            id: background
            anchors.fill: parent
            color: tree_delegate.row === tree_delegate.treeView.currentRow ? palette.highlight : Material.background
            // opacity: (tree_delegate.treeView.alternatingRows && tree_delegate.row % 2 !== 0) ? 0.3 : 0.1
        }

        Label {
            id: indicator
            x: padding + (tree_delegate.depth * tree_delegate.indentation)
            anchors.verticalCenter: parent.verticalCenter
            visible: tree_delegate.isTreeNode && tree_delegate.hasChildren
            text: tree_delegate.expanded ? "" : ""

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
        }
    }

    component MyTreeView: TreeView {
        id: treeView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        selectionModel: ItemSelectionModel {}

        // Connect to our Python model
        model: treeModel

        delegate: MyTreeDelegate {}
    }

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }

    SplitView {
        orientation: Qt.Horizontal
        anchors.fill: parent
        Rectangle {
            id: rect_1
            SplitView.preferredWidth: parent.width * 0.39
            color: Material.background
            border.color: Material.accent

            // Make sure to only focus treeView
            border.width: treeView.activeFocus ? 10 : 0
            focus: false
            activeFocusOnTab: false

            MyTreeView {
                id: treeView
                topMargin: rect_1.border.width + 2
                leftMargin: rect_1.border.width + 2
            }
        }
        Rectangle {
            SplitView.preferredWidth: parent.width * 0.61
            color: Material.background

            // Allow Focus
            focus: true
            activeFocusOnTab: true
            border.width: activeFocus ? 10 : 0
            border.color: Material.accent
        }
    }
}
```

##### Complex Example
###### Use Animation for Indicators
Rather than using Different Indicator Symbols, We can rotate an indicator symbol with an animation, this way the symbol is the same and is aesthetically pleasing

```qml
        // Rotate indicator when expanded by the user
        // (requires TreeView to have a selectionModel)
        property Animation indicatorAnimation: NumberAnimation {
            target: indicator
            property: "rotation"
            from: tree_delegate.expanded ? 0 : 90
            to: tree_delegate.expanded ? 90 : 0
            duration: 100
            easing.type: Easing.OutQuart
        }
        TableView.onPooled: indicatorAnimation.complete()
        TableView.onReused: if (current)
            indicatorAnimation.start()
        onExpandedChanged: indicator.rotation = expanded ? 90 : 0


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
```
###### Striped Background

```qml

        function is_current_item() {
            return tree_delegate.row === tree_delegate.treeView.currentRow
        }

        function item_opacity() {
            if (tree_delegate.is_current_item()) {
                return 1
            }
            if (tree_delegate.treeView.alternatingRows && tree_delegate.row % 2 !== 0) {
                return 0.1
            } else {
                return 0
            }
        }


        Rectangle {
            id: background
            anchors.fill: parent
            color: tree_delegate.is_current_item() ? palette.highlight : Material.accent
            opacity: tree_delegate.item_opacity()
        }

```
###### Animated Font

```qml
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
```
###### Complete Code
```qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: root
    // Custom handle component for SplitView
    width: 640
    height: 480
    visible: true
    title: "Animated Rectangle Demo"

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
            color: tree_delegate.is_current_item() ? palette.highlight : Material.accent
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
    }

    component MyTreeView: TreeView {
        id: treeView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        selectionModel: ItemSelectionModel {}

        // Connect to our Python model
        model: treeModel

        delegate: MyTreeDelegate {}
    }

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }

    SplitView {
        orientation: Qt.Horizontal
        anchors.fill: parent
        Rectangle {
            id: rect_1
            SplitView.preferredWidth: parent.width * 0.39
            color: Material.background
            border.color: Material.accent

            // Make sure to only focus treeView
            border.width: treeView.activeFocus ? 10 : 0
            focus: false
            activeFocusOnTab: false

            MyTreeView {
                id: treeView
                anchors.fill: parent
                topMargin: rect_1.border.width + 2
                leftMargin: rect_1.border.width + 2
            }
        }
        Rectangle {
            SplitView.preferredWidth: parent.width * 0.61
            color: Material.background

            // Allow Focus
            focus: true
            activeFocusOnTab: true
            border.width: activeFocus ? 10 : 0
            border.color: Material.accent
        }
    }
}
```
## KeyBindings
To map keybindings like Up/Down to J/K it's necessary to implement a key emitter in Python [^1740725726].

```python
from PySide6.QtCore import QObject, Slot, Qt
from PySide6.QtGui import QKeyEvent
from PySide6.QtWidgets import QApplication

class KeyEmitter(QObject):
    """Helper class to emit key events directly to the TreeView"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.view = None

    @Slot("QVariant")
    def setView(self, view):
        """Set the TreeView object that will receive key events"""
        self.view = view

    @Slot()
    def emitDownKey(self):
        """Emit a Down arrow key press to the TreeView"""
        print("Down")
        if self.view:
            key_press = QKeyEvent(
                QKeyEvent.Type.KeyPress, Qt.Key.Key_Down, Qt.KeyboardModifier.NoModifier
            )
            key_release = QKeyEvent(
                QKeyEvent.Type.KeyRelease,
                Qt.Key.Key_Down,
                Qt.KeyboardModifier.NoModifier,
            )

            QApplication.sendEvent(self.view, key_press)
            QApplication.sendEvent(self.view, key_release)

    @Slot()
    def emitUpKey(self):
        """Emit an Up arrow key press to the TreeView"""
        if self.view:
            key_press = QKeyEvent(
                QKeyEvent.Type.KeyPress, Qt.Key.Key_Up, Qt.KeyboardModifier.NoModifier
            )
            key_release = QKeyEvent(
                QKeyEvent.Type.KeyRelease, Qt.Key.Key_Up, Qt.KeyboardModifier.NoModifier
            )

            QApplication.sendEvent(self.view, key_press)
            QApplication.sendEvent(self.view, key_release)

    @Slot()
    def emitLeftKey(self):
        """Emit a Left arrow key press to the TreeView"""
        if self.view:
            key_press = QKeyEvent(
                QKeyEvent.Type.KeyPress, Qt.Key.Key_Left, Qt.KeyboardModifier.NoModifier
            )
            key_release = QKeyEvent(
                QKeyEvent.Type.KeyRelease, Qt.Key.Key_Left, Qt.KeyboardModifier.NoModifier
            )

            QApplication.sendEvent(self.view, key_press)
            QApplication.sendEvent(self.view, key_release)

    @Slot()
    def emitRightKey(self):
        """Emit a Right arrow key press to the TreeView"""
        if self.view:
            key_press = QKeyEvent(
                QKeyEvent.Type.KeyPress, Qt.Key.Key_Right, Qt.KeyboardModifier.NoModifier
            )
            key_release = QKeyEvent(
                QKeyEvent.Type.KeyRelease, Qt.Key.Key_Right, Qt.KeyboardModifier.NoModifier
            )

            QApplication.sendEvent(self.view, key_press)
            QApplication.sendEvent(self.view, key_release)

```


One could go a step further and use a decorator to make the code more DRY:

```python

from PySide6.QtCore import QObject, Slot, Qt
from PySide6.QtGui import QKeyEvent
from PySide6.QtWidgets import QApplication
import functools

def key_emitter(key):
    """Decorator to create key event emitter methods"""
    def decorator(func):
        @functools.wraps(func)
        def wrapper(self, *args, **kwargs):
            # Call the original function first (for any logging, etc.)
            func(self, *args, **kwargs)

            if self.view:
                # Create key press event
                key_press = QKeyEvent(
                    QKeyEvent.Type.KeyPress, key, Qt.KeyboardModifier.NoModifier
                )
                # Create key release event
                key_release = QKeyEvent(
                    QKeyEvent.Type.KeyRelease, key, Qt.KeyboardModifier.NoModifier
                )

                # Send events to the view
                QApplication.sendEvent(self.view, key_press)
                QApplication.sendEvent(self.view, key_release)
        return wrapper
    return decorator

class KeyEmitter(QObject):
    """Helper class to emit key events directly to the TreeView"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.view = None

    @Slot("QVariant")
    def setView(self, view):
        """Set the TreeView object that will receive key events"""
        self.view = view

    @Slot()
    @key_emitter(Qt.Key.Key_Down)
    def emitDownKey(self):
        """Emit a Down arrow key press to the TreeView"""
        print("Down")

    @Slot()
    @key_emitter(Qt.Key.Key_Up)
    def emitUpKey(self):
        """Emit an Up arrow key press to the TreeView"""
        pass

    @Slot()
    @key_emitter(Qt.Key.Key_Left)
    def emitLeftKey(self):
        """Emit a Left arrow key press to the TreeView"""
        pass

    @Slot()
    @key_emitter(Qt.Key.Key_Right)
    def emitRightKey(self):
        """Emit a Right arrow key press to the TreeView"""
        pass
```



See [chapter 1](./creating-a-menu-bar.md):

```python
    # Create the QML Engine
    engine = QQmlApplicationEngine()

    # Create and expose the key emitter
    key_emitter = KeyEmitter()
    engine.rootContext().setContextProperty("keyEmitter", key_emitter)


    # Set the main QML file
    qml_file = Path(__file__).parent / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
```

Then in the Tree View:


```qml
component MyTreeView: TreeView {
        id: treeView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        // property int currentRow: -1

        selectionModel: ItemSelectionModel {}

        // Connect to our Python model
        model: treeModel

        delegate: MyTreeDelegate {}

        // Add keyboard shortcuts
        Keys.onPressed: function (event) {
            // 'j' key to move down (like Down arrow)
            if (event.key === Qt.Key_J) {
                // Use the KeyEmitter to simulate a Down key press
                keyEmitter.emitDownKey();
                event.accepted = true;
            }
        }
    }
```




[^1740725726]: [c++ - How to simulate key pressed event in Qml? - Stack Overflow](https://stackoverflow.com/questions/62047184/how-to-simulate-key-pressed-event-in-qml)

## Context Menu


One can add a context Menu by adding it to the delegate like so:


/// info
Qt5 Allowed assigning a shortcut to the `menuItem` type which would display the key binding in the context menu.

I have not been able to figure this out. It seems the best approach currently is to create a custom delegate as in [pyside6 - How to add shortcut hint in MenuBar items in Qt/QML 6 - Stack Overflow](https://stackoverflow.com/questions/77163715/how-to-add-shortcut-hint-in-menubar-items-in-qt-qml-6) [^1740729047]

///

/// tip
Consider using the `MenuWithKbd` from [Menu With Keyboard Shortcuts](menu-with-keyboard-shortcuts.md)
///

[^1740729047]: [pyside6 - How to add shortcut hint in MenuBar items in Qt/QML 6 - Stack Overflow](https://stackoverflow.com/questions/77163715/how-to-add-shortcut-hint-in-menubar-items-in-qt-qml-6)


```qml
    component MyTreeDelegate: Item {
        id: tree_delegate
        implicitWidth: padding + label.x + label.implicitWidth + padding
        implicitHeight: label.implicitHeight * 1.5

        readonly property real indentation: 20
        /// ...
        /// ...
        /// ...

        // Handle right-click to show context menu
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: function(eventPoint) {
                // tree_delegate.treeView.currentRow = tree_delegate.row;
                contextMenu.x = eventPoint.position.x;
                contextMenu.y = eventPoint.position.y;
                contextMenu.open();
            }
        }

        // Context menu for tree items
        Menu {
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
                onTriggered: {
                    console.log("TODO Figure out hoow to copy text with QML and QT for Cross Platform"
                    }
            }

            Action {
                text: qsTr("&Details")
                shortcut: "?"
                onTriggered:  {
                    // Show details dialog
                    detailsDialog.title = "Item Details";
                    detailsDialog.itemText = tree_delegate.display;
                    detailsDialog.open();
                }
            }
        }

    }
```

If one wants to expose a property of the underlying item in the delegate, they can use a slot. The context Menu is a good place to start playing around with this.


First create a slot in the model:


```python

    @Slot(int, int, result=str)
    def getItemStats(self, row, column):
        """
        Get statistics about the item's text at the given row and column.
        This method is exposed to QML.

        Args:
            row: The row of the item
            column: The column of the item

        Returns:
            A string with statistics about the item
        """
        index = self.index(row, column)
        if not index.isValid():
            return "Invalid index"

        item_text = self.data(index, Qt.ItemDataRole.DisplayRole)
        if not item_text:
            return "No text"

        # Calculate statistics
        char_count = len(item_text)
        word_count = len(item_text.split())

        # Count lines
        line_count = item_text.count('\n') + 1

        # Count alphanumeric characters
        alpha_count = sum(c.isalnum() for c in item_text)

        s = f"Characters: {char_count}\nWords: {word_count}\nLines: {line_count}\nAlphanumeric: {alpha_count}"
        print(s)
        return s
```

I suggest going a step further and creating a getter method to enforce typing:

```python
    def _get_display_role(self, row: int, column: int) -> str:
        # Get the index
        index = self.index(row, column)
        if not index.isValid():
            return "Invalid index"

        # Get the display text
        item_text = self.data(index, Qt.ItemDataRole.DisplayRole)
        if not isinstance(item_text, str):
            print(f"Item at {row=}, {column=} is not a string", file=sys.stderr)

        # Make sure it's a valid string
        item_text_str = "No Text"
        try:
            item_text_str = f"{item_text}"
            if not item_text_str:
                return item_text_str
        except Exception as e:
            print(f"Unable to cast Item at {row=}, {column=} into a string:\n {e}", file=sys.stderr)
            return item_text_str

        # Return the text
        return item_text_str
```


Then access that slot in the delegate:

Actually, I think this could be out of date, I believe now it should be `onCurrentChanged: function(current, previous) {` (see [trees-with-sqlite](./trees-with-sqlite.md) instead)


```qml

            Action {
                text: qsTr("Show &Statistics")
                shortcut: "S"
                onTriggered: {
                    // Get statistics from the model
                    let stats = treeModel.getItemStats(tree_delegate.row, tree_delegate.column);
                    console.log(stats);
                }
            }

```

All together the delegate would look like this:

```qml
ApplicationWindow {
    id: root
    /// ...
    /// ...
    /// ...
    component MyTreeView: TreeView {
        id: treeView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        // property int currentRow: -1

        selectionModel: ItemSelectionModel {}

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

    /// ...
    /// ...
    /// ...
}

```


One could go a step further and create a popup dialog:


```qml
    // Dialog for showing item details
    Dialog {
        id: detailsDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 400
        height: 200
        modal: true

        property string itemText: ""

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10

            Label {
                text: "Selected Item:"
                font.bold: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextArea {
                    text: detailsDialog.itemText
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    background: Rectangle {
                        color: Universal.background
                        border.color: Universal.accent
                        border.width: 1
                        radius: 4
                    }
                }
            }

            Button {
                text: "Close"
                Layout.alignment: Qt.AlignRight
                onClicked: detailsDialog.close()
            }
        }
    }
```




```qml

MenuItem {
    action: Action {
        text: qsTr("Show &Statistics")
        shortcut: "S"
        onTriggered: {
            // Get statistics from the model
            let stats = treeModel.getItemStats(tree_delegate.row, tree_delegate.column);
            console.log(stats);

            // Show statistics dialog
            detailsDialog.title = "Item Statistics";
            detailsDialog.itemText = "Text: " + tree_delegate.display + "\n\n" + stats;
            detailsDialog.open();
        }
    }
}
```


## Signals and Slots

/// info
See Generally [Building an Application | The Qt 6 Book](https://www.qt.io/product/qt6/qml-book/ch19-python-build-app).
///

Now ideally we would use that output to populate the other widget.

### Emitting a signal on Item Change

There are two approaches to modify widgets in response to behaviour:

1. Set the widget state directly in the `onCurrentChanged` function
2. Emit and recieve a signal

Typically 2 is a better approach for the following reasons:

- The code is loosely connected, refactoring won't break anything
- Signals and Slots are async, so the application will remain responsive
    - Setting content directly may cause the application to hang whilst the changes are ocurring. Signals and Slots deal with this in an expected way.

In the TreeView, begin by emitting a signal when the item changes. This should use the `treeModel` to get the item statistics with `getItemStats` like so:

```qml
    component MyTreeView: TreeView {
        id: treeView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        // Signal to emit when the current item changes
        signal currentItemChanged(string statistics)

        // property int currentRow: -1

        selectionModel: ItemSelectionModel {
            onCurrentChanged: {
                // When current index changes, emit the signal with item statistics
                if (currentIndex.row >= 0) {
                    let stats = treeModel.getItemStats(currentIndex.row, currentIndex.column);
                    treeView.currentItemChanged(stats);
                }
            }
        }

        // Connect to our Python model
        model: treeModel

        delegate: MyTreeDelegate {}

```

### Connecting the signal

In the right hand rectangle, connect the signal like so:

```qml

    SplitView {
        orientation: Qt.Horizontal
        anchors.fill: parent
        Rectangle {
            id: rect_1
                /// ...

            MyTreeView {
                id: treeView
                anchors.fill: parent
                /// ...
            }
        }

        Rectangle {
            id: detailsRect
            SplitView.preferredWidth: parent.width * 0.61
            color: Universal.background

            /// ...

            border.color: Universal.accent
            // Connect to the tree view's signal
            Connections {
                target: treeView
                function onCurrentItemChanged(statistics) {
                    console.log(statistics)
                }
            }
        }
    }

```


### Display the signal content

Finally, this can be improved to display a more comprehensive summary:

![](docs/assets/2025-03-01T15:46:55.603925.png)


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
                    text: "Current Item Statistics"
                    font.bold: true
                    font.pointSize: 12
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        id: statsTextArea
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
                function onCurrentItemChanged(statistics) {
                    statsTextArea.text = statistics;
                }
            }
        }
```

### All the Code So far

#### Python
##### Model
```python

import sys
from PySide6.QtCore import QAbstractItemModel, QByteArray, QModelIndex, Qt, Slot
from typing import override
from hash_helper import calculate_hash


class TreeItem:
    def __init__(self, data, parent=None):
        self.parent_item = parent
        self.item_data = data
        self.child_items = []

    def appendChild(self, item):
        self.child_items.append(item)

    def child(self, row):
        if row < 0 or row >= len(self.child_items):
            return None
        return self.child_items[row]

    def childCount(self):
        return len(self.child_items)

    def columnCount(self):
        return len(self.item_data)

    def data(self, column):
        if column < 0 or column >= len(self.item_data):
            return None
        return self.item_data[column]

    def row(self):
        if self.parent_item:
            return self.parent_item.child_items.index(self)
        return 0

    def parentItem(self):
        return self.parent_item


class TreeModel(QAbstractItemModel):
    def __init__(self, data, parent=None):
        super().__init__(parent)

        # Create root item
        self.root_item = TreeItem(["Title", "Summary"])
        self.setupModelData(data, self.root_item)

    def columnCount(self, parent=QModelIndex()):
        if parent.isValid():
            return parent.internalPointer().columnCount()
        return self.root_item.columnCount()

    def data(self, index, role=Qt.ItemDataRole.DisplayRole):
        if not index.isValid():
            return None

        if role != Qt.ItemDataRole.DisplayRole and role != Qt.ItemDataRole.UserRole:
            return None

        item = index.internalPointer()
        return item.data(index.column())

    def flags(self, index):
        if not index.isValid():
            return Qt.ItemFlag.NoItemFlags

        return Qt.ItemFlag.ItemIsEnabled | Qt.ItemFlag.ItemIsSelectable

    def headerData(self, section, orientation, role=Qt.ItemDataRole.DisplayRole):
        if (
            orientation == Qt.Orientation.Horizontal
            and role == Qt.ItemDataRole.DisplayRole
        ):
            return self.root_item.data(section)

        return None

    def index(self, row, column, parent=QModelIndex()) -> QModelIndex:
        if not self.hasIndex(row, column, parent):
            return QModelIndex()

        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = parent.internalPointer()

        child_item = parent_item.child(row)
        if child_item:
            return self.createIndex(row, column, child_item)
        return QModelIndex()

    @override
    def parent(self, index):  # pyright: ignore [reportIncompatibleMethodOverride]
        # Note the ignore is likely a stubs error, docs suggests this is correct
        # https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractItemModel.html#PySide6.QtCore.QAbstractItemModel.parent
        if not index.isValid():
            return QModelIndex()

        child_item = index.internalPointer()
        parent_item = child_item.parentItem()

        if parent_item == self.root_item:
            return QModelIndex()

        return self.createIndex(parent_item.row(), 0, parent_item)

    def rowCount(self, parent=QModelIndex()):
        if parent.column() > 0:
            return 0

        if not parent.isValid():
            parent_item = self.root_item
        else:
            parent_item = parent.internalPointer()

        return parent_item.childCount()

    def roleNames(self):
        roles = {
            Qt.ItemDataRole.DisplayRole: QByteArray(b"display"),
            Qt.ItemDataRole.UserRole: QByteArray(b"userData"),
        }
        r: dict[int, QByteArray] = roles  # pyright: ignore [reportAssignmentType]
        return r

    @Slot(int, int, result=str)
    def getItemHash(self, row, column):
        """
        Calculate the hash of an item's text at the given row and column.
        This method is exposed to QML.

        Args:
            row: The row of the item
            column: The column of the item

        Returns:
            A string representation of the hash
        """
        index = self.index(row, column)
        if not index.isValid():
            return "Invalid index"

        item_text = self.data(index, Qt.ItemDataRole.DisplayRole)
        if not item_text:
            return "No text"

        return calculate_hash(item_text)


    def _get_display_role(self, row: int, column: int) -> str:
        # Get the index
        index = self.index(row, column)
        if not index.isValid():
            return "Invalid index"

        # Get the display text
        item_text = self.data(index, Qt.ItemDataRole.DisplayRole)
        if not isinstance(item_text, str):
            print(f"Item at {row=}, {column=} is not a string", file=sys.stderr)

        # Make sure it's a valid string
        item_text_str = "No Text"
        try:
            item_text_str = f"{item_text}"
            if not item_text_str:
                return item_text_str
        except Exception as e:
            print(f"Unable to cast Item at {row=}, {column=} into a string:\n {e}", file=sys.stderr)
            return item_text_str

        # Return the text
        return item_text_str


    @Slot(int, int, result=str)
    def getItemStats(self, row, column):
        """
        Get statistics about the item's text at the given row and column.
        This method is exposed to QML.

        Args:
            row: The row of the item
            column: The column of the item

        Returns:
            A string with statistics about the item
        """
        index = self.index(row, column)
        if not index.isValid():
            return "Invalid index"

        item_text = self.data(index, Qt.ItemDataRole.DisplayRole)
        if not item_text:
            return "No text"

        # Calculate statistics
        char_count = len(item_text)
        word_count = len(item_text.split())

        # Count lines
        line_count = item_text.count('\n') + 1

        # Count alphanumeric characters
        alpha_count = sum(c.isalnum() for c in item_text)

        s = f"Characters: {char_count}\nWords: {word_count}\nLines: {line_count}\nAlphanumeric: {alpha_count}"
        print(s)
        return s

    def setupModelData(self, data, parent):
        # Example data structure:
        # [
        #   ["Parent1", "Parent1 description", [
        #       ["Child1", "Child1 description"],
        #       ["Child2", "Child2 description", [
        #           ["Grandchild1", "Grandchild1 description"]
        #       ]]
        #   ]],
        #   ["Parent2", "Parent2 description"]
        # ]

        for item_data in data:
            if len(item_data) >= 2:
                # Extract the item data (first two elements)
                item_values = item_data[:2]

                # Create the item
                item = TreeItem(item_values, parent)
                parent.appendChild(item)

                # If there are children (third element is a list)
                if len(item_data) > 2 and isinstance(item_data[2], list):
                    self.setupModelData(item_data[2], item)
```

##### Main

```python

import signal
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType, QQmlContext
from PySide6.QtWidgets import QApplication
from example_table_model import ExampleTableModel
from treeModel import TreeModel
from key_emitter import KeyEmitter


def main():
    # Use QApplication instead of QGuiApplication to support QKeyEvent
    app = QApplication(sys.argv)
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    qml_import_name = "TableManager"
    qmlRegisterType(ExampleTableModel, qml_import_name, 1, 0, "ExampleTableModel")  # pyright: ignore

    # Register the TreeModel
    qmlRegisterType(TreeModel, qml_import_name, 1, 0, "TreeModel")  # pyright: ignore

    engine = QQmlApplicationEngine()

    # Create sample tree data
    tree_data = [
        ["Documents", "User documents", [
            ["Work", "Work-related documents", [
                ["Project A", "Files for Project A"],
                ["Project B", "Files for Project B"]
            ]],
            ["Personal", "Personal documents"]
        ]],
        ["Pictures", "User pictures", [
            ["Vacation", "Vacation photos"],
            ["Family", "Family photos"]
        ]],
        ["Music", "Audio files"]
    ]

    # Create the model and expose it to QML
    tree_model = TreeModel(tree_data)
    engine.rootContext().setContextProperty("treeModel", tree_model)

    # Create and expose the key emitter
    key_emitter = KeyEmitter()
    engine.rootContext().setContextProperty("keyEmitter", key_emitter)

    qml_file = Path(__file__).parent / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
```

#### QML
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

    // Create a component for menu items
    component MenuWithKbd: Menu {
        id: my_menu
        delegate: MenuItem {
            id: control

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

            contentItem: Item {
                anchors.centerIn: parent

                Text {
                    text: transformString(control.text)
                    // text: "My <u>S</u>tring"
                    anchors.left: parent.left
                    color: Universal.foreground
                }

                Text {
                    text: control.action.shortcut
                    anchors.right: parent.right
                    color: Universal.foreground
                }
            }
        }
    }

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

            Action {
                text: qsTr("&Details")
                shortcut: "?"
                onTriggered: {
                    // Show details dialog
                    detailsDialog.title = "Item Details";
                    detailsDialog.itemText = tree_delegate.display;
                    detailsDialog.open();
                }
            }

            Action {
                text: qsTr("Show &Hash")
                shortcut: "H"
                onTriggered: {
                    // Get hash from the model
                    let hash = treeModel.getItemHash(tree_delegate.row, tree_delegate.column);

                    // Show hash dialog
                    detailsDialog.title = "Item Hash";
                    detailsDialog.itemText = "Text: " + tree_delegate.display + "\n\nHash (SHA-256): " + hash;
                    detailsDialog.open();
                }
            }

            MenuItem {
                action: Action {
                    text: qsTr("Show &Statistics")
                    shortcut: "S"
                    onTriggered: {
                        // Get statistics from the model
                        let stats = treeModel.getItemStats(tree_delegate.row, tree_delegate.column);
                        console.log(stats);

                        // Show statistics dialog
                        detailsDialog.title = "Item Statistics";
                        detailsDialog.itemText = "Text: " + tree_delegate.display + "\n\n" + stats;
                        detailsDialog.open();
                    }
                }
            }
        }
    }

    component MyTreeView: TreeView {
        id: treeView
        anchors.fill: parent
        anchors.margins: 10
        clip: true

        // Signal to emit when the current item changes
        signal currentItemChanged(string statistics)

        // property int currentRow: -1

        selectionModel: ItemSelectionModel {
            onCurrentChanged: {
                // When current index changes, emit the signal with item statistics
                if (currentIndex.row >= 0) {
                    let stats = treeModel.getItemStats(currentIndex.row, currentIndex.column);
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

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }

    // Dialog for showing item details
    Dialog {
        id: detailsDialog
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 400
        height: 200
        modal: true

        property string itemText: ""

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10

            Label {
                text: "Selected Item:"
                font.bold: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextArea {
                    text: detailsDialog.itemText
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    background: Rectangle {
                        color: Universal.background
                        border.color: Universal.accent
                        border.width: 1
                        radius: 4
                    }
                }
            }

            Button {
                text: "Close"
                Layout.alignment: Qt.AlignRight
                onClicked: detailsDialog.close()
            }
        }
    }

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
                onCurrentItemChanged: function (statistics) {
                    console.log("Current item changed. Statistics:", statistics);
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
                    text: "Current Item Statistics"
                    font.bold: true
                    font.pointSize: 12
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        id: statsTextArea
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
                function onCurrentItemChanged(statistics) {
                    statsTextArea.text = statistics;
                }
            }
        }
    }
}
```

## Editable
### Rename Nodes
#### Python Model
The Python Model must have the following changes from the earlier model. Continued in [Trees With SQLite](./trees-with-sqlite.md).

```diff

diff --git a/treeModel.py b/treeModel.py
index 97cd094..66ea4ea 100644
--- a/treeModel.py
+++ b/treeModel.py
@@ -1,5 +1,5 @@
 import sys
-from PySide6.QtCore import QAbstractItemModel, QByteArray, QModelIndex, Qt, Slot
+from PySide6.QtCore import QAbstractItemModel, QByteArray, QModelIndex, Qt, Slot, Signal
 from typing import override
 from hash_helper import calculate_hash

@@ -51,11 +51,14 @@ class TreeModel(QAbstractItemModel):
             return parent.internalPointer().columnCount()
         return self.root_item.columnCount()

+    # Signal to notify when an item has been renamed
+    itemRenamed = Signal(int, int, str)
+
     def data(self, index, role=Qt.ItemDataRole.DisplayRole):
         if not index.isValid():
             return None

-        if role != Qt.ItemDataRole.DisplayRole and role != Qt.ItemDataRole.UserRole:
+        if role != Qt.ItemDataRole.DisplayRole and role != Qt.ItemDataRole.UserRole and role != Qt.ItemDataRole.EditRole:
             return None

         item = index.internalPointer()
@@ -65,7 +68,7 @@ class TreeModel(QAbstractItemModel):
         if not index.isValid():
             return Qt.ItemFlag.NoItemFlags

-        return Qt.ItemFlag.ItemIsEnabled | Qt.ItemFlag.ItemIsSelectable
+        return Qt.ItemFlag.ItemIsEnabled | Qt.ItemFlag.ItemIsSelectable | Qt.ItemFlag.ItemIsEditable

     def headerData(self, section, orientation, role=Qt.ItemDataRole.DisplayRole):
         if (
@@ -120,6 +123,7 @@ class TreeModel(QAbstractItemModel):
         roles = {
             Qt.ItemDataRole.DisplayRole: QByteArray(b"display"),
             Qt.ItemDataRole.UserRole: QByteArray(b"userData"),
+            Qt.ItemDataRole.EditRole: QByteArray(b"edit"),
         }
         r: dict[int, QByteArray] = roles  # pyright: ignore [reportAssignmentType]
         return r
@@ -173,6 +177,46 @@ class TreeModel(QAbstractItemModel):
         return item_text_str


+    @override
+    def setData(self, index, value, role=Qt.ItemDataRole.EditRole):
+        if not index.isValid() or role != Qt.ItemDataRole.EditRole:
+            return False
+
+        item = index.internalPointer()
+        if not item:
+            return False
+
+        # Update the item data
+        item.item_data[index.column()] = value
+
+        # Emit dataChanged signal
+        self.dataChanged.emit(index, index, [role])
+
+        # Emit our custom signal
+        self.itemRenamed.emit(index.row(), index.column(), value)
+
+        return True
+
+    @Slot(int, int, str)
+    def renameItem(self, row, column, newName):
+        """
+        Rename an item at the given row and column.
+        This method is exposed to QML.
+
+        Args:
+            row: The row of the item
+            column: The column of the item
+            newName: The new name for the item
+
+        Returns:
+            True if successful, False otherwise
+        """
+        index = self.index(row, column)
+        if not index.isValid():
+            return False
+
+        return self.setData(index, newName, Qt.ItemDataRole.EditRole)
+
     @Slot(int, int, result=str)
     def getItemStats(self, row, column):
         """
```

#### QML
### Create New Data
#### Context Menu
### Move Nodes
### Delete Nodes
## Animated
## Connecting to a File (JSON)
### Create a File
### Read an Existing File
### Update an Existing File
#### Create new Nodes
#### Rename Nodes
#### Move Nodes
#### Delete Nodes
## Connecting to a File (Sqlite)
### Create a File
### Read an Existing File
### Update an Existing File
#### Create new Nodes
#### Rename Nodes
#### Move Nodes
#### Delete Nodes
