import QtQuick
import Quickshell
import "state" as State
import "shortcuts" as Shortcuts
import "ui/bar" as Bar
import "features/hub" as HubFeature
import "features/status" as StatusFeature

ShellRoot {
    id: root

    State.ShellState {
        id: appState
    }

    Shortcuts.GlobalShortcuts {
        shellState: appState
    }

    Bar.TopBar {}

    HubFeature.HubWindow {
        shellState: appState
    }

    StatusFeature.StatusWindow {
        shellState: appState
    }
}
