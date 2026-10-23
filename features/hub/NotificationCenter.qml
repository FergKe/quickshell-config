import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme" as ThemeTokens
import "../../services" as Services

// Hub view bound to the shared notification history. Keeps the
// desiredWidth/desiredHeight/dismissed/takeFocus contract so HubWindow's resize
// transition and focus handling keep working unchanged.
Item {
    id: root

    signal dismissed()
    readonly property real desiredWidth: 480
    readonly property real desiredHeight: 500
    property int selectedIndex: -1

    readonly property var model: Services.NotificationService.historyModel

    function takeFocus() {
        root.forceActiveFocus()
    }

    function moveSelection(step) {
        const count = root.model.values.length
        if (count === 0) {
            selectedIndex = -1
            return
        }
        if (selectedIndex < 0)
            selectedIndex = step > 0 ? 0 : count - 1
        else
            selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + step))
        list.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function removeSelected() {
        const values = root.model.values
        if (selectedIndex >= 0 && selectedIndex < values.length)
            Services.NotificationService.dismiss(values[selectedIndex])
    }

    Component.onCompleted: Qt.callLater(takeFocus)
    Keys.onEscapePressed: root.dismissed()
    Keys.onDownPressed: root.moveSelection(1)
    Keys.onUpPressed: root.moveSelection(-1)
    Keys.onDeletePressed: root.removeSelected()

    // Header: title, DND toggle, clear all.
    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 28

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "󰂚  Notifications"
            color: ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
            font.weight: Font.DemiBold
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Do Not Disturb toggle: suppresses popups, still logs to history.
            Rectangle {
                width: dndLabel.implicitWidth + 24
                height: 26
                radius: 6
                color: Services.NotificationService.dnd
                    ? ThemeTokens.Theme.accent
                    : (dndArea.containsMouse ? ThemeTokens.Theme.surfaceBright
                                             : ThemeTokens.Theme.background)

                Text {
                    id: dndLabel
                    anchors.centerIn: parent
                    text: "󰂛  DND"
                    color: Services.NotificationService.dnd
                        ? ThemeTokens.Theme.background
                        : ThemeTokens.Theme.muted
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: ThemeTokens.Theme.fontSize - 1
                }

                MouseArea {
                    id: dndArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.NotificationService.toggleDnd()
                }
            }

            Rectangle {
                width: clearLabel.implicitWidth + 24
                height: 26
                radius: 6
                visible: root.model.values.length > 0
                color: clearArea.containsMouse ? ThemeTokens.Theme.surfaceBright
                                               : ThemeTokens.Theme.background

                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "󰎟  Clear all"
                    color: ThemeTokens.Theme.muted
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: ThemeTokens.Theme.fontSize - 1
                }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.NotificationService.clearAll()
                }
            }
        }
    }

    // Empty state.
    Text {
        anchors.centerIn: parent
        visible: root.model.values.length === 0
        text: "No notifications"
        color: ThemeTokens.Theme.muted
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: ThemeTokens.Theme.fontSize
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.bottomMargin: 14
        clip: true
        spacing: 6
        model: root.model
        currentIndex: root.selectedIndex

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property var notif: modelData ? modelData.n : null
            readonly property var time: modelData ? modelData.time : null

            width: list.width
            height: rowLayout.implicitHeight + 20
            radius: 6
            color: index === root.selectedIndex ? ThemeTokens.Theme.surfaceBright
                                                 : ThemeTokens.Theme.surface

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.selectedIndex = row.index
            }

            Column {
                id: rowLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 10
                spacing: 3

                Row {
                    width: parent.width
                    spacing: 8

                    IconImage {
                        id: rowIcon
                        width: 18
                        height: 18
                        anchors.verticalCenter: rowHeader.verticalCenter
                        visible: source.toString().length > 0
                        source: {
                            if (row.notif && row.notif.image && row.notif.image.length > 0)
                                return row.notif.image
                            if (row.notif && row.notif.appIcon)
                                return Quickshell.iconPath(row.notif.appIcon, "dialog-information")
                            return ""
                        }
                    }

                    Text {
                        id: rowHeader
                        width: parent.width - rowIcon.width - timeLabel.width
                               - deleteButton.width - parent.spacing * 3
                        text: row.notif ? row.notif.appName : ""
                        elide: Text.ElideRight
                        color: ThemeTokens.Theme.muted
                        font.family: ThemeTokens.Theme.fontFamily
                        font.pixelSize: ThemeTokens.Theme.fontSize - 2
                    }

                    Text {
                        id: timeLabel
                        anchors.verticalCenter: rowHeader.verticalCenter
                        text: row.time ? Qt.formatTime(row.time, "HH:mm") : ""
                        color: ThemeTokens.Theme.muted
                        font.family: ThemeTokens.Theme.fontFamily
                        font.pixelSize: ThemeTokens.Theme.fontSize - 2
                    }

                    Rectangle {
                        id: deleteButton
                        width: 18
                        height: 18
                        radius: 4
                        anchors.verticalCenter: rowHeader.verticalCenter
                        color: deleteArea.containsMouse ? ThemeTokens.Theme.danger
                                                        : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: deleteArea.containsMouse ? ThemeTokens.Theme.background
                                                           : ThemeTokens.Theme.muted
                            font.family: ThemeTokens.Theme.fontFamily
                            font.pixelSize: ThemeTokens.Theme.fontSize - 2
                        }

                        MouseArea {
                            id: deleteArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.NotificationService.dismiss(row.modelData)
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: row.notif ? row.notif.summary : ""
                    visible: text.length > 0
                    elide: Text.ElideRight
                    color: ThemeTokens.Theme.foreground
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: ThemeTokens.Theme.fontSize
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: row.notif ? row.notif.body : ""
                    visible: text.length > 0
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    color: ThemeTokens.Theme.foreground
                    font.family: ThemeTokens.Theme.fontFamily
                    font.pixelSize: ThemeTokens.Theme.fontSize - 1
                }
            }
        }
    }
}
