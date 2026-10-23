import QtQuick
import Quickshell
import "state" as State
import "shortcuts" as Shortcuts
import "ui/bar" as Bar
import "features/hub" as HubFeature
import "features/status" as StatusFeature
import "features/notifications" as NotificationsFeature

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

    // Independent of the hub/status surfaces: popups appear over anything and
    // never take focus. Binding its model here also forces the notification
    // service (and its D-Bus daemon) to start at launch, before the centre is
    // ever opened, so history collects from the first notification onward.
    NotificationsFeature.Popups {}
}
