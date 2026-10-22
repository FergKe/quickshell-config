import QtQuick
import "../../theme" as ThemeTokens

Item {
    id: root
    // "left" keeps only its lower-right curve; "right" is its mirror;
    // "center" has two lower curves and is square against the top screen edge.
    property string edge: "center"
    default property alias content: content.data

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: ThemeTokens.Theme.radius
        color: ThemeTokens.Theme.surface
    }

    // A rounded Rectangle is overpainted at the corners that must meet the
    // screen edge squarely. This avoids a visible transparent fringe.
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: ThemeTokens.Theme.radius
        color: surface.color
    }

    Rectangle {
        visible: root.edge === "left"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: ThemeTokens.Theme.radius
        color: surface.color
    }

    Rectangle {
        visible: root.edge === "right"
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: ThemeTokens.Theme.radius
        color: surface.color
    }

    Canvas {
        id: outline
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            const radius = ThemeTokens.Theme.radius
            const inset = 1
            const right = width - inset
            const bottom = height - inset

            ctx.clearRect(0, 0, width, height)
            ctx.beginPath()

            if (root.edge === "right") {
                // The right and top edges meet the screen, so only draw the
                // exposed left and bottom outline.
                ctx.moveTo(inset, inset)
                ctx.lineTo(inset, bottom - radius)
                ctx.quadraticCurveTo(inset, bottom, inset + radius, bottom)
                ctx.lineTo(right, bottom)
            } else if (root.edge === "left") {
                // The left and top edges meet the screen.
                ctx.moveTo(right, inset)
                ctx.lineTo(right, bottom - radius)
                ctx.quadraticCurveTo(right, bottom, right - radius, bottom)
                ctx.lineTo(inset, bottom)
            } else {
                // The center hub touches only the top edge of the screen.
                ctx.moveTo(inset, inset)
                ctx.lineTo(inset, bottom - radius)
                ctx.quadraticCurveTo(inset, bottom, inset + radius, bottom)
                ctx.lineTo(right - radius, bottom)
                ctx.quadraticCurveTo(right, bottom, right, bottom - radius)
                ctx.lineTo(right, inset)
            }

            ctx.strokeStyle = ThemeTokens.Theme.activeBorder
            ctx.lineWidth = 2
            ctx.stroke()
        }
    }

    Item {
        id: content
        anchors.fill: parent
    }
}
