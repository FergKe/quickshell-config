import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property QtObject shellState

    visible: false

    // Add matching Lua bindings from README.md so Hyprland can invoke these
    // shortcuts from any application.
    GlobalShortcut {
        name: "toggle-launcher"
        description: "Toggle the Quickshell application launcher"
        onPressed: root.shellState.toggleHub(root.shellState.hubLauncher)
    }

    GlobalShortcut {
        name: "toggle-bluetooth"
        description: "Toggle the Quickshell Bluetooth controls"
        onPressed: root.shellState.toggleStatus(root.shellState.statusBluetooth)
    }

    GlobalShortcut {
        name: "toggle-wifi"
        description: "Toggle the Quickshell Wi-Fi controls"
        onPressed: root.shellState.toggleStatus(root.shellState.statusWifi)
    }

    GlobalShortcut {
        name: "toggle-audio"
        description: "Toggle the Quickshell audio controls"
        onPressed: root.shellState.toggleStatus(root.shellState.statusAudio)
    }

    GlobalShortcut {
        name: "toggle-power"
        description: "Toggle the Quickshell power menu"
        onPressed: root.shellState.toggleStatus(root.shellState.statusPower)
    }
}
