import QtQuick
import "../theme" as ThemeTokens

Item {
    id: root
    signal dismissed()
    implicitWidth: 245
    implicitHeight: 20

    Text {
        anchors.centerIn: parent
        text: "󰔎  Gruvbox Material Dark Soft"
        color: ThemeTokens.Theme.foreground
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: ThemeTokens.Theme.fontSize
    }
}
