import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../theme" as ThemeTokens

Item {
    id: root
    signal dismissed()
    readonly property var adapter: Bluetooth.defaultAdapter
    property bool ownsDiscovery: false
    property int scanSecondsRemaining: 0
    property int selectedIndex: 0
    // 97px accounts for the header, power row, margins, and lower padding.
    readonly property real desiredHeight: Math.max(180, 97 + deviceColumn.implicitHeight)

    onSelectedIndexChanged: {
        if (selectedIndex === pairedDevices.values.length + 1)
            Qt.callLater(function() { deviceFlick.ensureVisible(availableHeader) })
    }

    function normalizeSelection() {
        const lastIndex = 1 + pairedDevices.values.length + availableDevices.values.length
        selectedIndex = Math.max(0, Math.min(lastIndex, selectedIndex))
    }

    function moveSelection(step) {
        const lastIndex = 1 + pairedDevices.values.length + availableDevices.values.length
        selectedIndex = Math.max(0, Math.min(lastIndex, selectedIndex + step))
    }

    function setBluetoothEnabled(value) {
        if (!adapter)
            return
        if (!value)
            stopOwnedDiscovery()
        adapter.enabled = value
    }

    function activateSelection() {
        if (selectedIndex === 0) {
            if (adapter)
                setBluetoothEnabled(!adapter.enabled)
            return
        }
        if (selectedIndex <= pairedDevices.values.length) {
            const device = pairedDevices.values[selectedIndex - 1]
            if (device.connected)
                device.disconnect()
            else
                device.connect()
            return
        }

        if (selectedIndex === pairedDevices.values.length + 1) {
            toggleDiscovery()
            return
        }

        const availableIndex = selectedIndex - pairedDevices.values.length - 2
        if (availableIndex >= 0 && availableIndex < availableDevices.values.length) {
            const device = availableDevices.values[availableIndex]
            if (device.pairing)
                device.cancelPair()
            else
                device.pair()
        }
    }

    function startDiscovery() {
        if (!adapter || !adapter.enabled || adapter.discovering)
            return

        ownsDiscovery = true
        scanSecondsRemaining = 30
        adapter.discovering = true
        discoveryCountdown.restart()
    }

    function stopOwnedDiscovery() {
        discoveryCountdown.stop()
        scanSecondsRemaining = 0

        if (adapter && ownsDiscovery && adapter.discovering)
            adapter.discovering = false

        ownsDiscovery = false
    }

    function toggleDiscovery() {
        if (ownsDiscovery)
            stopOwnedDiscovery()
        else
            startDiscovery()
    }

    Component.onDestruction: stopOwnedDiscovery()
    Keys.onEscapePressed: dismissed()
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: activateSelection()
    Keys.onEnterPressed: activateSelection()

    Timer {
        id: discoveryCountdown
        interval: 1000
        repeat: true

        onTriggered: {
            if (!root.adapter || !root.adapter.discovering) {
                root.ownsDiscovery = false
                root.scanSecondsRemaining = 0
                stop()
            } else if (root.scanSecondsRemaining <= 1) {
                root.stopOwnedDiscovery()
            } else {
                root.scanSecondsRemaining--
            }
        }
    }

    Connections {
        target: root.adapter

        function onDiscoveringChanged() {
            if (root.adapter && !root.adapter.discovering) {
                discoveryCountdown.stop()
                root.ownsDiscovery = false
                root.scanSecondsRemaining = 0
            }
        }
    }

    ScriptModel {
        id: pairedDevices
        values: root.adapter ? root.adapter.devices.values.filter(function(device) {
            return device.paired
        }) : []
        onValuesChanged: Qt.callLater(root.normalizeSelection)
    }

    ScriptModel {
        id: availableDevices
        values: root.adapter ? root.adapter.devices.values.filter(function(device) {
            return !device.paired
        }) : []
        onValuesChanged: Qt.callLater(root.normalizeSelection)
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 8
        text: "Bluetooth"
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
        text: "󰂯"
        color: root.adapter && root.adapter.enabled ? ThemeTokens.Theme.blue : ThemeTokens.Theme.muted
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: 17
    }

    Rectangle {
        id: powerRow
        anchors.top: parent.top
        anchors.topMargin: 48
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 15
        height: 24
        radius: 5
        color: root.selectedIndex === 0 ? ThemeTokens.Theme.surfaceBright : "transparent"
        border.width: root.selectedIndex === 0 ? 1 : 0
        border.color: ThemeTokens.Theme.activeBorder

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 5
            anchors.right: bluetoothToggle.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.adapter ? (root.adapter.enabled ? "Enabled" : "Disabled") : "No Bluetooth adapter"
            color: ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
        }

        Toggle {
            id: bluetoothToggle
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            checked: root.adapter ? root.adapter.enabled : false
            enabled: !!root.adapter
            onChangeRequested: function(value) {
                root.selectedIndex = 0
                root.setBluetoothEnabled(value)
            }
        }
    }

    Flickable {
        id: deviceFlick
        anchors.top: powerRow.bottom
        anchors.topMargin: 13
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        contentHeight: deviceColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        function ensureVisible(item) {
            const itemTop = item.y
            const itemBottom = itemTop + item.height
            if (itemTop < contentY)
                contentY = itemTop
            else if (itemBottom > contentY + height)
                contentY = itemBottom - height
        }

        Column {
            id: deviceColumn
            width: parent.width
            spacing: 4

            Text {
                width: parent.width
                leftPadding: 5
                text: "Paired devices"
                color: ThemeTokens.Theme.accent
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                visible: pairedDevices.values.length === 0
                width: parent.width
                leftPadding: 8
                topPadding: 6
                bottomPadding: 8
                text: "No paired devices"
                color: ThemeTokens.Theme.muted
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: ThemeTokens.Theme.fontSize
            }

            Repeater {
                model: pairedDevices

                delegate: DeviceRow {
                    required property var modelData
                    required property int index
                    width: deviceColumn.width
                    device: modelData
                    navigationIndex: 1 + index
                    keyboardSelected: root.selectedIndex === navigationIndex
                    actionText: device.connected ? "Disconnect" : "Connect"
                    onActionRequested: {
                        if (device.connected)
                            device.disconnect()
                        else
                            device.connect()
                    }
                }
            }

            Item {
                id: availableHeader
                width: parent.width
                height: 38

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 5
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 7
                    text: "Available devices"
                    color: ThemeTokens.Theme.accent
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    id: scanButton
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.bottom: parent.bottom
                    width: scanLabel.implicitWidth + 16
                    height: 26
                    radius: 5
                    opacity: root.adapter && root.adapter.enabled ? 1 : 0.45
                    color: scanMouse.containsMouse ? ThemeTokens.Theme.surfaceBright
                                                   : ThemeTokens.Theme.background
                    border.width: root.selectedIndex === pairedDevices.values.length + 1 ? 1 : 0
                    border.color: ThemeTokens.Theme.activeBorder

                    Text {
                        id: scanLabel
                        anchors.centerIn: parent
                        text: root.adapter && root.adapter.discovering
                              ? root.ownsDiscovery
                                ? "Stop  " + root.scanSecondsRemaining + "s"
                                : "Scanning"
                              : "Scan  30s"
                        color: ThemeTokens.Theme.foreground
                        font.family: ThemeTokens.Theme.fontFamily
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        enabled: root.adapter && root.adapter.enabled
                                 && (!root.adapter.discovering || root.ownsDiscovery)
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            root.selectedIndex = pairedDevices.values.length + 1
                            root.toggleDiscovery()
                        }
                    }
                }
            }

            Text {
                visible: availableDevices.values.length === 0
                width: parent.width
                leftPadding: 8
                topPadding: 6
                text: !root.adapter || !root.adapter.enabled
                      ? "Turn Bluetooth on to scan"
                      : root.adapter.discovering
                        ? "Looking for devices…"
                        : "Select Scan to find devices"
                color: ThemeTokens.Theme.muted
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: ThemeTokens.Theme.fontSize
            }

            Repeater {
                model: availableDevices

                delegate: DeviceRow {
                    required property var modelData
                    required property int index
                    width: deviceColumn.width
                    device: modelData
                    navigationIndex: 2 + pairedDevices.values.length + index
                    keyboardSelected: root.selectedIndex === navigationIndex
                    actionText: device.pairing ? "Cancel" : "Pair"
                    onActionRequested: {
                        if (device.pairing)
                            device.cancelPair()
                        else
                            device.pair()
                    }
                }
            }
        }
    }

    component DeviceRow: Rectangle {
        id: row
        required property var device
        required property int navigationIndex
        property string actionText: ""
        property bool keyboardSelected: false
        signal actionRequested()

        height: 49
        radius: 6
        color: device.connected || keyboardSelected
               ? ThemeTokens.Theme.surfaceBright : "transparent"
        border.width: keyboardSelected ? 1 : 0
        border.color: ThemeTokens.Theme.activeBorder

        onKeyboardSelectedChanged: {
            if (keyboardSelected)
                Qt.callLater(function() { deviceFlick.ensureVisible(row) })
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            text: "󰂯"
            color: row.device.connected ? ThemeTokens.Theme.blue : ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: 17
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 43
            anchors.right: action.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: row.device.name || "Unknown device"
                elide: Text.ElideRight
                color: ThemeTokens.Theme.foreground
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: ThemeTokens.Theme.fontSize
            }

            Text {
                text: row.device.connected ? "Connected" : row.device.pairing ? "Pairing…" : row.device.paired ? "Paired" : "Available"
                color: row.device.connected ? ThemeTokens.Theme.success : ThemeTokens.Theme.muted
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: 10
            }
        }

        Rectangle {
            id: action
            anchors.right: parent.right
            anchors.rightMargin: 7
            anchors.verticalCenter: parent.verticalCenter
            width: actionLabel.implicitWidth + 16
            height: 26
            radius: 5
            color: actionMouse.containsMouse ? ThemeTokens.Theme.surfaceBright : ThemeTokens.Theme.background

            Text {
                id: actionLabel
                anchors.centerIn: parent
                text: row.actionText
                color: ThemeTokens.Theme.foreground
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: 10
            }

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.selectedIndex = row.navigationIndex
                    row.actionRequested()
                }
            }
        }
    }
}
