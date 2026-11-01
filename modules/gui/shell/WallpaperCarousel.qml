// Spotlight-style wallpaper bar: a centred card with a horizontal carousel (the
// selected wallpaper is enlarged) above a search field. Type to filter by file
// name, Left/Right or scroll to move, Enter or a click on the selected one
// applies it, Escape or a click outside closes.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Qt.labs.folderlistmodel

PanelWindow {
    id: win
    property bool open: false
    signal closeRequested

    readonly property int cardW: Math.min(1100, width - 80)
    readonly property int cellW: 250
    readonly property int cellH: 170
    readonly property bool shown: open || card.opacity > 0

    visible: shown
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "pill-panel"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property string currentWallpaper: ""
    FileView {
        path: settings.stateDir + "/current-wallpaper"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: win.currentWallpaper = text().trim()
    }
    Process { id: runner }

    function apply(path) {
        runner.command = [settings.bin + "/set-wallpaper", path];
        runner.running = true;
        win.closeRequested();
    }

    onOpenChanged: {
        if (open) {
            input.text = "";
            Qt.callLater(() => input.forceActiveFocus());
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: win.closeRequested()
    }

    Item {
        id: card
        width: win.cardW
        height: 330
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.5 - height / 2
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.96
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            radius: 24
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, theme.opacity * 0.85)
            border.width: 1
            border.color: Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.6)
        }

        ListView {
            id: list
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 16
            height: 240
            orientation: ListView.Horizontal
            clip: true
            spacing: 0
            boundsBehavior: Flickable.StopAtBounds
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: (width - win.cellW) / 2
            preferredHighlightEnd: (width + win.cellW) / 2
            highlightMoveDuration: 220
            cacheBuffer: win.cellW * 6

            model: FolderListModel {
                id: folder
                folder: "file://" + settings.wallpaperDir
                caseSensitive: false
                showDirs: false
                sortField: FolderListModel.Name
                nameFilters: {
                    const q = input.text.trim();
                    return ["png", "jpg", "jpeg", "webp"].map(e => "*" + q + "*." + e);
                }
            }

            // Mouse wheel steps through items instead of scrolling pixels.
            WheelHandler {
                onWheel: event => {
                    const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                    list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + (d < 0 ? 1 : -1)));
                }
            }

            // Start on the active wallpaper once the folder has loaded.
            onCountChanged: if (count > 0 && input.text === "") positionTimer.restart()
            Timer {
                id: positionTimer
                interval: 30
                onTriggered: {
                    for (let i = 0; i < folder.count; i++) {
                        if (folder.get(i, "filePath") === win.currentWallpaper) {
                            list.currentIndex = i;
                            return;
                        }
                    }
                }
            }

            delegate: Item {
                id: cell
                required property int index
                required property string filePath
                required property string fileBaseName
                readonly property bool selected: ListView.isCurrentItem

                width: win.cellW
                height: list.height

                Item {
                    id: tile
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -10
                    width: parent.width - 14
                    height: width * 0.6
                    scale: cell.selected ? 1.22 : 1
                    z: cell.selected ? 1 : 0
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Image {
                        id: thumb
                        anchors.fill: parent
                        source: "file://" + cell.filePath
                        sourceSize.width: 480
                        sourceSize.height: 300
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: mask
                        }
                    }
                    Rectangle {
                        id: mask
                        anchors.fill: thumb
                        radius: 16
                        visible: false
                        layer.enabled: true
                    }
                    Rectangle {
                        anchors.fill: parent
                        radius: 16
                        color: "transparent"
                        border.width: cell.filePath === win.currentWallpaper ? 3 : 0
                        border.color: theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cell.selected)
                                win.apply(cell.filePath);
                            else
                                list.currentIndex = cell.index;
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: cell.fileBaseName
                    color: cell.selected ? theme.text : theme.textDim
                    font.family: settings.font
                    font.pixelSize: cell.selected ? 15 : 13
                }
            }
        }

        Text {
            anchors.centerIn: list
            visible: list.count === 0
            text: "No wallpapers match"
            color: theme.textDim
            font.family: settings.font
            font.pixelSize: 15
        }

        // Search field
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 12
            height: 52
            radius: 16
            color: theme.surfaceHigh

            Text {
                id: glyph
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: ""
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 16
            }
            TextInput {
                id: input
                anchors.left: glyph.right
                anchors.leftMargin: 14
                anchors.right: clear.left
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: theme.text
                selectionColor: theme.accent
                selectedTextColor: theme.accentText
                font.family: settings.font
                font.pixelSize: 16
                clip: true

                Text {
                    visible: !input.text
                    text: "Search wallpapers"
                    color: theme.textDim
                    font: input.font
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        win.closeRequested();
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab
                               || (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_N || event.key === Qt.Key_L))) {
                        list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
                               || (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_P || event.key === Qt.Key_H))) {
                        list.currentIndex = Math.max(0, list.currentIndex - 1);
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (list.currentItem)
                            win.apply(list.currentItem.filePath);
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }

            Text {
                id: clear
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 14
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.closeRequested()
                }
            }
        }
    }
}
