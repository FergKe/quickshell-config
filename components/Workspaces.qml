import QtQuick
import Quickshell.Hyprland
import "../theme" as ThemeTokens

Row {
    id: root
    spacing: 4

    readonly property int highestWorkspace: {
        let highest = 5
        const workspaces = Hyprland.workspaces.values
        for (let i = 0; i < workspaces.length; i++) {
            if (workspaces[i].id > highest)
                highest = workspaces[i].id
        }
        return highest
    }

    function workspaceFor(number) {
        const workspaces = Hyprland.workspaces.values
        for (let i = 0; i < workspaces.length; i++) {
            if (workspaces[i].id === number)
                return workspaces[i]
        }
        return null
    }

    Repeater {
        model: root.highestWorkspace

        delegate: Rectangle {
            required property int index
            readonly property int workspaceNumber: index + 1
            readonly property var workspace: root.workspaceFor(workspaceNumber)
            readonly property bool selected: workspace ? workspace.focused : false
            readonly property bool occupied: workspace ? workspace.toplevels.count > 0 : false

            width: selected ? 26 : 20
            height: 20
            radius: height / 2
            color: selected ? ThemeTokens.Theme.accent
                            : occupied ? ThemeTokens.Theme.surfaceBright
                                       : ThemeTokens.Theme.surface

            Behavior on width { NumberAnimation { duration: 140 } }
            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                anchors.centerIn: parent
                text: workspaceNumber
                color: root.enabled && selected ? ThemeTokens.Theme.background : ThemeTokens.Theme.muted
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: 11
                font.bold: selected
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (workspace)
                        workspace.activate()
                    else
                        Hyprland.dispatch("workspace " + workspaceNumber)
                }
            }
        }
    }
}
