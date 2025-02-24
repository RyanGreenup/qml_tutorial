# Chapter 1

## Introduction

This book serves as an introduction to QML

## Comparison to Widgets

- More performant
    - In my experience, QML is much faster
- More Powerful
    - Easier to do really complex things
- More Difficult
    - Harder to get up and Go
- Cleaner Code
    - Layout of code is better
- Worse Code
    - Lack of typing means a good structure is really important. Your code will either be great or dogshit, it's a lot more nuanced.


## What this book Aims to achieve

How to get up and running with QML quickly, for desktop application development, targeting PySide6.


The qml book oficially documents C++ but doesn't provide a simple cover-to-cover walkthrough. I hope to fill this gap. The target is desktop with Pyside6.

Pyside6 makes a lot of sense, easy to package with, e.g. `uv`, less pain than cmake and for important stuff we have maturin and pyo3 which will also be covered later in this book


## Installing

The author uses a variety of OS (Void, Gentoo, Arch), this book targets Arch and all steps are confirmed to run in an Arch docker container (thank you distrobox)


```
pacman -S qt6 qt6-declarative
```

You will want to have `qmlls` in your `$PATH` if you are using Neovim, for me I simply:


```sh
PATH="${PATH}:$HOME/.local/bin"
ln -s $(which qmlls6) ~/.local/bin
```


## Writing

Qt Creator is handy because the popups work out of the box and `F1` will open the help.

I typically use vim, however, ocassionaly I go over to qt creator to quickly access the help


The qt docs for qtwidgets and qml are different for views. i.e. the following are different:

- [PySide6.QtWidgets.QTreeView - Qt for Python](https://doc.qt.io/qtforpython-6/PySide6/QtWidgets/QTreeView.html)
- [TreeView QML Type | Qt Quick 6.8.2](https://doc.qt.io/qt-6/qml-qtquick-treeview.html)

However, The Models are the same:

- Lists
    - [PySide6.QtCore.QAbstractListModel - Qt for Python](https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractListModel.html#PySide6.QtCore.QAbstractListModel)
    - [QAbstractListModel Class | Qt Core 6.8.2](https://doc.qt.io/qt-6/qabstractlistmodel.html)
- Abstract
    - [PySide6.QtCore.QAbstractItemModel - Qt for Python](https://doc.qt.io/qtforpython-6/PySide6/QtCore/QAbstractItemModel.html)
    - [QAbstractItemModel Class | Qt Core 6.8.2](https://doc.qt.io/qt-6/qabstractitemmodel.html)
