import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win
    property bool open: false
    signal closeRequested

    // Set by the creator (the window's own `screen` can't be read here without a binding loop).
    property string screenName: ""
    readonly property bool isFocusedScreen: Hyprland.focusedMonitor !== null
        && Hyprland.focusedMonitor.name === screenName
    readonly property bool shown: isFocusedScreen && (open || card.opacity > 0)

    visible: shown
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "pill-panel"
    WlrLayershell.keyboardFocus: (open && isFocusedScreen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string pending: ""

    function choose(mode) {
        pending = mode;
        closeRequested();
        // Let the overlay fade out first so it isn't in the recording / region picker.
        launch.restart();
    }

    Timer {
        id: launch
        interval: 250
        onTriggered: {
            starter.command = ["shell-record", "start", win.pending];
            starter.running = true;
        }
    }
    Process { id: starter }

    onOpenChanged: if (open) Qt.callLater(() => card.forceActiveFocus())

    MouseArea {
        anchors.fill: parent
        onPressed: win.closeRequested()
    }

    Item {
        id: card
        width: 360
        height: 128
        anchors.centerIn: parent
        focus: true
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                win.closeRequested();
            } else if (event.key === Qt.Key_R || event.key === Qt.Key_1) {
                win.choose("region");
            } else if (event.key === Qt.Key_F || event.key === Qt.Key_2) {
                win.choose("full");
            } else {
                return;
            }
            event.accepted = true;
        }

        // Swallow clicks on the card so they don't reach the close area.
        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, theme.opacity * 0.6)
            border.width: 1
            border.color: Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.6)
        }

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            Repeater {
                model: [
                    { icon: "󰆞", label: "Select area", hint: "R", mode: "region" },
                    { icon: "󰹑", label: "Fullscreen", hint: "F", mode: "full" }
                ]

                delegate: Rectangle {
                    id: tile
                    required property var modelData
                    width: (card.width - 24 - 8) / 2
                    height: card.height - 24
                    radius: 14
                    color: area.containsMouse ? theme.surfaceHigh : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.icon
                            color: area.containsMouse ? theme.accent : theme.text
                            font.family: settings.font
                            font.pixelSize: 28
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.label
                            color: theme.text
                            font.family: settings.font
                            font.pixelSize: 14
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.hint
                            color: theme.textDim
                            font.family: settings.font
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.choose(tile.modelData.mode)
                    }
                }
            }
        }
    }
}
