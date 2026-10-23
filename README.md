# Quickshell UI

The top bar uses the Gruvbox Material Dark Soft palette and expects the font
family `JetBrainsMono Nerd Font` to be installed.

## Project structure

The shell is organised by responsibility so new views can be added without
growing `shell.qml` or the window implementations:

```text
shell.qml                 Application composition root
features/hub/             Hub window, content router, and hub views
features/status/          Status window and status controls
features/notifications/   Notification popup surface and popup delegate
services/                 Long-lived shell services (notification daemon)
shortcuts/                Global shortcut registrations
state/                    Shared shell UI state and navigation
ui/bar/                   Top bar UI
ui/common/                Reusable visual components
theme/                    Theme tokens
```

Hub views expose `desiredWidth`, `desiredHeight`, and `dismissed`. Add a view
to `features/hub/` and register it in `HubContent.qml`; `HubWindow.qml` handles
the common focus and resize transition. All entry points should use the methods
on `ShellState.qml` so the hub and status window remain mutually exclusive.

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

hl.bind(mod .. " + N", hl.dsp.global("quickshell:toggle-notifications"), {
    description = "Toggle Quickshell notification centre",
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

hl.bind(mod .. " + SHIFT + P", hl.dsp.global("quickshell:toggle-power"), {
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
and `Super+Shift+P`. The power icon can also be clicked directly. Suspend happens
immediately; restart and power-off require a second click to confirm.

## Notifications

The shell runs its own freedesktop notification daemon
(`services/NotificationService.qml`), so it must be the only notification server
on the system. If you currently run `mako`, `dunst`, or `swaync`, stop it and
remove it from your Hyprland autostart, then reload Quickshell:

```sh
pkill mako        # or dunst / swaync
```

Incoming notifications slide in as popups just below the right status box,
stay briefly, then slide back out — up to four at a time, with the rest queued.
Critical notifications do not auto-dismiss. Hovering a popup pauses its timer;
its close button hides it while keeping it in history.

`Super+N` opens the notification centre in the hub, listing every notification
with per-item delete, a **Clear all** button, and a **DND** toggle. Do Not
Disturb suppresses popups while still logging notifications to the centre. All
history is in-memory and resets when Quickshell reloads.

Every expanded right-side menu supports keyboard control. Use `Up` and `Down`
to move the highlighted selection, `Enter` to activate it, and `Escape` to
close the menu. In the audio panel, `Left` and `Right` adjust the volume.
