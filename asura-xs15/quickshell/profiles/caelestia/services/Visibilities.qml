pragma Singleton

import Quickshell
import qs.components
import qs.services

Singleton {
    property var screens: new Map()
    property var bars: new Map()
    property DrawerVisibilities fallback

    function load(screen: ShellScreen, visibilities: DrawerVisibilities): void {
        const monitor = Hypr.monitorFor(screen);
        const key = monitor?.name || screen?.name || "__default";
        screens.set(key, visibilities);
        if (!fallback)
            fallback = visibilities;
    }

    function getForActive(): DrawerVisibilities {
        const key = Hypr.focusedMonitor?.name || "__default";
        return screens.get(key) ?? fallback ?? screens.values().next().value;
    }
}
