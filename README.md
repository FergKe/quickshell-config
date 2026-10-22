# Quickshell UI

The top bar uses the Gruvbox Material Dark Soft palette and expects the font
family `JetBrainsMono Nerd Font` to be installed.

## Run

```sh
quickshell -p ~/.config/quickshell
```

## Hyprland keybinds (Lua config)

Quickshell registers the launcher shortcut through Hyprland's global shortcuts
protocol. Add this to your Hyprland Lua configuration, then reload Hyprland:

```lua
hl.bind(mod .. " + SPACE", hl.dsp.global("quickshell:toggle-launcher"), {
    description = "Toggle Quickshell application launcher",
})

hl.bind(mod .. " + B", hl.dsp.global("quickshell:toggle-bluetooth"), {
    description = "Toggle Quickshell Bluetooth controls",
})

hl.bind(mod .. " + I", hl.dsp.global("quickshell:toggle-wifi"), {
    description = "Toggle Quickshell Wi-Fi controls",
})

hl.bind(mod .. " + A", hl.dsp.global("quickshell:toggle-audio"), {
    description = "Toggle Quickshell audio controls",
})

hl.bind(mod .. " + P", hl.dsp.global("quickshell:toggle-power"), {
    description = "Toggle Quickshell power menu",
})
```

The center hub returns to the clock when the launcher is toggled a second time.
The persistent hub grows from its clock size into the application launcher,
overlaying windows without reserving more desktop space. Search is fuzzy across
installed desktop applications; click an entry to launch it or press Escape to
close the launcher.

The right status box follows the same persistent-surface design. Bluetooth,
Wi-Fi, audio, and power expand in place with `Super+B`, `Super+I`, `Super+A`,
and `Super+P`. The power icon can also be clicked directly. Suspend happens
immediately; restart and power-off require a second click to confirm.

Every expanded right-side menu supports keyboard control. Use `Up` and `Down`
to move the highlighted selection, `Enter` to activate it, and `Escape` to
close the menu. In the audio panel, `Left` and `Right` adjust the volume.
