import QtQuick

Item {
    id: root

    required property QtObject shellState
    required property string mode
    signal dismissed()

    readonly property real desiredWidth: loader.item ? loader.item.desiredWidth : 0
    readonly property real desiredHeight: loader.item ? loader.item.desiredHeight : 0

    function takeFocus() {
        if (loader.item && typeof loader.item.takeFocus === "function")
            loader.item.takeFocus()
        else if (loader.item)
            loader.item.forceActiveFocus()
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: root.mode === root.shellState.hubLauncher ? launcherComponent
                       : root.mode === root.shellState.hubTheme ? themeComponent
                       : root.mode === root.shellState.hubNotifications ? notificationsComponent
                       : root.mode === root.shellState.hubMedia ? mediaComponent
                       : clockComponent
    }

    Connections {
        target: loader.item
        function onDismissed() { root.dismissed() }
    }

    Component { id: clockComponent; Clock { anchors.centerIn: parent } }
    Component { id: launcherComponent; AppLauncher {} }
    Component { id: themeComponent; ThemePicker {} }
    Component { id: notificationsComponent; NotificationCenter {} }
    Component { id: mediaComponent; MediaPlayer {} }
}
