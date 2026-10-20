cmake_minimum_required(VERSION 3.16)

# The click is QML-only: qmlscene runs qml/Main.qml, so nothing is compiled and
# the package is architecture-independent.
project(gemplayer
    VERSION 0.1.0
    DESCRIPTION "A VLC-style media player for Ubuntu Touch"
    LANGUAGES NONE)

# The development aids, the remote control (qml/dev/) and the diagnostics
# page (qml/spike/), go only into development builds: tools/dev.sh turns this
# on. A plain `clickable build`, as a release is made, leaves them out.
option(GEM_DEV_AIDS "Package the development aids" OFF)
if(GEM_DEV_AIDS)
    set(GEM_DEV_AIDS_JS "true")
    set(GEM_LEAVE_OUT "^$")
else()
    set(GEM_DEV_AIDS_JS "false")
    set(GEM_LEAVE_OUT "/qml/(dev|spike)(/|$)")
endif()
configure_file(qml/js/Build.js.in ${CMAKE_CURRENT_BINARY_DIR}/Build.js @ONLY)
# Not remembered from one build to the next: a build without the switch is
# one without the aids, whatever the build folder saw before.
unset(GEM_DEV_AIDS CACHE)

# Click layout: QML tree and icon at the package root. Only these paths are
# installed, so the vlc-android/ reference clone never reaches the package.
install(DIRECTORY qml
    DESTINATION ${CMAKE_INSTALL_PREFIX}
    REGEX "${GEM_LEAVE_OUT}" EXCLUDE
    PATTERN "Build.js.in" EXCLUDE)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/Build.js
    DESTINATION ${CMAKE_INSTALL_PREFIX}/qml/js)
install(FILES assets/icon.png
    DESTINATION ${CMAKE_INSTALL_PREFIX}/assets)
install(FILES manifest.json gemplayer.apparmor gemplayer.desktop
        gemplayer.content-hub.json
    DESTINATION ${CMAKE_INSTALL_PREFIX})
