import QtQuick
import "../../theme" as ThemeTokens

Item {
    id: root
    property bool checked: false
    signal changeRequested(bool value)

    implicitWidth: 42
    implicitHeight: 22
    opacity: enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? ThemeTokens.Theme.success : ThemeTokens.Theme.background
        border.width: 1
        border.color: root.checked ? ThemeTokens.Theme.success : ThemeTokens.Theme.muted

        Rectangle {
            width: 16
            height: 16
            radius: 8
            y: 3
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? ThemeTokens.Theme.background : ThemeTokens.Theme.muted

            Behavior on x {
                NumberAnimation { duration: 140; easing.type: Easing.InOutQuad }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.changeRequested(!root.checked)
    }
}
