pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

QtObject {
    id: root

    readonly property var toplevels: Hyprland.toplevels
    readonly property var workspaces: Hyprland.workspaces
    readonly property var monitors: Hyprland.monitors

    readonly property var activeToplevel: Hyprland.activeToplevel
    readonly property var focusedWorkspace: Hyprland.focusedWorkspace
    readonly property var focusedMonitor: Hyprland.focusedMonitor
    readonly property int activeWsId: Hyprland.focusedWorkspace?.id ?? 1

    readonly property var keyboard: null
    readonly property bool capsLock: false
    readonly property bool numLock: false
    readonly property string defaultKbLayout: "us"
    readonly property string kbLayoutFull: "us"
    readonly property string kbLayout: "us"
    readonly property var kbMap: new Map()

    readonly property var extras: ({
        devices: {
            keyboards: []
        },
        options: root.options,
        message: function(request) {
            Quickshell.execDetached(["hyprctl", String(request)]);
        },
        batchMessage: function(requests) {
            for (const request of requests)
                Quickshell.execDetached(["hyprctl", String(request)]);
        },
        applyOptions: function(values) {
            for (const key in values)
                Quickshell.execDetached(["hyprctl", "keyword", key, String(values[key])]);
            root.refreshOptions();
        },
        refreshOptions: function() {
            root.refreshOptions();
        },
        refreshDevices: function() {
            root.refreshDevices();
        }
    })

    readonly property var devices: extras.devices
    property var options: ({})
    property bool hadKeyboard: true
    property string lastSpecialWorkspace: ""

    signal configReloaded

    function dispatch(request: string): void {
        Hyprland.dispatch(request);
    }

    function cycleSpecialWorkspace(direction: string): void {
        const openSpecials = workspaces.values.filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0);

        if (openSpecials.length === 0)
            return;

        const activeSpecial = focusedMonitor?.lastIpcObject?.specialWorkspace?.name ?? "";

        if (!activeSpecial) {
            if (lastSpecialWorkspace) {
                const workspace = workspaces.values.find(w => w.name === lastSpecialWorkspace);
                if (workspace && workspace.lastIpcObject.windows > 0) {
                    dispatch(`togglespecialworkspace ${lastSpecialWorkspace.slice(8)}`);
                    return;
                }
            }
            dispatch(`togglespecialworkspace ${openSpecials[0].name.slice(8)}`);
            return;
        }

        const currentIndex = openSpecials.findIndex(w => w.name === activeSpecial);
        let nextIndex = 0;

        if (currentIndex !== -1) {
            if (direction === "next")
                nextIndex = (currentIndex + 1) % openSpecials.length;
            else
                nextIndex = (currentIndex - 1 + openSpecials.length) % openSpecials.length;
        }

        dispatch(`togglespecialworkspace ${openSpecials[nextIndex].name.slice(8)}`);
    }

    function monitorNames(): list<string> {
        return monitors.values.map(e => e.name);
    }

    function monitorFor(screen): var {
        return Hyprland.monitorFor(screen) ?? focusedMonitor;
    }

    function refreshOptions(): void {
        const keys = [
            "animations:enabled",
            "decoration:shadow:enabled",
            "decoration:blur:enabled",
            "general:gaps_in",
            "general:gaps_out",
            "general:border_size",
            "decoration:rounding",
            "general:allow_tearing"
        ];

        for (const key of keys)
            Quickshell.execDetached(["sh", "-c", `hyprctl -j getoption ${key} | jq -r '.int // .float // .str // .custom // empty' >/tmp/caelestia-hypr-${key.replace(/[^A-Za-z0-9_]/g, "_")} 2>/dev/null || true`]);
    }

    function refreshDevices(): void {
    }

    function reloadDynamicConfs(): void {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        configReloaded();
    }

    Component.onCompleted: {
        reloadDynamicConfs();
    }
}
