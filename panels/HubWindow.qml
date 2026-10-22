import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../theme" as ThemeTokens
import "../components" as Components
import "../hub" as HubViews

// The hub is one persistent window. Changing state resizes this same surface;
// no launcher window is placed over the clock.
PanelWindow {
    id: hub
    required property QtObject hubState
    readonly property bool launcherOpen: hubState.active === hubState.launcher
    property string displayedMode: "clock"
    property bool contentVisible: true
    readonly property real launcherWidth: 580
    readonly property real launcherHeight: 470
    readonly property real overshootWidth: 596
    readonly property real overshootHeight: 484
    readonly property real clockWidth: clockMeasure.advanceWidth + 24

    onLauncherOpenChanged: {
        contentVisible = false
        openAnimation.stop()
        closeAnimation.stop()
        fadeOutTimer.restart()
    }

    function finishResize() {
        displayedMode = launcherOpen ? "launcher" : "clock"
        contentVisible = true
    }

    anchors.top: true
    // Keep the layer-shell surface stable. Resizing the window itself every
    // animation frame makes Hyprland repeatedly reconfigure and reposition it.
    implicitWidth: overshootWidth
    implicitHeight: overshootHeight
    // Anchor to the physical screen edge instead of being displaced by the
    // full-width top bar's reserved 34px zone.
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: launcherOpen
    color: "transparent"

    HyprlandFocusGrab {
        id: focusGrab
        windows: [hub]
        active: hub.launcherOpen

        onCleared: {
            if (hub.launcherOpen)
                hub.hubState.close()
        }
    }

    // The unused transparent portion of the fixed window remains click-through.
    mask: Region {
        item: hubSurface
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: ThemeTokens.Theme.radius
        bottomRightRadius: ThemeTokens.Theme.radius
    }

    TextMetrics {
        id: clockMeasure
        text: "Wed  30 Sep  ·  23:59"
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: ThemeTokens.Theme.fontSize
        font.weight: Font.DemiBold
    }

    Components.TopSegment {
        id: hubSurface
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: hub.clockWidth
        height: ThemeTokens.Theme.barHeight
        edge: "center"
        clip: true

        Loader {
            id: hubLoader
            anchors.fill: parent
            sourceComponent: hub.displayedMode === "launcher" ? launcherComponent : clockComponent
            opacity: hub.contentVisible ? 1 : 0
            onLoaded: {
                if (hub.displayedMode === "launcher" && item && item.focusSearch)
                    Qt.callLater(item.focusSearch)
            }

            Behavior on opacity {
                NumberAnimation { duration: 140; easing.type: Easing.InOutQuad }
            }
        }

    }

    Timer {
        id: fadeOutTimer
        // Wait for the old content to become fully transparent before moving
        // any edge of the hub.
        interval: 150
        repeat: false
        onTriggered: {
            if (hub.launcherOpen)
                openAnimation.restart()
            else
                closeAnimation.restart()
        }
    }

    SequentialAnimation {
        id: openAnimation

        ParallelAnimation {
            NumberAnimation {
                target: hubSurface; property: "width"
                to: hub.overshootWidth; duration: 280
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: hubSurface; property: "height"
                to: hub.overshootHeight; duration: 300
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: hubSurface; property: "width"
                to: hub.launcherWidth; duration: 110
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: hubSurface; property: "height"
                to: hub.launcherHeight; duration: 110
                easing.type: Easing.InOutQuad
            }
        }

        onFinished: hub.finishResize()
    }

    SequentialAnimation {
        id: closeAnimation

        ParallelAnimation {
            NumberAnimation {
                target: hubSurface; property: "width"
                to: hub.overshootWidth; duration: 100
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: hubSurface; property: "height"
                to: hub.overshootHeight; duration: 100
                easing.type: Easing.OutQuad
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: hubSurface; property: "width"
                to: hub.clockWidth; duration: 300
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: hubSurface; property: "height"
                to: ThemeTokens.Theme.barHeight; duration: 300
                easing.type: Easing.InOutCubic
            }
        }

        onFinished: hub.finishResize()
    }

    Component {
        id: clockComponent

        Item {
            Components.Clock {
                anchors.centerIn: parent
            }
        }
    }

    Component {
        id: launcherComponent

        HubViews.AppLauncher {
            onDismissed: hub.hubState.close()
        }
    }

}
