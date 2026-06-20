import QtQuick

// Stub for profiles where global shortcuts are owned by Hyprland binds.
QtObject {
    property string appid: "caelestia"
    property string name: ""
    property string description: ""
    signal pressed
    signal released
}
