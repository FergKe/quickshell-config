import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../theme" as ThemeTokens
import "../../ui/common" as Common

// One persistent layer-shell surface hosts every hub mode. Content declares
// its preferred size through HubContent, keeping this window mode-agnostic.
PanelWindow {
    id: hub

    required property QtObject shellState
    // Keep rendering the previous mode while it fades out. The destination is
    // assigned by fadeOutTimer before the resize begins.
    property string displayedMode: shellState.hubClock
    property bool contentVisible: true
    property real targetWidth: ThemeTokens.Theme.barHeight
    property real targetHeight: ThemeTokens.Theme.barHeight
    property real overshootTargetWidth: targetWidth
    property real overshootTargetHeight: targetHeight
    readonly property bool interactive: shellState.hubMode !== shellState.hubClock

    function syncInitialSize() {
        if (content.desiredWidth <= 0 || content.desiredHeight <= 0)
            return
        hubSurface.width = content.desiredWidth
        hubSurface.height = content.desiredHeight
    }

    function beginResize() {
        targetWidth = content.desiredWidth
        targetHeight = content.desiredHeight
        overshootTargetWidth = Math.max(hubSurface.width, targetWidth) + 16
        overshootTargetHeight = Math.max(hubSurface.height, targetHeight) + 14
        resizeAnimation.restart()
    }

    function finishResize() {
        contentVisible = true
        if (interactive)
            Qt.callLater(content.takeFocus)
    }

    onDisplayedModeChanged: Qt.callLater(function() {
        if (!fadeOutTimer.running && !resizeAnimation.running && contentVisible)
            syncInitialSize()
    })

    Connections {
        target: shellState
        function onHubModeChanged() {
            hub.contentVisible = false
            resizeAnimation.stop()
            fadeOutTimer.restart()
        }
    }

    anchors.top: true
    // Keep the layer-shell allocation stable while the visible surface moves.
    implicitWidth: 620
    implicitHeight: 520
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: interactive
    color: "transparent"

    HyprlandFocusGrab {
        windows: [hub]
        active: hub.interactive
        onCleared: {
            if (hub.interactive)
                hub.shellState.closeHub()
        }
    }

    mask: Region {
        item: hubSurface
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: ThemeTokens.Theme.radius
        bottomRightRadius: ThemeTokens.Theme.radius
    }

    Common.TopSegment {
        id: hubSurface
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: ThemeTokens.Theme.barHeight
        height: ThemeTokens.Theme.barHeight
        edge: "center"
        clip: true

        HubContent {
            id: content
            anchors.fill: parent
            shellState: hub.shellState
            mode: hub.displayedMode
            opacity: hub.contentVisible ? 1 : 0
            onDismissed: hub.shellState.closeHub()

            Behavior on opacity {
                NumberAnimation { duration: 140; easing.type: Easing.InOutQuad }
            }

            Component.onCompleted: Qt.callLater(hub.syncInitialSize)
        }
    }

    Timer {
        id: fadeOutTimer
        interval: 150
        repeat: false
        onTriggered: {
            hub.displayedMode = hub.shellState.hubMode
            Qt.callLater(hub.beginResize)
        }
    }

    SequentialAnimation {
        id: resizeAnimation

        ParallelAnimation {
            NumberAnimation {
                target: hubSurface; property: "width"
                to: hub.overshootTargetWidth; duration: 200
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: hubSurface; property: "height"
                to: hub.overshootTargetHeight; duration: 220
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: hubSurface; property: "width"
                to: hub.targetWidth; duration: 190
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: hubSurface; property: "height"
                to: hub.targetHeight; duration: 190
                easing.type: Easing.InOutCubic
            }
        }

        onFinished: hub.finishResize()
    }
}
