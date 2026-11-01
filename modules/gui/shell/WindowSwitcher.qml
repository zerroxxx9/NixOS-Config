// Alt+Tab overlay on the focused monitor: one card per window with a live
// preview, most recently used first. Tab / Shift+Tab / arrows move, releasing
// Alt or Enter switches, Escape or a click outside cancels.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    required property var ctl

    readonly property bool onThisScreen: screen !== null && ctl.screenName === screen.name
    readonly property bool shown: onThisScreen && (ctl.open || card.opacity > 0)

    readonly property int cellW: 252
    readonly property int cellH: 190
    readonly property int cols: Math.max(1, Math.min(ctl.count, Math.floor((width * 0.9 - 24) / cellW)))

    visible: shown
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "pill-panel"
    WlrLayershell.keyboardFocus: (ctl.open && onThisScreen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onPressed: win.ctl.cancel()
    }

    onShownChanged: if (shown && ctl.open) Qt.callLater(() => keys.forceActiveFocus())

    Item {
        id: card
        anchors.centerIn: parent
        width: win.cols * win.cellW + 24
        height: Math.ceil(Math.max(1, win.ctl.count) / win.cols) * win.cellH + 24
        opacity: win.ctl.open ? 1 : 0
        scale: win.ctl.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, theme.opacity * 0.6)
            border.width: 1
            border.color: Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.6)
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                const n = win.ctl.count;
                if (event.key === Qt.Key_Escape) {
                    win.ctl.cancel();
                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right) {
                    win.ctl.step(1);
                } else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left) {
                    win.ctl.step(-1);
                } else if (event.key === Qt.Key_Down) {
                    win.ctl.step(win.cols);
                } else if (event.key === Qt.Key_Up) {
                    win.ctl.step(-win.cols);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    win.ctl.commit();
                } else {
                    return;
                }
                event.accepted = true;
            }
            Keys.onReleased: event => {
                if (event.key === Qt.Key_Alt && !event.isAutoRepeat) {
                    win.ctl.commit();
                    event.accepted = true;
                }
            }
        }

        Flow {
            anchors.fill: parent
            anchors.margins: 12

            Repeater {
                model: win.ctl.open ? win.ctl.entries : []

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool selected: index === win.ctl.index

                    width: win.cellW
                    height: win.cellH

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 16
                        color: cell.selected ? theme.surfaceHigh : "transparent"
                        border.width: cell.selected ? 2 : 0
                        border.color: theme.accent
                    }

                    // Live preview, fitted to the window's aspect ratio.
                    Item {
                        id: preview
                        x: 14
                        y: 14
                        width: win.cellW - 28
                        height: 120

                        readonly property real ratio: Math.min(width / Math.max(1, cell.modelData.width), height / Math.max(1, cell.modelData.height))

                        Rectangle {
                            anchors.centerIn: parent
                            width: Math.round(cell.modelData.width * preview.ratio)
                            height: Math.round(cell.modelData.height * preview.ratio)
                            radius: 8
                            color: theme.surfaceHigh
                            clip: true

                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: cell.modelData.toplevel
                                live: win.ctl.open
                            }
                        }
                    }

                    Row {
                        x: 16
                        y: 14 + 120 + 10
                        width: win.cellW - 32
                        spacing: 8

                        Image {
                            width: 20
                            height: 20
                            anchors.verticalCenter: parent.verticalCenter
                            sourceSize.width: 40
                            sourceSize.height: 40
                            source: {
                                const e = DesktopEntries.heuristicLookup(cell.modelData.cls);
                                return Quickshell.iconPath(e ? e.icon : cell.modelData.cls.toLowerCase(), "application-x-executable");
                            }
                        }
                        Text {
                            width: parent.width - 28
                            anchors.verticalCenter: parent.verticalCenter
                            text: cell.modelData.title || cell.modelData.cls
                            elide: Text.ElideRight
                            color: cell.selected ? theme.accent : theme.text
                            font.family: settings.font
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: win.ctl.select(cell.index)
                        onClicked: win.ctl.commit()
                    }
                }
            }
        }
    }
}
