import QtQuick
import "../../theme" as ThemeTokens

Item {
    id: root

    signal dismissed()
    readonly property real desiredWidth: 420
    readonly property real desiredHeight: 280

    Keys.onEscapePressed: dismissed()

    Column {
        anchors.centerIn: parent
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰂚  Notification centre"
            color: ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No notifications"
            color: ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
        }
    }
}
