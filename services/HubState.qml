import QtQuick

QtObject {
    id: state

    readonly property string clock: "clock"
    readonly property string launcher: "launcher"
    readonly property string theme: "theme"
    readonly property string settings: "settings"

    property string active: clock

    function toggle(nextState) {
        active = active === nextState ? clock : nextState
    }

    function close() {
        active = clock
    }
}
