import QtQuick
import "../../theme" as ThemeTokens

Text {
    id: clock

    signal dismissed()
    readonly property real desiredWidth: implicitWidth + 24
    readonly property real desiredHeight: ThemeTokens.Theme.barHeight
    property date now: new Date()

    text: Qt.formatDateTime(now, "ddd  dd MMM  ·  HH:mm")
    color: ThemeTokens.Theme.foreground
    font.family: ThemeTokens.Theme.fontFamily
    font.pixelSize: ThemeTokens.Theme.fontSize
    font.weight: Font.DemiBold
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.now = new Date()
    }
}
