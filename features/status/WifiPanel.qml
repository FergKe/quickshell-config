import QtQuick
import Quickshell
import Quickshell.Networking
import "../../theme" as ThemeTokens

Item {
    id: root
    signal dismissed()
    property var selectedNetwork: null
    property int selectedIndex: 0

    function normalizeSelection() {
        selectedIndex = Math.max(0, Math.min(networks.values.length, selectedIndex))
    }

    function setWifiEnabled(value) {
        if (!wifiDevice)
            return
        Networking.wifiEnabled = value
        wifiDevice.scannerEnabled = value
    }

    function moveSelection(step) {
        selectedIndex = Math.max(0, Math.min(networks.values.length,
                                             selectedIndex + step))
        if (selectedIndex > 0) {
            networkList.positionViewAtIndex(selectedIndex - 1, ListView.Contain)
        }
    }

    function activateSelection() {
        if (selectedIndex === 0) {
            setWifiEnabled(!Networking.wifiEnabled)
            return
        }

        Qt.callLater(function() {
            if (networkList.currentItem)
                networkList.currentItem.activate()
        })
    }

    function isPskNetwork(network) {
        return network.security === WifiSecurityType.WpaPsk
                || network.security === WifiSecurityType.Wpa2Psk
                || network.security === WifiSecurityType.Sae
    }

    function rowsHeight() {
        const items = networks.values
        if (items.length === 0)
            return 61

        let height = Math.max(0, items.length - 1) * networkList.spacing
        for (let i = 0; i < items.length; i++) {
            const passwordVisible = selectedNetwork === items[i]
                    && isPskNetwork(items[i]) && !items[i].known && !items[i].connected
            height += passwordVisible ? 90 : 50
        }
        return height
    }

    // 117px is the fixed header/switch/title area plus bottom padding.
    readonly property real desiredHeight: Math.max(180, 117 + rowsHeight())

    function findWifiDevice() {
        const devices = Networking.devices.values
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].type === DeviceType.Wifi)
                return devices[i]
        }
        return null
    }

    readonly property var wifiDevice: findWifiDevice()

    Component.onCompleted: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = true
    }

    onWifiDeviceChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = true
    }

    Component.onDestruction: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = false
    }

    Keys.onEscapePressed: dismissed()
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: activateSelection()
    Keys.onEnterPressed: activateSelection()

    ScriptModel {
        id: networks
        values: {
            if (!root.wifiDevice)
                return []
            const list = root.wifiDevice.networks.values.slice()
            list.sort(function(a, b) {
                if (a.connected !== b.connected)
                    return a.connected ? -1 : 1
                return b.signalStrength - a.signalStrength
            })
            return list
        }
        onValuesChanged: Qt.callLater(root.normalizeSelection)
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 8
        text: "Wi-Fi"
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
        text: "󰤨"
        color: Networking.wifiEnabled ? ThemeTokens.Theme.blue : ThemeTokens.Theme.muted
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
            anchors.right: wifiToggle.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: !root.wifiDevice ? "No Wi-Fi adapter" : Networking.wifiEnabled ? "Enabled" : "Disabled"
            color: ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
        }

        Toggle {
            id: wifiToggle
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            checked: Networking.wifiEnabled
            enabled: !!root.wifiDevice
            onChangeRequested: function(value) {
                root.selectedIndex = 0
                root.setWifiEnabled(value)
            }
        }
    }

    Text {
        id: networkTitle
        anchors.top: powerRow.bottom
        anchors.topMargin: 15
        anchors.left: parent.left
        anchors.leftMargin: 15
        text: root.wifiDevice && root.wifiDevice.scannerEnabled ? "Networks  ·  scanning…" : "Networks"
        color: ThemeTokens.Theme.accent
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }

    ListView {
        id: networkList
        anchors.top: networkTitle.bottom
        anchors.topMargin: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 10
        model: networks
        spacing: 4
        clip: true
        currentIndex: root.selectedIndex - 1

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property var network: modelData
            readonly property bool selected: root.selectedNetwork === network
            readonly property bool keyboardSelected: root.selectedIndex === index + 1
            readonly property bool pskNetwork: root.isPskNetwork(network)
            width: networkList.width
            height: selected && pskNetwork && !network.known && !network.connected ? 90 : 50
            radius: 6
            color: network.connected || selected || keyboardSelected
                   ? ThemeTokens.Theme.surfaceBright : "transparent"
            border.width: keyboardSelected ? 1 : 0
            border.color: ThemeTokens.Theme.activeBorder

            function activate() {
                root.selectedIndex = index + 1
                if (network.connected) {
                    network.disconnect()
                    return
                }
                if (network.known || network.security === WifiSecurityType.Open) {
                    network.connect()
                    return
                }
                if (pskNetwork) {
                    root.selectedNetwork = network
                    Qt.callLater(function() { passwordInput.forceActiveFocus() })
                }
            }

            Behavior on height {
                NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
            }

            Text {
                id: strengthIcon
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.top: parent.top
                anchors.topMargin: 14
                text: row.network.signalStrength > 75 ? "󰤨" : row.network.signalStrength > 50 ? "󰤥" : row.network.signalStrength > 25 ? "󰤢" : "󰤟"
                color: row.network.connected ? ThemeTokens.Theme.success : ThemeTokens.Theme.foreground
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: 15
            }

            Column {
                anchors.left: strengthIcon.right
                anchors.leftMargin: 10
                anchors.right: statusText.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.topMargin: 8
                spacing: 2

                Text {
                    width: parent.width
                    text: row.network.name || "Hidden network"
                    elide: Text.ElideRight
                    color: ThemeTokens.Theme.foreground
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: ThemeTokens.Theme.fontSize
                }

                Text {
                    text: row.network.connected ? "Connected" : row.network.stateChanging ? "Connecting…" : row.network.known ? "Saved" : row.network.security === WifiSecurityType.Open ? "Open" : "Secured"
                    color: row.network.connected ? ThemeTokens.Theme.success : ThemeTokens.Theme.muted
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: 10
                }
            }

            Text {
                id: statusText
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.top: parent.top
                anchors.topMargin: 14
                text: row.network.connected ? "󰄬" : row.network.security === WifiSecurityType.Open ? "" : "󰌾"
                color: row.network.connected ? ThemeTokens.Theme.success : ThemeTokens.Theme.muted
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: 13
            }

            Rectangle {
                id: passwordSurface
                visible: row.selected && row.pskNetwork && !row.network.known && !row.network.connected
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 7
                height: 31
                radius: 5
                color: ThemeTokens.Theme.background
                border.width: 1
                border.color: passwordInput.activeFocus ? ThemeTokens.Theme.activeBorder : ThemeTokens.Theme.surfaceBright

                Text {
                    visible: passwordInput.text.length === 0
                    anchors.left: parent.left
                    anchors.leftMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password — press Enter to connect"
                    color: ThemeTokens.Theme.muted
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: 10
                }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 9
                    anchors.rightMargin: 9
                    verticalAlignment: TextInput.AlignVCenter
                    color: ThemeTokens.Theme.foreground
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: ThemeTokens.Theme.fontSize
                    echoMode: TextInput.Password
                    selectByMouse: true
                    clip: true
                    onAccepted: {
                        if (text.length > 0) {
                            row.network.connectWithPsk(text)
                            text = ""
                            root.selectedNetwork = null
                        }
                    }
                    Keys.onEscapePressed: root.dismissed()
                }
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 50
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    row.activate()
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: networks.values.length === 0
            text: Networking.wifiEnabled ? "No networks found yet" : "Turn Wi-Fi on to scan"
            color: ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
        }
    }
}
