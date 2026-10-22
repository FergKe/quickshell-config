import QtQuick
import Quickshell.Services.Pipewire
import "../../theme" as ThemeTokens

Item {
    id: root
    signal dismissed()
    readonly property real desiredHeight: 178
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    property int selectedIndex: 0

    function moveSelection(step) {
        selectedIndex = Math.max(0, Math.min(1, selectedIndex + step))
    }

    function toggleMute() {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted
    }

    function adjustVolume(step) {
        if (!sink || !sink.audio)
            return
        selectedIndex = 1
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step))
    }

    Keys.onEscapePressed: dismissed()
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onLeftPressed: adjustVolume(-0.05)
    Keys.onRightPressed: adjustVolume(0.05)
    Keys.onReturnPressed: toggleMute()
    Keys.onEnterPressed: toggleMute()

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 8
        text: "Audio"
        color: ThemeTokens.Theme.foreground
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: ThemeTokens.Theme.fontSize
        font.weight: Font.DemiBold
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 7
        text: root.muted ? "󰝟" : root.volume > 0.66 ? "󰕾" : root.volume > 0 ? "󰖀" : "󰕿"
        color: root.muted ? ThemeTokens.Theme.muted : ThemeTokens.Theme.foreground
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: 17
    }

    Text {
        id: outputLabel
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 52
        text: root.sink ? root.sink.name : "No audio output"
        color: ThemeTokens.Theme.muted
        elide: Text.ElideRight
        width: parent.width - 80
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: 11
    }

    Rectangle {
        id: muteButton
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: outputLabel.verticalCenter
        width: 43
        height: 25
        radius: 5
        color: muteMouse.containsMouse ? ThemeTokens.Theme.surfaceBright : ThemeTokens.Theme.background
        border.width: root.selectedIndex === 0 ? 1 : 0
        border.color: ThemeTokens.Theme.activeBorder

        Text {
            anchors.centerIn: parent
            text: root.muted ? "Unmute" : "Mute"
            color: ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: 9
        }

        MouseArea {
            id: muteMouse
            anchors.fill: parent
            enabled: root.sink && root.sink.audio
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.selectedIndex = 0
                root.toggleMute()
            }
        }
    }

    Text {
        id: volumeIcon
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.top: outputLabel.bottom
        anchors.topMargin: 28
        text: root.muted ? "󰝟" : "󰕾"
        color: root.muted ? ThemeTokens.Theme.muted : ThemeTokens.Theme.foreground
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: 16
    }

    Item {
        id: slider
        anchors.left: volumeIcon.right
        anchors.leftMargin: 12
        anchors.right: percent.left
        anchors.rightMargin: 12
        anchors.verticalCenter: volumeIcon.verticalCenter
        height: 24

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: "transparent"
            border.width: root.selectedIndex === 1 ? 1 : 0
            border.color: ThemeTokens.Theme.activeBorder
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 5
            radius: 3
            color: ThemeTokens.Theme.background

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.volume))
                height: parent.height
                radius: parent.radius
                color: ThemeTokens.Theme.activeBorder
            }
        }

        Rectangle {
            x: Math.max(0, Math.min(parent.width - width, root.volume * parent.width - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: ThemeTokens.Theme.foreground
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.sink && root.sink.audio
            cursorShape: Qt.PointingHandCursor

            function applyVolume(mouseX) {
                root.selectedIndex = 1
                root.sink.audio.volume = Math.max(0, Math.min(1, mouseX / width))
            }

            onPressed: function(mouse) { applyVolume(mouse.x) }
            onPositionChanged: function(mouse) {
                if (pressed)
                    applyVolume(mouse.x)
            }
        }
    }

    Text {
        id: percent
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: volumeIcon.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.volume * 100) + "%"
        color: ThemeTokens.Theme.foreground
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: 11
    }
}
