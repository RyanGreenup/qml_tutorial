# QML Desktop Tutorial

- [Creating a Menu Bar](./creating-a-menu-bar.md)
- Animations
- Basic models
    - List View
    - Tree View
    - Table View
- Charts
- Markdown Preview
- SQL Tables
- File Trees



Widgets are quicker to develop a keyboard centric desktop application that does what one might expect out of the box quickly. qss can style the application.

QML will provide conventions around code style that make it easier to maintain and easier to polish. Animations are easy and I've generally found performance in QML to be better than qt widgets in PySide6.

So:


1. Template in QT Widgets
    - Investigate how the application will be used and refine:
        - Animations
        - Keyboard shortcuts and navigation
        - Missing Features
2. Rewrite in QML
    - Also provides an opportunity to write data handlers in Rust with pyO3 which may (or may not) offer benefits in terms of correctness, performance and portability (e.g. write the API in Rust then share with a tui in TUI-rs or a web app with Axum and minijinja or leptos)



