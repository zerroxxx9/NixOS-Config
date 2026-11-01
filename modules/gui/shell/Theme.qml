// Wallpaper palette. Re-read whenever set-wallpaper renders a new theme.json;
// the defaults below only show until the first render.
import QtQuick
import Quickshell.Io

QtObject {
    id: theme
    required property string path

    property color surface: "#101417"
    property color surfaceHigh: "#1c2024"
    property color text: "#e0e3e7"
    property color textDim: "#89929a"
    property color accent: "#8cceff"
    property color accentText: "#00344f"
    property color outline: "#40484d"
    property color success: "#66d18d"
    property color warning: "#e4ad3c"
    property color error: "#ff9093"
    property real opacity: 0.8

    property FileView file: FileView {
        path: theme.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                for (const k in c)
                    if (k in theme)
                        theme[k] = c[k];
            } catch (e) {
                console.warn("theme.json: " + e);
            }
        }
    }
}
