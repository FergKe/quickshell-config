pragma Singleton

import QtQuick

QtObject {
    // Gruvbox Material Dark Soft — keep visual decisions here so themes can
    // later be swapped without touching individual widgets.
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int barHeight: 34
    readonly property int radius: 9
    readonly property int spacing: 8

    readonly property color background: "#32302f"
    readonly property color surface: "#3c3836"
    readonly property color surfaceBright: "#45403d"
    readonly property color foreground: "#d4be98"
    readonly property color muted: "#a89984"
    readonly property color accent: "#d8a657"
    readonly property color blue: "#7daea3"
    readonly property color success: "#a9b665"
    // Matches Hyprland's active window border: rgba(a9b665ff).
    readonly property color activeBorder: "#a9b665"
    readonly property color warning: "#d8a657"
    readonly property color danger: "#ea6962"
}
