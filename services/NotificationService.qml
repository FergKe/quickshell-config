pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Single long-lived owner of the freedesktop notification daemon. It must
// outlive every view switch, so it lives here as a singleton rather than inside
// a hub view that the HubContent loader creates and destroys. Both surfaces —
// the popup window and the hub notification centre — bind to the models below,
// so a dismissal is consistent everywhere.
Singleton {
    id: service

    // History is intentionally in-memory only; a Quickshell reload starts clean
    // (keepOnReload is false to match).
    property bool dnd: false
    readonly property int maxVisiblePopups: 4
    readonly property int defaultTimeout: 5000
    // Bound memory over a long session; oldest entries are expired out.
    readonly property int maxHistory: 100

    readonly property alias historyModel: historyModelImpl
    readonly property alias popupModel: popupModelImpl
    readonly property int count: service._history.length

    // Each entry is a wrapper { n: Notification, time: Date } so the centre can
    // show an arrival time (Notification itself carries none). Newest first.
    property var _history: []
    property var _popups: []
    property var _queue: []

    ScriptModel {
        id: historyModelImpl
        values: service._history
    }

    ScriptModel {
        id: popupModelImpl
        values: service._popups
    }

    NotificationServer {
        id: server

        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true

        onNotification: (n) => service._onNotification(n)
    }

    function _onNotification(n) {
        // Keep the object (and its live actions) alive while it is shown.
        n.tracked = true

        const entry = { "n": n, "time": new Date() }

        // When the sending app or we close it, drop it everywhere.
        n.closed.connect(function() { service._remove(entry) })

        // Transient notifications (volume/brightness OSDs, progress) are meant
        // to flash, not accumulate — show the popup but keep them out of the
        // centre's history.
        if (!n.transient) {
            service._history = [entry].concat(service._history)
            service._trim()
        }

        if (!service.dnd)
            service._enqueuePopup(entry)
    }

    function _trim() {
        while (service._history.length > service.maxHistory) {
            const removed = service._history[service._history.length - 1]
            service._history = service._history.slice(0, service._history.length - 1)
            if (removed.n)
                removed.n.expire()
        }
    }

    function _enqueuePopup(entry) {
        if (service._popups.length < service.maxVisiblePopups)
            service._popups = [entry].concat(service._popups)
        else
            service._queue = service._queue.concat([entry])
    }

    // Hide a popup only (auto-timeout or the popup's close button). The
    // notification stays in history; the slot is handed to the next in queue.
    function dismissPopup(entry) {
        if (service._popups.indexOf(entry) === -1)
            return

        service._popups = service._popups.filter(function(e) { return e !== entry })

        if (service._queue.length > 0) {
            const next = service._queue[0]
            service._queue = service._queue.slice(1)
            service._popups = service._popups.concat([next])
        }
    }

    // Remove from history entirely (centre delete). Closing the notification
    // fires `closed`, which calls _remove — but we also remove directly so the
    // UI updates even if the signal is delayed.
    function dismiss(entry) {
        if (!entry)
            return
        service._remove(entry)
        if (entry.n)
            entry.n.dismiss()
    }

    function _remove(entry) {
        service._history = service._history.filter(function(e) { return e !== entry })
        service.dismissPopup(entry)
    }

    function clearAll() {
        const all = service._history.slice()
        service._history = []
        service._popups = []
        service._queue = []
        for (let i = 0; i < all.length; i++) {
            if (all[i].n)
                all[i].n.dismiss()
        }
    }

    function invokeAction(entry, action) {
        if (action)
            action.invoke()
        // Most clients close the notification in response; the `closed` handler
        // will clean up. Hide the popup immediately for responsiveness.
        service.dismissPopup(entry)
    }

    function toggleDnd() {
        service.dnd = !service.dnd
    }
}
