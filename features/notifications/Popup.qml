import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../../theme" as ThemeTokens
import "../../services" as Services

// A single popup card. Slides in from the right edge, dwells, then slides back
// out and removes itself from the service's popup queue. Critical notifications
// never auto-expire; hovering pauses the dwell timer.
Item {
    id: popup

    required property var entry
    readonly property var notif: entry ? entry.n : null
    readonly property bool critical: notif
        && notif.urgency === NotificationUrgency.Critical

    // Honor the sender's requested timeout: a positive value is milliseconds,
    // 0 means never expire, and -1 (the default) falls back to our own. Critical
    // notifications never auto-dismiss.
    readonly property int effectiveTimeout: {
        if (critical)
            return 0
        const t = notif ? notif.expireTimeout : -1
        if (t === 0)
            return 0
        if (t > 0)
            return t
        return Services.NotificationService.defaultTimeout
    }
    readonly property bool autoDismiss: effectiveTimeout > 0

    implicitHeight: card.height

    // Animate an x offset so the card flies over Hyprland windows without the
    // window itself moving. Starts off-screen to the right.
    property real slideX: width
    transform: Translate { x: popup.slideX }
    opacity: 0

    Behavior on slideX {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
    }

    Component.onCompleted: {
        slideX = 0
        opacity = 1
        if (autoDismiss)
            dwell.start()
    }

    function close() {
        slideX = width
        opacity = 0
        removeTimer.start()
    }

    Timer {
        id: dwell
        interval: popup.effectiveTimeout
        onTriggered: popup.close()
    }

    Timer {
        id: removeTimer
        interval: 240
        onTriggered: Services.NotificationService.dismissPopup(popup.entry)
    }

    Rectangle {
        id: card
        width: parent.width
        height: layout.implicitHeight + 24
        color: ThemeTokens.Theme.surface
        // Rounded on the exposed (left) side, square against the right screen
        // edge — matching how the bar components meet the screen.
        topLeftRadius: ThemeTokens.Theme.radius
        bottomLeftRadius: ThemeTokens.Theme.radius
        topRightRadius: 0
        bottomRightRadius: 0

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onEntered: dwell.stop()
            onExited: if (popup.autoDismiss) dwell.restart()
            onClicked: {
                // Invoke the default action if the app provided one.
                const actions = popup.notif ? popup.notif.actions : []
                for (let i = 0; i < actions.length; i++) {
                    if (actions[i].identifier === "default") {
                        Services.NotificationService.invokeAction(popup.entry, actions[i])
                        return
                    }
                }
            }
        }

        // Outline on the exposed edges only, left open on the right so the card
        // reads as coming out of the screen edge. Standard colour matches the
        // other components (activeBorder); critical popups use the danger hue.
        Canvas {
            id: outline
            anchors.fill: parent
            readonly property color stroke: popup.critical
                ? ThemeTokens.Theme.danger
                : ThemeTokens.Theme.activeBorder

            onStrokeChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                const r = ThemeTokens.Theme.radius
                const inset = 1
                const right = width
                const bottom = height - inset

                ctx.clearRect(0, 0, width, height)
                ctx.beginPath()
                ctx.moveTo(right, inset)
                ctx.lineTo(inset + r, inset)
                ctx.quadraticCurveTo(inset, inset, inset, inset + r)
                ctx.lineTo(inset, bottom - r)
                ctx.quadraticCurveTo(inset, bottom, inset + r, bottom)
                ctx.lineTo(right, bottom)

                ctx.strokeStyle = outline.stroke
                ctx.lineWidth = 2
                ctx.stroke()
            }
        }

        Column {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 6

            Row {
                width: parent.width
                spacing: 10

                Rectangle {
                    id: closeButton
                    width: 20
                    height: 20
                    radius: 4
                    anchors.verticalCenter: header.verticalCenter
                    color: closeArea.containsMouse
                        ? ThemeTokens.Theme.surfaceBright
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: ThemeTokens.Theme.muted
                        font.family: ThemeTokens.Theme.fontFamily
                        font.pixelSize: ThemeTokens.Theme.fontSize
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.close()
                    }
                }

                IconImage {
                    id: icon
                    width: 28
                    height: 28
                    anchors.verticalCenter: header.verticalCenter
                    visible: source.toString().length > 0
                    // Prefer the notification's own image (album art, avatars,
                    // screenshots); fall back to the sending app's icon.
                    source: {
                        if (popup.notif && popup.notif.image && popup.notif.image.length > 0)
                            return popup.notif.image
                        if (popup.notif && popup.notif.appIcon)
                            return Quickshell.iconPath(popup.notif.appIcon, "dialog-information")
                        return ""
                    }
                }

                Column {
                    id: header
                    width: parent.width - icon.width - closeButton.width - parent.spacing * 2
                    spacing: 2

                    Text {
                        width: parent.width
                        text: popup.notif ? popup.notif.appName : ""
                        visible: text.length > 0
                        elide: Text.ElideRight
                        color: ThemeTokens.Theme.muted
                        font.family: ThemeTokens.Theme.fontFamily
                        font.pixelSize: ThemeTokens.Theme.fontSize - 2
                    }

                    Text {
                        width: parent.width
                        text: popup.notif ? popup.notif.summary : ""
                        elide: Text.ElideRight
                        color: ThemeTokens.Theme.foreground
                        font.family: ThemeTokens.Theme.fontFamily
                        font.pixelSize: ThemeTokens.Theme.fontSize
                        font.weight: Font.DemiBold
                    }
                }
            }

            Text {
                width: parent.width
                text: popup.notif ? popup.notif.body : ""
                visible: text.length > 0
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.StyledText
                color: ThemeTokens.Theme.foreground
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: ThemeTokens.Theme.fontSize - 1
            }

            Row {
                width: parent.width
                spacing: 8
                visible: popup.notif && popup.notif.actions.length > 0

                Repeater {
                    model: popup.notif ? popup.notif.actions : []

                    delegate: Rectangle {
                        id: actionButton
                        required property var modelData
                        readonly property var action: modelData
                        // The default action is reachable by clicking the card.
                        visible: action.identifier !== "default"
                        width: visible ? actionLabel.implicitWidth + 20 : 0
                        height: visible ? 26 : 0
                        radius: 5
                        color: actionArea.containsMouse
                            ? ThemeTokens.Theme.surfaceBright
                            : ThemeTokens.Theme.background

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: actionButton.action.text
                            color: ThemeTokens.Theme.foreground
                            font.family: ThemeTokens.Theme.fontFamily
                            font.pixelSize: ThemeTokens.Theme.fontSize - 1
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Services.NotificationService.invokeAction(
                                popup.entry, actionButton.action)
                        }
                    }
                }
            }
        }
    }
}
