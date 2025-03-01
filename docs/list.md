
Start with a basic application layout


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

    component CustomHandle: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        color: SplitHandle.pressed ? Material.accent : SplitHandle.hovered ? Qt.lighter(Material.accent, 1.5) : Qt.rgba(0, 0, 0, 0.2)
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    component FocusableRectangle: Rectangle {
        border.width: activeFocus ? 10 : 0
        border.color: Material.accent
        focus: true
        activeFocusOnTab: true

        Keys.onPressed: function (event) {
            if (event.modifiers & Qt.ControlModifier) {
                const step = 20;
                switch (event.key) {
                case Qt.Key_Left:
                    SplitView.preferredWidth = Math.max(50, SplitView.preferredWidth - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Right:
                    SplitView.preferredWidth = Math.min(parent.width - 50, SplitView.preferredWidth + step);
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    SplitView.preferredHeight = Math.max(50, SplitView.preferredHeight - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    SplitView.preferredHeight = Math.min(parent.height - 50, SplitView.preferredHeight + step);
                    event.accepted = true;
                    break;
                }
            }
        }
    }

    component SplitViewWithCustomHandle: SplitView {
        anchors.fill: parent
        handle: CustomHandle {}
    }

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }





    SplitViewWithCustomHandle {
        orientation: Qt.Horizontal
        FocusableRectangle {
            SplitView.preferredWidth: parent.width * 0.39
            color: Fusion.background
        }
        FocusableRectangle {
            SplitView.preferredWidth: parent.width * 0.61
            color: Fusion.background
        }
    }
}
```

Now replace one of the rectangles with a list:


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


    component ContactModel: ListModel {
        ListElement {
            name: "Bill Smith"
            number: "555 3264"
        }
        ListElement {
            name: "John Brown"
            number: "555 8426"
        }
        ListElement {
            name: "Sam Wise"
            number: "555 0473"
        }
    }

    component ContactView: ListView {
        width: 180
        height: 200

        // Allow Focusing the list for keyboard use
        activeFocusOnTab: true
        focus: true

        // Highlight the current item
        highlight: Rectangle {
            color: "lightsteelblue"
            radius: 5
        }
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 500

        // Set the model for the data
        model: ContactModel {}

        // How to display the content
        delegate: Text {
            required property string name
            required property string number
            text: name + ": " + number
        }
    }

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }

    SplitViewWithCustomHandle {
        orientation: Qt.Horizontal
        ContactView {
            SplitView.preferredWidth: parent.width * 0.39
        }

        // NOTE FocusableRectangle has been moved into a file FocusableRectangle.qml
        FocusableRectangle {
            SplitView.preferredWidth: parent.width * 0.61
            color: Fusion.background
        }
    }
}
```

In this list , notice the highlightMoveDuration, this may be worth changing if it's too slow




We can improve the delegate to make it a bit prettier:

```qml
component ContactDelegate: Item {
        id: myItem
        required property string name
        required property string number
        width: 180
        height: 40
        Column {
            Text {
                text: '<b>Name:</b> ' + myItem.name
            }
            Text {
                text: '<b>Number:</b> ' + myItem.number
            }
        }
    }
```

Importantly, the delegate requires a `MouseArea` if the user wishes to click an item in the list in order to select it:


```qml
component ContactDelegate: Item {
        id: myItem
        required property string name
        required property string number
        required property int index
        width: 180
        height: 40

        Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Qt.lighter("lightsteelblue", 1.1) : "transparent"

            Column {
                Text {
                    text: '<b>Name:</b> ' + myItem.name
                }
                Text {
                    text: '<b>Number:</b> ' + myItem.number
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: myItem.ListView.view.currentIndex = index
            }
        }
    }

```

All together:

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

    component CustomHandle: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        color: SplitHandle.pressed ? Material.accent : SplitHandle.hovered ? Qt.lighter(Material.accent, 1.5) : Qt.rgba(0, 0, 0, 0.2)
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    component FocusableRectangle: Rectangle {
        border.width: activeFocus ? 10 : 0
        border.color: Material.accent
        focus: true
        activeFocusOnTab: true

        Keys.onPressed: function (event) {
            if (event.modifiers & Qt.ControlModifier) {
                const step = 20;
                switch (event.key) {
                case Qt.Key_Left:
                    SplitView.preferredWidth = Math.max(50, SplitView.preferredWidth - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Right:
                    SplitView.preferredWidth = Math.min(parent.width - 50, SplitView.preferredWidth + step);
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    SplitView.preferredHeight = Math.max(50, SplitView.preferredHeight - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    SplitView.preferredHeight = Math.min(parent.height - 50, SplitView.preferredHeight + step);
                    event.accepted = true;
                    break;
                }
            }
        }
    }

    component SplitViewWithCustomHandle: SplitView {
        anchors.fill: parent
        handle: CustomHandle {}
    }

    component ContactModel: ListModel {
        ListElement {
            name: "Bill Smith"
            number: "555 3264"
        }
        ListElement {
            name: "John Brown"
            number: "555 8426"
        }
        ListElement {
            name: "Sam Wise"
            number: "555 0473"
        }
    }

    component ContactDelegate: Item {
        id: myItem
        required property string name
        required property string number
        required property int index
        width: 180
        height: 40

        Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Qt.lighter("lightsteelblue", 1.1) : "transparent"

            Column {
                Text {
                    text: '<b>Name:</b> ' + myItem.name
                }
                Text {
                    text: '<b>Number:</b> ' + myItem.number
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: myItem.ListView.view.currentIndex = myItem.index
            }
        }
    }
    component ContactView: ListView {
        id: myList
        width: 180
        height: 200
        activeFocusOnTab: true
        highlight: Rectangle {
            color: "lightsteelblue"
            radius: 5
        }
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 500
        keyNavigationWraps: true

        model: ContactModel {}
        focus: true
        delegate: ContactDelegate {}
    }

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }

    SplitViewWithCustomHandle {
        orientation: Qt.Horizontal
        ContactView {
            SplitView.preferredWidth: parent.width * 0.39
        }

        FocusableRectangle {
            SplitView.preferredWidth: parent.width * 0.61
            color: Material.background
        }
    }
}
```



The listview does not have a border, only the rectangle does. we could use `anchors.fill: parent` to fill out a rectangle:

```qml
FocusableRectangle {
        SplitView.preferredWidth: parent.width * 0.39
        ContactView {
            anchors.fill: parent
        }
    }
```

However, this selects the rectangle and the list isn't in focus, the user must press tab again which selects the list but indicates nothing to the user.

To solve this, we could do something like this:

```qml
SplitView {
    // ...
    Rectangle {
        // Don't allow this to take focus
        focus: false
        // Set the color of the border when focused
        border.color: Material.accent
        // Set border when the contact view is focused
        border.width: contactList.activeFocus ? 10 : 0
        // Set the split
        SplitView.preferredWidth: 0.4 * parent.width
        ContactView {
            // Set the id from above
            id: contactList
            // Fill the parent rectangle
            anchors.fill: parent
        }
    }
}
```

We could also take a different approach, which we will do instead simply for the sake of example.

We instead create a rectangle **inside** the List, don't allow the rectangle to take focus but do give it a border in the same way:


```qml
pragma ComponentBehavior: Bound

ApplicationWindow {
    id: root
    // ...
    // ...
    // ...

    /**
     * Determines the border width based on focus state.
     *
     * @param {boolean} activeFocus - Indicates whether the element is focused.
     * @returns {number} The border width.
     */
    function border_width_on_focus(activeFocus) {
        if (activeFocus) {
            return 10
        } else {
            return 0
        }
    }
    component ContactView: ListView {
            id: myList
            width: 180
            height: 200

            // Allow Focusing for keyboard use
            activeFocusOnTab: true
            focus: true
            keyNavigationWraps: true

            // Highlight the current item
            highlight: Rectangle {
                color: "lightsteelblue"
                radius: 5
            }
            highlightFollowsCurrentItem: true
            highlightMoveDuration: 500

            // Use a rectangle for an outer border
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                // border.width: parent.activeFocus ? 2 : 0
                border.width: border_width_on_focus(parent.activeFocus)
                border.color: Material.accent
                // z: -1
            }
            // Buffer the list to make space for the rectangle
            topMargin: focusBorderWidth + 2
            leftMargin: focusBorderWidth + 2

            // Model for the data
            model: ContactModel {}

            // Delegate to display each roe
            delegate: ContactDelegate {}
        }
}
```

Some things to note here:


1. The `z: -1` ensures the rectangle is always at the bottom of the layers of items in the lisview. Order matters in QML and declaring the Rectangle at the very end would likely be sufficient, however this may good practice to bear in mind.
    - Comment out the `z: -1` and the border will be behind the focus border
    - Leave it in and the border will be behind the highlight of list items.
2. `pragma`. This allows us to call the function from a parent. Using this pragma can lead to tightly coupled code and make refactoring harder, it's used here as an example
    - As we want the borders to have the same size
    - One could also create a property in the root of the application `property int focusBorderWidth: 10` and then use it like so:

    ```qml
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.focusBorderWidth
        border.color: Material.accent
        // z: -1
    }

    ```
3. Docstrings on functions
    - JS has no types, it quickly gets very confusing, use docstrings for your own health and wellbeing

One should also set the `margin.width` of views inside a rectangle to something relative to the margin width. One could also set the `margin.width` to depend on the parent `border.width` so that it adjusts when focused to make room for the border.

The use of a function here could be valid, but it depends. This tightly couples all of the components together meaning one cannot easily move things around which usually comes to be a pain later. it may be better to set a property with a default value and overwrite it later:


```qml
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: root
    property int focusBorderWidth: 10

    SplitViewWithCustomHandle {
            orientation: Qt.Horizontal

            ContactView {
                id: contactList
                SplitView.preferredWidth: parent.width * 0.39
                focusBorderWidth: root.focusBorderWidth
            }

            FocusableRectangle {
                SplitView.preferredWidth: parent.width * 0.61
                color: Material.background
                focusBorderWidth: root.focusBorderWidth
            }
        }
}
```

However, if the component is not going be refactored out of the parent component it will be fine.


- `pragma ComponentBehavior: Bound`
    - If the attribute will never need to changed from outside the parent component, use the pragma to inherit the parent  value and refactor the parent into a self contained file
- Default Property
    - If you want to be able to move that component wherever and it taking a default value is not a problem, then use a property and set it when used

This is where the lack of typing becomes a pain




Here is the code so far:


```qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: root
    property int focusBorderWidth: 10
    width: 640
    height: 480
    visible: true
    title: "Animated Rectangle Demo"

    component CustomHandle: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        color: SplitHandle.pressed ? Material.accent : SplitHandle.hovered ? Qt.lighter(Material.accent, 1.5) : Qt.rgba(0, 0, 0, 0.2)
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }



    /*!
        A rectangle that can be focused by pressing tab between widgets.

        Properties:
            - focusBorderWidth: Controls the width of the border when focused

        Keyboard Shortcuts:
            - Ctrl + Arrow Keys: Resize the rectangle within SplitView
            - Tab: Navigate between focusable components

        Example:
            FocusableRectangle {
                focusBorderWidth: 5
                SplitView.preferredWidth: parent.width * 0.5
            }
    */
    component FocusableRectangle: Rectangle {
        property int focusBorderWidth: 10
        border.width: activeFocus ? focusBorderWidth : 0
        border.color: Material.accent
        focus: true
        activeFocusOnTab: true

        Keys.onPressed: function (event) {
            if (event.modifiers & Qt.ControlModifier) {
                const step = 20;
                switch (event.key) {
                case Qt.Key_Left:
                    SplitView.preferredWidth = Math.max(50, SplitView.preferredWidth - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Right:
                    SplitView.preferredWidth = Math.min(parent.width - 50, SplitView.preferredWidth + step);
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    SplitView.preferredHeight = Math.max(50, SplitView.preferredHeight - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    SplitView.preferredHeight = Math.min(parent.height - 50, SplitView.preferredHeight + step);
                    event.accepted = true;
                    break;
                }
            }
        }
    }

    component SplitViewWithCustomHandle: SplitView {
        anchors.fill: parent
        handle: CustomHandle {}
    }

    component ContactModel: ListModel {
        ListElement {
            name: "Bill Smith"
            number: "555 3264"
        }
        ListElement {
            name: "John Brown"
            number: "555 8426"
        }
        ListElement {
            name: "Sam Wise"
            number: "555 0473"
        }
    }

    component ContactDelegate: Item {
        id: myItem
        required property string name
        required property string number
        required property int index
        width: 180
        height: 40

        Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Qt.lighter("lightsteelblue", 1.1) : "transparent"

            Column {
                Text {
                    text: '<b>Name:</b> ' + myItem.name
                }
                Text {
                    text: '<b>Number:</b> ' + myItem.number
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: myItem.ListView.view.currentIndex = myItem.index
            }
        }
    }
    component ContactView: ListView {
        id: myList
        width: 180
        height: 200
        property int focusBorderWidth: 10
        topMargin: focusBorderWidth + 2
        leftMargin: focusBorderWidth + 2

        activeFocusOnTab: true
        highlight: Rectangle {
            color: "lightsteelblue"
            radius: 5
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: parent.activeFocus ? myList.focusBorderWidth : 0
            border.color: Material.accent
            // z: -1
        }
        keyNavigationWraps: true

        model: ContactModel {}
        focus: true
        delegate: ContactDelegate {}
    }

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }

    SplitViewWithCustomHandle {
        orientation: Qt.Horizontal

        ContactView {
            id: contactList
            SplitView.preferredWidth: parent.width * 0.39
            focusBorderWidth: root.focusBorderWidth
        }

        FocusableRectangle {
            SplitView.preferredWidth: parent.width * 0.61
            color: Material.background
            focusBorderWidth: root.focusBorderWidth
        }
    }
}
```


We still need to:

1. Populate the right side with some info
2. Move the model to Python


To implement 1, we should emit a signal from the listView that contains information needed by the right rectangle, we can do this like so:


```qml
        signal contactSelected(string name, string number)

        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                const currentItem = model.get(currentIndex)
                contactSelected(currentItem.name, currentItem.number)
            }
        }
```

here currentIndex is a property of the listView [^1740369570] and `.name` and `.number` are properties of the model.

[^1740369570]: [ListView QML Type | Qt Quick 6.8.2#currentIndex-prop](https://doc.qt.io/qt-6/qml-qtquick-listview.html#currentIndex-prop)


Then the signals can be connected like so:


```qml
SplitViewWithCustomHandle {
        orientation: Qt.Horizontal

        ContactView {
            id: contactList
            SplitView.preferredWidth: parent.width * 0.39
            focusBorderWidth: root.focusBorderWidth
        }

        FocusableRectangle {
            id: detailsRect
            SplitView.preferredWidth: parent.width * 0.61
            color: Material.background
            focusBorderWidth: root.focusBorderWidth

            property string contactName: ""
            property string contactNumber: ""

            Label {
                text: detailsRect.contactName + " " + detailsRect.contactNumber
            }

            Connections {
                target: contactList
                function onContactSelected(name, number) {
                    detailsRect.contactName = name
                    detailsRect.contactNumber = number
                }
            }
        }
    }
```


This could be visually improved and wrapped into a component like so:


```qml

    component ContactDetails: FocusableRectangle {
        id: detailsRect
        color: Material.background

        property string contactName: ""
        property string contactNumber: ""

        Column {
            anchors.centerIn: parent
            spacing: 10
            Text {
                text: "Selected Contact Details:"
                font.bold: true
            }
            Text {
                text: "Name: " + detailsRect.contactName
            }
            Text {
                text: "Number: " + detailsRect.contactNumber
            }
        }

        Connections {
            target: contactList
            function onContactSelected(name, number) {
                detailsRect.contactName = name;
                detailsRect.contactNumber = number;
            }
        }
    }

    SplitViewWithCustomHandle {
        orientation: Qt.Horizontal

        ContactView {
            id: contactList
            SplitView.preferredWidth: parent.width * 0.39
            focusBorderWidth: root.focusBorderWidth
        }
        ContactDetails {
            SplitView.preferredWidth: parent.width * 0.61
            focusBorderWidth: root.focusBorderWidth
        }
    }

```


All together:


```qml

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: root
    property int focusBorderWidth: 10
    width: 640
    height: 480
    visible: true
    title: "Animated Rectangle Demo"

    component CustomHandle: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        color: SplitHandle.pressed ? Material.accent : SplitHandle.hovered ? Qt.lighter(Material.accent, 1.5) : Qt.rgba(0, 0, 0, 0.2)
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    component FocusableRectangle: Rectangle {
        property int focusBorderWidth: 10
        border.width: activeFocus ? focusBorderWidth : 0
        border.color: Material.accent
        focus: true
        activeFocusOnTab: true

        Keys.onPressed: function (event) {
            if (event.modifiers & Qt.ControlModifier) {
                const step = 20;
                switch (event.key) {
                case Qt.Key_Left:
                    SplitView.preferredWidth = Math.max(50, SplitView.preferredWidth - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Right:
                    SplitView.preferredWidth = Math.min(parent.width - 50, SplitView.preferredWidth + step);
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    SplitView.preferredHeight = Math.max(50, SplitView.preferredHeight - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    SplitView.preferredHeight = Math.min(parent.height - 50, SplitView.preferredHeight + step);
                    event.accepted = true;
                    break;
                }
            }
        }
    }

    component SplitViewWithCustomHandle: SplitView {
        anchors.fill: parent
        handle: CustomHandle {}
    }

    component ContactModel: ListModel {
        ListElement {
            name: "Bill Smith"
            number: "555 3264"
        }
        ListElement {
            name: "John Brown"
            number: "555 8426"
        }
        ListElement {
            name: "Sam Wise"
            number: "555 0473"
        }
    }

    component ContactDelegate: Item {
        id: myItem
        required property string name
        required property string number
        required property int index
        width: 180
        height: 40

        Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Qt.lighter("lightsteelblue", 1.1) : "transparent"

            Column {
                Text {
                    text: '<b>Name:</b> ' + myItem.name
                }
                Text {
                    text: '<b>Number:</b> ' + myItem.number
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: myItem.ListView.view.currentIndex = myItem.index
            }
        }
    }
    component ContactView: ListView {
        id: myList
        width: 180
        height: 200
        property int focusBorderWidth: 10
        signal contactSelected(string name, string number)

        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                const currentItem = model.get(currentIndex);
                contactSelected(currentItem.name, currentItem.number);
            }
        }
        topMargin: focusBorderWidth + 2
        leftMargin: focusBorderWidth + 2

        activeFocusOnTab: true
        highlight: Rectangle {
            color: "lightsteelblue"
            radius: 5
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: parent.activeFocus ? myList.focusBorderWidth : 0
            border.color: Material.accent
            // z: -1
        }
        keyNavigationWraps: true

        model: ContactModel {}
        focus: true
        delegate: ContactDelegate {}
    }

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }

    component ContactDetails: FocusableRectangle {
        id: detailsRect
        color: Material.background

        property string contactName: ""
        property string contactNumber: ""

        Column {
            anchors.centerIn: parent
            spacing: 10
            Text {
                text: "Selected Contact Details:"
                font.bold: true
            }
            Text {
                text: "Name: " + detailsRect.contactName
            }
            Text {
                text: "Number: " + detailsRect.contactNumber
            }
        }

        Connections {
            target: contactList
            function onContactSelected(name, number) {
                detailsRect.contactName = name;
                detailsRect.contactNumber = number;
            }
        }
    }

    SplitViewWithCustomHandle {
        orientation: Qt.Horizontal

        ContactView {
            id: contactList
            SplitView.preferredWidth: parent.width * 0.39
            focusBorderWidth: root.focusBorderWidth
        }
        ContactDetails {
            SplitView.preferredWidth: parent.width * 0.61
            focusBorderWidth: root.focusBorderWidth
        }
    }
}

```


Now we just need to move the model over to Python.

Until now we've been able to run the qml with:

```
qml6 main.qml
```

Now we will need python that can drive the qml:

```sh
dir=my_qml_application
uv init "${dir}"
cd "${dir}"
uv add pyside6
mv hello.py main.py
mv ../main.qml main.qml
nvim main.py
```



```python
import signal
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

def main():
    app = QGuiApplication(sys.argv)
    signal.signal(signal.SIGINT, signal.SIG_DFL)

    engine = QQmlApplicationEngine()
    qml_file = Path(__file__).parent / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == '__main__':
    main()
```


```
.
└── my_app
    ├── .git/
    ├── main.py
    ├── main.qml
    ├── pyproject.toml
    ├── README.md
    └── uv.lock

2 directories, 5 files
```


Then run what we had with:

```
python main.py
```




The Python listmodel is documented by [PySide6.QtCore.QAbstractListModel - Qt for Python](https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractListModel.html#PySide6.QtCore.QAbstractListModel) [^1740370196].

[^1740370196]: [PySide6.QtCore.QAbstractListModel - Qt for Python](https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractListModel.html#PySide6.QtCore.QAbstractListModel)

Migrate `ContactModel` into a python module that subclasses `QAbstractListModel`. When subclassing QAbstractListModel , you must provide implementations of the rowCount() and data() functions. Well behaved models also provide a headerData() implementation.

See this section from the documentation [^1740370196]:

> When subclassing QAbstractListModel , you must provide implementations of the rowCount() and data() functions. Well behaved models also provide a headerData() implementation.
>
> If your model is used within QML and requires roles other than the default ones provided by the roleNames() function, you must override it.
>
> For editable list models, you must also provide an implementation of setData() , and implement the flags() function so that it returns a value containing ItemIsEditable .
>
> Note that QAbstractListModel provides a default implementation of columnCount() that informs views that there is only a single column of items in this model.
>
> Models that provide interfaces to resizable list-like data structures can provide implementations of insertRows() and removeRows() . When implementing these functions, it is important to call the appropriate functions so that all connected views are aware of any changes:
>
> An insertRows() implementation must call beginInsertRows() before inserting new rows into the data structure, and it must call endInsertRows() immediately afterwards.
>
> A removeRows() implementation must call beginRemoveRows() before the rows are removed from the data structure, and it must call endRemoveRows() immediately afterwards.


We can adda

The model can be translated to python like so:


```python
from typing import final, override
from PySide6.QtCore import (
    QByteArray,
    QObject,
    QPersistentModelIndex,
    Qt,
    QAbstractListModel,
    QModelIndex,
)


@final
class ContactModel(QAbstractListModel):
    NameRole = Qt.ItemDataRole.UserRole + 1
    NumberRole = Qt.ItemDataRole.UserRole + 2

    def __init__(self, parent: QObject | None = None):
        super().__init__(parent)
        self._contacts = [
            {"name": "Bill Smith", "number": "555 3264"},
            {"name": "John Brown", "number": "555 8426"},
            {"name": "Sam Wise", "number": "555 0473"},
        ]

    @override
    def roleNames(self):
        return {
            self.NameRole: QByteArray(b"name"),
            self.NumberRole: QByteArray(b"number"),
        }

    @override
    def rowCount(
        self, parent: QModelIndex | QPersistentModelIndex | None = None
    ) -> int:
        if parent is None:
            parent = QModelIndex()
        return len(self._contacts)

    @override
    def data(
        self,
        index: QModelIndex | QPersistentModelIndex,
        role: int = Qt.ItemDataRole.DisplayRole,
    ):
        if not index.isValid() or not (0 <= index.row() < len(self._contacts)):
            return None

        contact = self._contacts[index.row()]

        if role == self.NameRole:
            return contact["name"]
        elif role == self.NumberRole:
            return contact["number"]

        return None

    @override
    def headerData(
        self,
        section: int,
        orientation: Qt.Orientation,
        role: int = Qt.ItemDataRole.DisplayRole,
    ) -> str | None:
        if role != Qt.ItemDataRole.DisplayRole:
            return None

        if orientation == Qt.Orientation.Horizontal:
            return "Contacts"

        return str(section + 1)
```

This can be exposed to QML in the `main.py` like so:


```python

import signal
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from ContactModel import ContactModel


def main():
    app = QGuiApplication(sys.argv)
    _ = signal.signal(signal.SIGINT, signal.SIG_DFL)

    qml_import_name = "ContactManager"
    _qml_type_id = qmlRegisterType(ContactModel, qml_import_name, 1, 0, "ContactModel")  # pyright: ignore

    engine = QQmlApplicationEngine()

    qml_file = Path(__file__).parent / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
```




Because the right rectangle is connected with signals the only thing that needs to be changed is the view, so the correct signal is emitted with the current item is changed:

```qml
component ContactView: ListView {
        id: myList
        width: 180
        height: 200
        property int focusBorderWidth: 10
        signal contactSelected(string name, string number)

        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                console.log("name: " + currentItem.name);
                console.log("number: " + currentItem.number);
                contactSelected(currentItem.name, currentItem.number);
            }
        }
        topMargin: focusBorderWidth + 2
        leftMargin: focusBorderWidth + 2

        activeFocusOnTab: true
        highlight: Rectangle {
            color: "lightsteelblue"
            radius: 5
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: parent.activeFocus ? myList.focusBorderWidth : 0
            border.color: Material.accent
            // z: -1
        }
        keyNavigationWraps: true

        model: ContactModel {}
        focus: true
        delegate: ContactDelegate {}
    }

```

No, wait the delegate needs to be changed too. It's important to use `required property string name` for each additional role.

```qml
    component ContactDelegate: Item {
        id: myItem
        required property string name
        required property string number
        required property int index
        width: 180
        height: 40

        Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Qt.lighter("lightsteelblue", 1.1) : "transparent"

            Column {
                Text {
                    text: '<b>Name:</b> ' + myItem.name
                }
                Text {
                    text: '<b>Number:</b> ' + myItem.number
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: ListView.view.currentIndex = index
            }
        }
    }
```




## All the Code


### Main.py

```python

import signal
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from ContactModel import ContactModel


def main():
    app = QGuiApplication(sys.argv)
    _ = signal.signal(signal.SIGINT, signal.SIG_DFL)

    qml_import_name = "ContactManager"
    _qml_type_id = qmlRegisterType(ContactModel, qml_import_name, 1, 0, "ContactModel")  # pyright: ignore

    engine = QQmlApplicationEngine()

    qml_file = Path(__file__).parent / "main.qml"
    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())


if __name__ == "__main__":
    main()
```


### ContactsModel.py

```python

from typing import final, override
from PySide6.QtCore import (
    QByteArray,
    QObject,
    QPersistentModelIndex,
    Qt,
    QAbstractListModel,
    QModelIndex,
)


@final
class ContactModel(QAbstractListModel):
    NameRole = Qt.ItemDataRole.UserRole + 1
    NumberRole = Qt.ItemDataRole.UserRole + 2

    def __init__(self, parent: QObject | None = None):
        super().__init__(parent)
        self._contacts = [
            {"name": "Bill Smith", "number": "555 3264"},
            {"name": "John Brown", "number": "555 8426"},
            {"name": "Sam Wise", "number": "555 0473"},
        ]

    @override
    def roleNames(self):
        return {
            self.NameRole: QByteArray(b"name"),
            self.NumberRole: QByteArray(b"number"),
        }

    @override
    def rowCount(
        self, parent: QModelIndex | QPersistentModelIndex | None = None
    ) -> int:
        if parent is None:
            parent = QModelIndex()
        return len(self._contacts)

    @override
    def data(
        self,
        index: QModelIndex | QPersistentModelIndex,
        role: int = Qt.ItemDataRole.DisplayRole,
    ):
        if not index.isValid() or not (0 <= index.row() < len(self._contacts)):
            return None

        contact = self._contacts[index.row()]

        if role == self.NameRole:
            return contact["name"]
        elif role == self.NumberRole:
            return contact["number"]

        return None

    @override
    def headerData(
        self,
        section: int,
        orientation: Qt.Orientation,
        role: int = Qt.ItemDataRole.DisplayRole,
    ) -> str | None:
        if role != Qt.ItemDataRole.DisplayRole:
            return None

        if orientation == Qt.Orientation.Horizontal:
            return "Contacts"

        return str(section + 1)

```


### Main.QML


```qml

pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import ContactManager 1.0

ApplicationWindow {
    id: root
    property int focusBorderWidth: 10
    width: 640
    height: 480
    visible: true
    title: "Animated Rectangle Demo"

    component CustomHandle: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        color: SplitHandle.pressed ? Material.accent : SplitHandle.hovered ? Qt.lighter(Material.accent, 1.5) : Qt.rgba(0, 0, 0, 0.2)
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    component FocusableRectangle: Rectangle {
        property int focusBorderWidth: 10
        border.width: activeFocus ? focusBorderWidth : 0
        border.color: Material.accent
        focus: true
        activeFocusOnTab: true

        Keys.onPressed: function (event) {
            if (event.modifiers & Qt.ControlModifier) {
                const step = 20;
                switch (event.key) {
                case Qt.Key_Left:
                    SplitView.preferredWidth = Math.max(50, SplitView.preferredWidth - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Right:
                    SplitView.preferredWidth = Math.min(parent.width - 50, SplitView.preferredWidth + step);
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    SplitView.preferredHeight = Math.max(50, SplitView.preferredHeight - step);
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    SplitView.preferredHeight = Math.min(parent.height - 50, SplitView.preferredHeight + step);
                    event.accepted = true;
                    break;
                }
            }
        }
    }

    component SplitViewWithCustomHandle: SplitView {
        anchors.fill: parent
        handle: CustomHandle {}
    }


    component ContactDelegate: Item {
        id: myItem
        required property string name
        required property string number
        required property int index
        width: 180
        height: 40

        Rectangle {
            anchors.fill: parent
            color: mouseArea.containsMouse ? Qt.lighter("lightsteelblue", 1.1) : "transparent"

            Column {
                Text {
                    text: '<b>Name:</b> ' + myItem.name
                }
                Text {
                    text: '<b>Number:</b> ' + myItem.number
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: ListView.view.currentIndex = index
            }
        }
    }
    component ContactView: ListView {
        id: myList
        width: 180
        height: 200
        property int focusBorderWidth: 10
        signal contactSelected(string name, string number)

        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                console.log("name: " + currentItem.name);
                console.log("number: " + currentItem.number);
                contactSelected(currentItem.name, currentItem.number);
            }
        }
        topMargin: focusBorderWidth + 2
        leftMargin: focusBorderWidth + 2

        activeFocusOnTab: true
        highlight: Rectangle {
            color: "lightsteelblue"
            radius: 5
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: parent.activeFocus ? myList.focusBorderWidth : 0
            border.color: Material.accent
            // z: -1
        }
        keyNavigationWraps: true

        model: ContactModel {}
        focus: true
        delegate: ContactDelegate {}
    }

    // Not important here
    // menuBar: AppMenuBar { }
    // header: AppToolBar { }
    // footer: AppTabBar { }

    component ContactDetails: FocusableRectangle {
        id: detailsRect
        color: Material.background

        property string contactName: ""
        property string contactNumber: ""

        Column {
            anchors.centerIn: parent
            spacing: 10
            Text {
                text: "Selected Contact Details:"
                font.bold: true
            }
            Text {
                text: "Name: " + detailsRect.contactName
            }
            Text {
                text: "Number: " + detailsRect.contactNumber
            }
        }

        Connections {
            target: contactList
            function onContactSelected(name, number) {
                detailsRect.contactName = name;
                detailsRect.contactNumber = number;
            }
        }
    }

    SplitViewWithCustomHandle {
        orientation: Qt.Horizontal

        ContactView {
            id: contactList
            SplitView.preferredWidth: parent.width * 0.39
            focusBorderWidth: root.focusBorderWidth
        }
        ContactDetails {
            SplitView.preferredWidth: parent.width * 0.61
            focusBorderWidth: root.focusBorderWidth
        }
    }
}
```

