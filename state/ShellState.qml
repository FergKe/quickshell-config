import QtQuick

QtObject {
    id: state

    readonly property string hubClock: "clock"
    readonly property string hubLauncher: "launcher"
    readonly property string hubTheme: "theme"
    readonly property string hubNotifications: "notifications"
    readonly property string hubMedia: "media"

    readonly property string statusCompact: "compact"
    readonly property string statusBluetooth: "bluetooth"
    readonly property string statusWifi: "wifi"
    readonly property string statusAudio: "audio"
    readonly property string statusPower: "power"

    property string hubMode: hubClock
    property string statusMode: statusCompact

    function toggleHub(nextMode) {
        const opening = nextMode !== hubClock && hubMode !== nextMode
        if (opening)
            statusMode = statusCompact

        hubMode = opening ? nextMode : hubClock
    }

    function closeHub() {
        hubMode = hubClock
    }

    function toggleStatus(nextMode) {
        const opening = nextMode !== statusCompact && statusMode !== nextMode
        if (opening)
            hubMode = hubClock

        statusMode = opening ? nextMode : statusCompact
    }

    function closeStatus() {
        statusMode = statusCompact
    }
}
