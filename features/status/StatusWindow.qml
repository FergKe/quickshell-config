import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme" as ThemeTokens
import "../../ui/common" as Common

// One persistent top-right surface. Only the painted box changes size, which
// avoids layer-shell resize jitter while preserving the grow-from-the-bar look.
PanelWindow {
    id: statusWindow
    required property QtObject shellState

    readonly property bool expanded: shellState.statusMode !== shellState.statusCompact
    readonly property real compactWidth: 110
    readonly property real expandedWidth: 410
    readonly property real maximumExpandedHeight: Math.max(178, height - 14)
    readonly property real requestedContentHeight: statusLoader.item
                                                   && statusLoader.item.desiredHeight !== undefined
                                                   ? statusLoader.item.desiredHeight : 178
    readonly property real desiredExpandedHeight: Math.min(maximumExpandedHeight,
                                                           Math.max(ThemeTokens.Theme.barHeight,
                                                                    requestedContentHeight))
    property string displayedMode: "compact"
    property bool contentVisible: true
    property real targetWidth: compactWidth
    property real targetHeight: ThemeTokens.Theme.barHeight
    property real overshootTargetWidth: targetWidth
    property real overshootTargetHeight: targetHeight

    function beginResize() {
        targetWidth = expanded ? expandedWidth : compactWidth
        targetHeight = expanded ? desiredExpandedHeight : ThemeTokens.Theme.barHeight
        overshootTargetWidth = Math.max(statusSurface.width, targetWidth) + 16
        overshootTargetHeight = Math.max(statusSurface.height, targetHeight) + 14
        resizeAnimation.restart()
    }

    function finishResize() {
        contentVisible = true
        Qt.callLater(function() {
            if (statusLoader.item && statusWindow.expanded)
                statusLoader.item.forceActiveFocus()
        })
    }

    onExpandedChanged: beginTransition()
    Connections {
        target: statusWindow.shellState
        function onStatusModeChanged() {
            // onExpandedChanged covers compact <-> expanded. This handles an
            // expanded view changing directly into another expanded view.
            if (statusWindow.expanded
                    && statusWindow.displayedMode !== statusWindow.shellState.statusCompact
                    && statusWindow.displayedMode !== statusWindow.shellState.statusMode)
                statusWindow.beginTransition()
        }
    }

    function beginTransition() {
        contentVisible = false
        resizeAnimation.stop()
        contentResizeAnimation.stop()
        fadeOutTimer.restart()
    }

    anchors {
        top: true
        right: true
    }
    implicitWidth: expandedWidth + 16
    // Keep a stable transparent layer-shell surface large enough for dynamic
    // lists. The mask below leaves everything outside the painted box inert.
    implicitHeight: screen ? screen.height : 900
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: expanded
    color: "transparent"

    HyprlandFocusGrab {
        windows: [statusWindow]
        active: statusWindow.expanded

        onCleared: {
            if (statusWindow.expanded)
                statusWindow.shellState.closeStatus()
        }
    }

    mask: Region {
        item: statusSurface
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: ThemeTokens.Theme.radius
        bottomRightRadius: 0
    }

    Common.TopSegment {
        id: statusSurface
        anchors.top: parent.top
        anchors.right: parent.right
        width: statusWindow.compactWidth
        height: ThemeTokens.Theme.barHeight
        edge: "right"
        clip: true

        Loader {
            id: statusLoader
            anchors.fill: parent
            sourceComponent: statusWindow.displayedMode === statusWindow.shellState.statusBluetooth
                             ? bluetoothComponent
                             : statusWindow.displayedMode === statusWindow.shellState.statusWifi
                               ? wifiComponent
                               : statusWindow.displayedMode === statusWindow.shellState.statusAudio
                                 ? audioComponent
                                 : statusWindow.displayedMode === statusWindow.shellState.statusPower
                                   ? powerComponent : compactComponent
            opacity: statusWindow.contentVisible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 140; easing.type: Easing.InOutQuad }
            }
        }
    }

    Connections {
        target: statusLoader.item

        function onDesiredHeightChanged() {
            // Networks and Bluetooth devices can arrive after scanning starts.
            // Follow the list's natural height even after the open animation.
            if (statusWindow.expanded && statusWindow.contentVisible
                    && statusWindow.displayedMode === statusWindow.shellState.statusMode)
                Qt.callLater(function() { contentResizeAnimation.restart() })
        }
    }

    NumberAnimation {
        id: contentResizeAnimation
        target: statusSurface
        property: "height"
        to: statusWindow.desiredExpandedHeight
        duration: 180
        easing.type: Easing.InOutCubic
    }

    Timer {
        id: fadeOutTimer
        interval: 150
        repeat: false
        onTriggered: {
            // Load the destination invisibly first so its natural height is
            // known before applying the same bounce used by the center hub.
            statusWindow.displayedMode = statusWindow.shellState.statusMode
            Qt.callLater(statusWindow.beginResize)
        }
    }

    SequentialAnimation {
        id: resizeAnimation

        ParallelAnimation {
            NumberAnimation {
                target: statusSurface; property: "width"
                to: statusWindow.overshootTargetWidth; duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: statusSurface; property: "height"
                to: statusWindow.overshootTargetHeight; duration: 220
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: statusSurface; property: "width"
                to: statusWindow.targetWidth; duration: 190
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: statusSurface; property: "height"
                to: statusWindow.targetHeight; duration: 190
                easing.type: Easing.InOutCubic
            }
        }

        onFinished: statusWindow.finishResize()
    }

    Component {
        id: compactComponent

        Item {
            readonly property real desiredHeight: ThemeTokens.Theme.barHeight

            StatusArea {
                anchors.centerIn: parent
                shellState: statusWindow.shellState
            }
        }
    }

    Component {
        id: bluetoothComponent

        BluetoothPanel {
            onDismissed: statusWindow.shellState.closeStatus()
        }
    }

    Component {
        id: wifiComponent

        WifiPanel {
            onDismissed: statusWindow.shellState.closeStatus()
        }
    }

    Component {
        id: audioComponent

        AudioPanel {
            onDismissed: statusWindow.shellState.closeStatus()
        }
    }

    Component {
        id: powerComponent

        PowerPanel {
            onDismissed: statusWindow.shellState.closeStatus()
        }
    }
}
