import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../theme" as ThemeTokens

Item {
    id: root

    signal dismissed()
    readonly property real desiredWidth: 580
    readonly property real desiredHeight: 470
    property int selectedIndex: 0
    property string query: ""

    function takeFocus() {
        search.forceActiveFocus()
    }

    function fuzzyScore(haystack, needle) {
        const source = haystack.toLowerCase()
        const query = needle.trim().toLowerCase()
        if (query.length === 0)
            return 0

        let cursor = 0
        let score = 0
        for (let i = 0; i < query.length; i++) {
            const found = source.indexOf(query[i], cursor)
            if (found === -1)
                return -1
            score += found === cursor ? 8 : 1 - (found - cursor)
            cursor = found + 1
        }
        return score + (source.indexOf(query) === 0 ? 80 : 0)
    }

    function matches(entry) {
        const searchable = [entry.name, entry.genericName, entry.comment,
                            entry.keywords ? entry.keywords.join(" ") : ""].join(" ")
        return fuzzyScore(searchable, query) >= 0
    }

    function launch(entry) {
        if (!entry)
            return
        entry.execute()
        dismissed()
    }

    function resetSelection() {
        selectedIndex = filteredApps.values.length > 0 ? 0 : -1
        if (selectedIndex >= 0)
            results.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function moveSelection(step) {
        const count = filteredApps.values.length
        if (count === 0) {
            selectedIndex = -1
            return
        }

        if (selectedIndex < 0)
            selectedIndex = step > 0 ? 0 : count - 1
        else
            selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + step))

        results.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function launchSelected() {
        if (selectedIndex >= 0 && selectedIndex < filteredApps.values.length)
            launch(filteredApps.values[selectedIndex])
    }

    Component.onCompleted: Qt.callLater(takeFocus)

    ScriptModel {
        id: filteredApps
        values: DesktopEntries.applications.values.filter(function(entry) {
            return root.matches(entry)
        })
        onValuesChanged: Qt.callLater(root.resetSelection)
    }

    Text {
        id: title
        anchors.top: parent.top
        anchors.topMargin: 9
        anchors.horizontalCenter: parent.horizontalCenter
        text: "󰀻  Application launcher"
        color: ThemeTokens.Theme.foreground
        font.family: ThemeTokens.Theme.fontFamily
        font.pixelSize: ThemeTokens.Theme.fontSize
        font.weight: Font.DemiBold
    }

    Rectangle {
        id: inputSurface
        anchors.top: title.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 42
        radius: 6
        color: ThemeTokens.Theme.background
        border.width: 1
        border.color: search.activeFocus ? ThemeTokens.Theme.activeBorder : ThemeTokens.Theme.surfaceBright

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍉"
            color: ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: 16
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 38
            anchors.verticalCenter: parent.verticalCenter
            visible: search.text.length === 0
            text: "Search applications…"
            color: ThemeTokens.Theme.muted
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
        }

        TextInput {
            id: search
            anchors.left: parent.left
            anchors.leftMargin: 38
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: ThemeTokens.Theme.foreground
            font.family: ThemeTokens.Theme.fontFamily
            font.pixelSize: ThemeTokens.Theme.fontSize
            focus: true
            selectByMouse: true
            clip: true
            onTextChanged: root.query = text
            onAccepted: root.launchSelected()
            Keys.onEscapePressed: root.dismissed()
            Keys.onDownPressed: root.moveSelection(1)
            Keys.onUpPressed: root.moveSelection(-1)
        }
    }

    ListView {
        id: results
        anchors.top: inputSurface.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        clip: true
        spacing: 3
        model: filteredApps
        currentIndex: root.selectedIndex

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property var entry: modelData
            width: results.width
            height: 48
            radius: 5
            color: index === root.selectedIndex ? ThemeTokens.Theme.surfaceBright : "transparent"

            IconImage {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                source: Quickshell.iconPath(row.entry.icon, "application-x-executable")
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 50
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: row.entry.name
                elide: Text.ElideRight
                color: ThemeTokens.Theme.foreground
                font.family: ThemeTokens.Theme.fontFamily
                font.pixelSize: ThemeTokens.Theme.fontSize
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selectedIndex = row.index
                onClicked: root.launch(row.entry)
            }
        }
    }
}
