import QtQuick
import "../../theme" as ThemeTokens

Item {
    id: root

    signal dismissed()
    readonly property real desiredWidth: 420
    readonly property real desiredHeight: 220

    Keys.onEscapePressed: dismissed()

    Column {
        anchors.centerIn: parent
        spacing: 10

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰎈  Media player"
            color: ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Nothing is playing"
            color: ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
        }
    }
}
