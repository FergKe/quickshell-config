import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme" as ThemeTokens
import "../components" as Components
import "../status" as StatusViews

// One persistent top-right surface. Only the painted box changes size, which
// avoids layer-shell resize jitter while preserving the grow-from-the-bar look.
PanelWindow {
    id: statusWindow
    required property QtObject statusState

    readonly property bool expanded: statusState.active !== statusState.compact
    readonly property real compactWidth: 110
    readonly property real expandedWidth: 410
    readonly property real maximumExpandedHeight: Math.max(178, height - 14)
    readonly property real requestedContentHeight: statusLoader.item
                                                   && statusLoader.item.desiredHeight !== undefined
                                                   ? statusLoader.item.desiredHeight : 178
    readonly property real targetHeight: Math.min(maximumExpandedHeight,
                                                  Math.max(ThemeTokens.Theme.barHeight,
                                                           requestedContentHeight))
    property string displayedMode: "compact"
    property bool contentVisible: true
    property real closeOvershootWidth: 0
    property real closeOvershootHeight: 0

    function finishResize() {
        displayedMode = statusState.active
        contentVisible = true
        Qt.callLater(function() {
            if (statusLoader.item && statusWindow.expanded)
                statusLoader.item.forceActiveFocus()
        })
    }

    onExpandedChanged: beginTransition()
    Connections {
        target: statusWindow.statusState
        function onActiveChanged() {
            // onExpandedChanged covers compact <-> expanded. This handles an
            // expanded view changing directly into another expanded view.
            if (statusWindow.expanded && statusWindow.displayedMode !== statusWindow.statusState.active)
                statusWindow.beginTransition()
        }
    }

    function beginTransition() {
        contentVisible = false
        openAnimation.stop()
        closeAnimation.stop()
        fadeOutTimer.restart()
    }

    anchors {
        top: true
        right: true
    }
    implicitWidth: 424
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
                statusWindow.statusState.close()
        }
    }

    mask: Region {
        item: statusSurface
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: ThemeTokens.Theme.radius
        bottomRightRadius: 0
    }

    Components.TopSegment {
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
            sourceComponent: statusWindow.displayedMode === statusWindow.statusState.bluetooth
                             ? bluetoothComponent
                             : statusWindow.displayedMode === statusWindow.statusState.wifi
                               ? wifiComponent
                               : statusWindow.displayedMode === statusWindow.statusState.audio
                                 ? audioComponent
                                 : statusWindow.displayedMode === statusWindow.statusState.power
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
                    && statusWindow.displayedMode === statusWindow.statusState.active)
                Qt.callLater(function() { contentResizeAnimation.restart() })
        }
    }

    NumberAnimation {
        id: contentResizeAnimation
        target: statusSurface
        property: "height"
        to: statusWindow.targetHeight
        duration: 180
        easing.type: Easing.InOutCubic
    }

    Timer {
        id: fadeOutTimer
        interval: 150
        repeat: false
        onTriggered: {
            if (statusWindow.expanded) {
                // Load the destination invisibly first so its natural list
                // height is known before the box begins to grow.
                statusWindow.displayedMode = statusWindow.statusState.active
                Qt.callLater(function() { openAnimation.restart() })
            } else {
                statusWindow.closeOvershootWidth = Math.min(statusWindow.width, statusSurface.width + 12)
                statusWindow.closeOvershootHeight = Math.min(statusWindow.height, statusSurface.height + 12)
                closeAnimation.restart()
            }
        }
    }

    SequentialAnimation {
        id: openAnimation

        ParallelAnimation {
            NumberAnimation {
                target: statusSurface; property: "width"
                to: statusWindow.expandedWidth + 14; duration: 280
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: statusSurface; property: "height"
                to: statusWindow.targetHeight + 14; duration: 300
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: statusSurface; property: "width"
                to: statusWindow.expandedWidth; duration: 110
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: statusSurface; property: "height"
                to: statusWindow.targetHeight; duration: 110
                easing.type: Easing.InOutQuad
            }
        }

        onFinished: statusWindow.finishResize()
    }

    SequentialAnimation {
        id: closeAnimation

        ParallelAnimation {
            NumberAnimation {
                target: statusSurface; property: "width"
                to: statusWindow.closeOvershootWidth; duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: statusSurface; property: "height"
                to: statusWindow.closeOvershootHeight; duration: 100
                easing.type: Easing.OutQuad
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: statusSurface; property: "width"
                to: statusWindow.compactWidth; duration: 300
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: statusSurface; property: "height"
                to: ThemeTokens.Theme.barHeight; duration: 300
                easing.type: Easing.InOutCubic
            }
        }

        onFinished: statusWindow.finishResize()
    }

    Component {
        id: compactComponent

        Item {
            readonly property real desiredHeight: ThemeTokens.Theme.barHeight

            Components.StatusArea {
                anchors.centerIn: parent
                statusState: statusWindow.statusState
            }
        }
    }

    Component {
        id: bluetoothComponent

        StatusViews.BluetoothPanel {
            onDismissed: statusWindow.statusState.close()
        }
    }

    Component {
        id: wifiComponent

        StatusViews.WifiPanel {
            onDismissed: statusWindow.statusState.close()
        }
    }

    Component {
        id: audioComponent

        StatusViews.AudioPanel {
            onDismissed: statusWindow.statusState.close()
        }
    }

    Component {
        id: powerComponent

        StatusViews.PowerPanel {
            onDismissed: statusWindow.statusState.close()
        }
    }
}
