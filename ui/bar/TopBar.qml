import QtQuick
import Quickshell
import "../../theme" as ThemeTokens
import "../common" as Common

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

        Common.TopSegment {
            anchors.left: parent.left
            anchors.top: parent.top
            edge: "left"
            width: workspaces.implicitWidth + 30
            height: ThemeTokens.Theme.barHeight

            Workspaces {
                id: workspaces
                anchors.centerIn: parent
            }
        }
    }
}
