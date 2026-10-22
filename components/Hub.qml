import QtQuick
import "../theme" as ThemeTokens
import "../hub" as HubViews

Item {
    id: root
    required property QtObject hubState
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Item {
        id: content
        anchors.centerIn: parent
        implicitWidth: loader.item ? loader.item.implicitWidth : 0
        implicitHeight: loader.item ? loader.item.implicitHeight : 0

        Loader {
            id: loader
            anchors.centerIn: parent
            sourceComponent: root.hubState.active === root.hubState.launcher ? launcher
                           : root.hubState.active === root.hubState.theme ? theme
                           : clock
        }
    }

    Component { id: clock; Clock {} }
    Component {
        id: launcher
        Text {
            text: "󰀻  Application launcher"
            color: ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
        }
    }
    Component { id: theme; HubViews.ThemePicker { onDismissed: root.hubState.close() } }

    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
}
