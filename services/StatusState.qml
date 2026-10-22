import QtQuick

QtObject {
    id: state

    readonly property string compact: "compact"
    readonly property string bluetooth: "bluetooth"
    readonly property string wifi: "wifi"
    readonly property string audio: "audio"
    readonly property string power: "power"

    property string active: compact

    function toggle(nextState) {
        active = active === nextState ? compact : nextState
    }

    function close() {
        active = compact
    }
}
