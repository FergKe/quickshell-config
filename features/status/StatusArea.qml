import QtQuick
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import "../../theme" as ThemeTokens
import "../../services" as Services

Row {
    id: root
    required property QtObject shellState
    spacing: 12

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Notification bell: shows the centre's count, a muted bell when empty, and
    // a struck-through bell when Do Not Disturb is on. Click opens the centre.
    Item {
        width: bellRow.implicitWidth
        height: 24

        Row {
            id: bellRow
            anchors.centerIn: parent
            spacing: 3

            Text {
                id: bellIcon
                readonly property bool dnd: Services.NotificationService.dnd
                readonly property int count: Services.NotificationService.count
                text: dnd ? "󰂛" : count > 0 ? "󰂚" : "󰂜"
                color: dnd ? ThemeTokens.Theme.warning
                     : count > 0 ? ThemeTokens.Theme.accent
                     : ThemeTokens.Theme.muted
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: 16
            }

            Text {
                anchors.verticalCenter: bellIcon.verticalCenter
                visible: !Services.NotificationService.dnd
                         && Services.NotificationService.count > 0
                text: Services.NotificationService.count
                color: ThemeTokens.Theme.accent
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: ThemeTokens.Theme.fontSize - 2
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shellState.toggleHub(root.shellState.hubNotifications)
        }
    }

    Item {
        width: wifiIcon.implicitWidth
        height: 24

        Text {
            id: wifiIcon
            anchors.centerIn: parent
            text: "󰤨"
            color: Networking.wifiEnabled ? ThemeTokens.Theme.blue : ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: 16
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shellState.toggleStatus(root.shellState.statusWifi)
        }
    }

    Item {
        width: bluetoothIcon.implicitWidth
        height: 24

        Text {
            id: bluetoothIcon
            anchors.centerIn: parent
            text: "󰂯"
            color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                   ? ThemeTokens.Theme.blue : ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: 16
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shellState.toggleStatus(root.shellState.statusBluetooth)
        }
    }

    Item {
        width: audioIcon.implicitWidth
        height: 24

        Text {
            id: audioIcon
            readonly property var sink: Pipewire.defaultAudioSink
            readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
            readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
            anchors.centerIn: parent
            text: muted ? "󰝟" : volume > 0.66 ? "󰕾" : volume > 0 ? "󰖀" : "󰕿"
            color: muted ? ThemeTokens.Theme.muted : ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: 16
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shellState.toggleStatus(root.shellState.statusAudio)
        }
    }

    Item {
        width: powerIcon.implicitWidth
        height: 24

        Text {
            id: powerIcon
            anchors.centerIn: parent
            text: "󰐥"
            color: powerMouse.containsMouse ? ThemeTokens.Theme.danger
                                            : ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: 16
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shellState.toggleStatus(root.shellState.statusPower)
        }
    }

}
