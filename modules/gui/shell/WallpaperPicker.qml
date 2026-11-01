// Wallpaper grid that drops out of the bar, like the launcher. Click a
// thumbnail to apply it; Escape or clicking elsewhere closes it.
import QtQuick
import QtQuick.Effects
import Quickshell.Io
import Qt.labs.folderlistmodel

Item {
    id: win
    property bool open: false
    signal closeRequested

    readonly property int maxHeight: 340
    // 0 = tucked under the bar, 1 = fully out; the corner pieces follow this.
    readonly property real progress: card.height > 0 ? Math.max(0, Math.min(1, (card.y + card.height) / card.height)) : 0
    visible: open || card.opacity > 0
    implicitWidth: 640
    implicitHeight: 324
    width: implicitWidth
    height: implicitHeight
    clip: true

    property string currentWallpaper: ""
    FileView {
        path: settings.stateDir + "/current-wallpaper"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: win.currentWallpaper = text().trim()
    }
    Process { id: runner }

    onOpenChanged: if (open) Qt.callLater(() => keys.forceActiveFocus())

    Item {
        id: card
        width: parent.width
        height: parent.height
        y: win.open ? 0 : -height
        opacity: win.open ? 1 : 0
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Same fill as the bar; top corners sit above the clip edge.
        Rectangle {
            y: -radius
            width: parent.width
            height: parent.height + radius
            radius: 24
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, theme.opacity * 0.6)
        }

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: win.closeRequested()

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: 12
                anchors.rightMargin: 28
                cellWidth: Math.floor(width / 4)
                cellHeight: 100
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                model: FolderListModel {
                    folder: "file://" + settings.wallpaperDir
                    nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                    showDirs: false
                    sortField: FolderListModel.Name
                }

                delegate: Item {
                    id: cell
                    required property string filePath
                    readonly property bool current: win.currentWallpaper === filePath
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        id: tile
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 12
                        color: theme.surfaceHigh

                        Image {
                            id: thumb
                            anchors.fill: parent
                            anchors.margins: cell.current ? 3 : 0
                            source: "file://" + cell.filePath
                            sourceSize.width: 320
                            sourceSize.height: 200
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: thumbMask
                            }
                        }
                        Rectangle {
                            id: thumbMask
                            anchors.fill: thumb
                            radius: tile.radius - (cell.current ? 3 : 0)
                            visible: false
                            layer.enabled: true
                        }
                        // Border and hover tint over the image.
                        Rectangle {
                            anchors.fill: parent
                            radius: tile.radius
                            color: area.containsMouse && !cell.current ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                            border.width: cell.current ? 3 : 0
                            border.color: theme.accent
                        }
                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                runner.command = [settings.bin + "/set-wallpaper", cell.filePath];
                                runner.running = true;
                            }
                        }
                    }
                }
            }

            // Scrollbar: click or drag anywhere on the track.
            Item {
                id: track
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 16
                anchors.bottomMargin: 16
                width: 8
                visible: grid.contentHeight > grid.height

                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.08)
                }
                Rectangle {
                    width: parent.width
                    radius: 4
                    height: Math.max(24, grid.visibleArea.heightRatio * track.height)
                    y: grid.visibleArea.yPosition * track.height
                    color: handleArea.pressed || handleArea.containsMouse ? theme.accent : theme.textDim
                }
                MouseArea {
                    id: handleArea
                    anchors.fill: parent
                    anchors.leftMargin: -6
                    anchors.rightMargin: -6
                    hoverEnabled: true
                    function scrollTo(y) {
                        const ratio = grid.visibleArea.heightRatio;
                        const pos = Math.max(0, Math.min(1 - ratio, y / track.height - ratio / 2));
                        grid.contentY = grid.originY + pos * grid.contentHeight;
                    }
                    onPressed: mouse => scrollTo(mouse.y)
                    onPositionChanged: mouse => { if (pressed) scrollTo(mouse.y); }
                }
            }
        }
    }
}
