import QtQuick
import "../../theme" as ThemeTokens

Item {
    id: root

    signal dismissed()
    readonly property real desiredWidth: 360
    readonly property real desiredHeight: 190

    Keys.onEscapePressed: dismissed()

    Text {
        anchors.centerIn: parent
        text: "󰔎  Gruvbox Material Dark Soft"
        color: ThemeTokens.Theme.foreground
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: ThemeTokens.Theme.fontSize
    }
}
