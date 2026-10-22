import QtQuick
import "../theme" as ThemeTokens

Text {
    id: clock
    property date now: new Date()
    text: Qt.formatDateTime(now, "ddd  dd MMM  ·  HH:mm")
    color: ThemeTokens.Theme.foreground
    font.family: ThemeTokens.Theme.fontFamily
    font.pixelSize: ThemeTokens.Theme.fontSize
    font.weight: Font.DemiBold

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: clock.now = new Date()
    }
}
