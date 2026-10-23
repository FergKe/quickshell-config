import QtQuick
import Quickshell
import "../../theme" as ThemeTokens
import "../../services" as Services

// Standalone popup surface. Independent of the hub/status mutual-exclusion state
// so popups appear over anything. Like the other shell windows it reserves no
// exclusive zone (no window reflow) and floats above Hyprland clients. It never
// takes focus, and the mask collapses to the painted cards so clicks pass
// straight through everywhere else — including the whole surface when idle.
PanelWindow {
    id: popupWindow

    readonly property real popupWidth: 380
    // Sit just below the status component in the top-right corner.
    readonly property real topOffset: ThemeTokens.Theme.barHeight + ThemeTokens.Theme.spacing

    anchors {
        top: true
        right: true
    }
    implicitWidth: popupWidth
    implicitHeight: screen ? screen.height : 900
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: false
    color: "transparent"

    // Only the stack of cards is interactive. When empty, the column has zero
    // size, so the whole surface is click-through.
    mask: Region {
        item: column
    }

    Column {
        id: column
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: popupWindow.topOffset
        // Flush to the right screen edge so popups read as emerging from it.
        anchors.rightMargin: 0
        width: popupWindow.popupWidth
        spacing: ThemeTokens.Theme.spacing

        Repeater {
            model: Services.NotificationService.popupModel

            delegate: Popup {
                required property var modelData
                width: popupWindow.popupWidth
                entry: modelData
            }
        }
    }
}
