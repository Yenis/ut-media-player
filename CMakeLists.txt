cmake_minimum_required(VERSION 3.16)

# The click is QML-only: qmlscene runs qml/Main.qml, so nothing is compiled and
# the package is architecture-independent.
project(gemplayer
    VERSION 0.0.6
    DESCRIPTION "A VLC-style media player for Ubuntu Touch"
    LANGUAGES NONE)

# Click layout: QML tree and icon at the package root. Only these paths are
# installed, so the vlc-android/ reference clone never reaches the package.
install(DIRECTORY qml
    DESTINATION ${CMAKE_INSTALL_PREFIX})
install(FILES assets/icon.png
    DESTINATION ${CMAKE_INSTALL_PREFIX}/assets)
install(FILES manifest.json gemplayer.apparmor gemplayer.desktop
        gemplayer.content-hub.json
    DESTINATION ${CMAKE_INSTALL_PREFIX})
