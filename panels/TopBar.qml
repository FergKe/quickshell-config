import QtQuick
import Quickshell
import "../theme" as ThemeTokens
import "../components" as Components

PanelWindow {
    id: panel

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: ThemeTokens.Theme.barHeight
    exclusiveZone: ThemeTokens.Theme.barHeight
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Components.TopSegment {
            anchors.left: parent.left
            anchors.top: parent.top
            edge: "left"
            width: workspaces.implicitWidth + 30
            height: ThemeTokens.Theme.barHeight

            Components.Workspaces {
                id: workspaces
                anchors.centerIn: parent
            }
        }
    }
}
