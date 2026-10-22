import QtQuick
import Quickshell.Io
import "../../theme" as ThemeTokens

Item {
    id: root
    signal dismissed()
    readonly property real desiredHeight: 222
    property string pendingAction: ""
    property int selectedIndex: 0

    function moveSelection(step) {
        selectedIndex = Math.max(0, Math.min(2, selectedIndex + step))
    }

    function activateSelection() {
        if (selectedIndex === 0)
            invoke("sleep", ["systemctl", "suspend"], false)
        else if (selectedIndex === 1)
            invoke("restart", ["systemctl", "reboot"], true)
        else
            invoke("poweroff", ["systemctl", "poweroff"], true)
    }

    function invoke(action, command, confirm) {
        if (confirm && pendingAction !== action) {
            pendingAction = action
            confirmationTimer.restart()
            return
        }

        confirmationTimer.stop()
        pendingAction = ""
        actionProcess.command = command
        actionProcess.running = true
    }

    Keys.onEscapePressed: dismissed()
    Keys.onUpPressed: moveSelection(-1)
    Keys.onDownPressed: moveSelection(1)
    Keys.onReturnPressed: activateSelection()
    Keys.onEnterPressed: activateSelection()

    Timer {
        id: confirmationTimer
        interval: 4000
        repeat: false
        onTriggered: root.pendingAction = ""
    }

    Process {
        id: actionProcess
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.top: parent.top
        anchors.topMargin: 8
        text: "Power"
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
        text: "󰐥"
        color: ThemeTokens.Theme.danger
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: 17
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 48
        anchors.margins: 10
        spacing: 6

        PowerAction {
            width: parent.width
            navigationIndex: 0
            selected: root.selectedIndex === 0
            icon: "󰒲"
            title: "Sleep"
            detail: "Suspend this computer"
            onActivated: root.invoke("sleep", ["systemctl", "suspend"], false)
        }

        PowerAction {
            width: parent.width
            navigationIndex: 1
            selected: root.selectedIndex === 1
            icon: "󰜉"
            title: "Restart"
            detail: root.pendingAction === "restart"
                    ? "Click again to confirm"
                    : "Restart the operating system"
            dangerous: root.pendingAction === "restart"
            confirming: root.pendingAction === "restart"
            onActivated: root.invoke("restart", ["systemctl", "reboot"], true)
        }

        PowerAction {
            width: parent.width
            navigationIndex: 2
            selected: root.selectedIndex === 2
            icon: "󰐥"
            title: "Power off"
            detail: root.pendingAction === "poweroff"
                    ? "Click again to confirm"
                    : "Shut down this computer"
            dangerous: true
            confirming: root.pendingAction === "poweroff"
            onActivated: root.invoke("poweroff", ["systemctl", "poweroff"], true)
        }
    }

    component PowerAction: Rectangle {
        id: action
        required property string icon
        required property string title
        required property string detail
        required property int navigationIndex
        property bool dangerous: false
        property bool confirming: false
        property bool selected: false
        signal activated()

        height: 50
        radius: 6
        color: actionMouse.containsMouse || selected || confirming
               ? ThemeTokens.Theme.surfaceBright : "transparent"
        border.width: selected || confirming ? 1 : 0
        border.color: confirming ? ThemeTokens.Theme.danger
                                 : ThemeTokens.Theme.activeBorder

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.verticalCenter: parent.verticalCenter
            text: action.icon
            color: action.dangerous ? ThemeTokens.Theme.danger
                                    : ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: 17
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 44
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: action.title
                color: action.dangerous ? ThemeTokens.Theme.danger
                                        : ThemeTokens.Theme.foreground
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: ThemeTokens.Theme.fontSize
            }

            Text {
                text: action.detail
                color: action.confirming ? ThemeTokens.Theme.danger
                                         : ThemeTokens.Theme.muted
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: 10
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.selectedIndex = action.navigationIndex
                action.activated()
            }
        }
    }
}
