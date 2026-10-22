import QtQuick
import Quickshell
import Quickshell.Hyprland
import "services" as Services
import "panels" as Panels

ShellRoot {
    id: root

    Services.HubState {
        id: hubState
    }

    Services.StatusState {
        id: statusState
    }

    // Hyprland global shortcuts are registered here. Add the matching Lua
    // bindings from README.md so Hyprland can invoke them from any app.
    GlobalShortcut {
        name: "toggle-launcher"
        description: "Toggle the Quickshell application launcher"
        onPressed: {
            statusState.close()
            hubState.toggle("launcher")
        }
    }

    GlobalShortcut {
        name: "toggle-bluetooth"
        description: "Toggle the Quickshell Bluetooth controls"
        onPressed: {
            hubState.close()
            statusState.toggle(statusState.bluetooth)
        }
    }

    GlobalShortcut {
        name: "toggle-wifi"
        description: "Toggle the Quickshell Wi-Fi controls"
        onPressed: {
            hubState.close()
            statusState.toggle(statusState.wifi)
        }
    }

    GlobalShortcut {
        name: "toggle-audio"
        description: "Toggle the Quickshell audio controls"
        onPressed: {
            hubState.close()
            statusState.toggle(statusState.audio)
        }
    }

    GlobalShortcut {
        name: "toggle-power"
        description: "Toggle the Quickshell power menu"
        onPressed: {
            hubState.close()
            statusState.toggle(statusState.power)
        }
    }

    Panels.TopBar {}

    Panels.HubWindow {
        hubState: hubState
    }

    Panels.StatusWindow {
        statusState: statusState
    }
}
