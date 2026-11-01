// App launcher: search field, icon + name + description rows, accent-coloured
// selected row. Toggled over IPC (`quickshell -c shell ipc call launcher toggle`).
import QtQuick
import Quickshell
import Quickshell.Widgets

// Lives inside the bar's window, directly under the bar, and slides down out of it.
Item {
    id: win
    property bool open: false
    signal closeRequested

    readonly property int maxHeight: 400
    // Mapped while open or still animating out.
    readonly property bool shown: open || card.opacity > 0
    // 0 = fully tucked under the bar, 1 = fully out; the corner pieces follow this.
    readonly property real progress: card.height > 0 ? Math.max(0, Math.min(1, (card.y + card.height) / card.height)) : 0
    visible: shown
    implicitWidth: 520
    implicitHeight: card.implicitHeight
    width: implicitWidth
    height: implicitHeight
    clip: true

    property string query: ""
    property var results: []

    function score(e, q) {
        const n = e.name.toLowerCase();
        if (n === q) return 0;
        if (n.startsWith(q)) return 1;
        if (n.split(/[\s-]+/).some(w => w.startsWith(q))) return 2;
        if (n.includes(q)) return 3;
        if ((e.genericName ?? "").toLowerCase().includes(q)) return 4;
        if ((e.comment ?? "").toLowerCase().includes(q)) return 5;
        if ((e.categories ?? []).some(c => c.toLowerCase().includes(q))) return 6;
        return -1;
    }

    function refilter() {
        const q = query.trim().toLowerCase();
        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        let out;
        if (q === "") {
            out = apps.slice().sort((a, b) => a.name.localeCompare(b.name));
        } else {
            out = apps.map(e => ({ e, s: score(e, q) }))
                .filter(x => x.s >= 0)
                .sort((a, b) => a.s - b.s || a.e.name.localeCompare(b.e.name))
                .map(x => x.e);
        }
        results = out;
        list.currentIndex = 0;
    }

    function launch(entry) {
        if (!entry)
            return;
        entry.execute();
        closeRequested();
    }

    onOpenChanged: {
        if (open) {
            query = "";
            input.text = "";
            refilter();
            Qt.callLater(() => input.forceActiveFocus());
        }
    }
    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { if (win.open) win.refilter(); }
    }

    Item {
        id: card
        width: parent.width
        implicitHeight: content.implicitHeight + 16
        height: implicitHeight
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

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Search field
            Item {
                width: parent.width
                height: 52

                Text {
                    id: glyph
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: theme.textDim
                    font.family: settings.font
                    font.pixelSize: 16
                }
                TextInput {
                    id: input
                    anchors.left: glyph.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: theme.text
                    selectionColor: theme.accent
                    selectedTextColor: theme.accentText
                    font.family: settings.font
                    font.pixelSize: 16
                    clip: true
                    onTextChanged: { win.query = text; win.refilter(); }

                    Text {
                        visible: !input.text
                        text: "Search"
                        color: theme.textDim
                        font: input.font
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            win.closeRequested();
                        } else if (event.key === Qt.Key_Down || (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_N || event.key === Qt.Key_J))) {
                            list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                        } else if (event.key === Qt.Key_Up || (event.modifiers & Qt.ControlModifier && (event.key === Qt.Key_P || event.key === Qt.Key_K))) {
                            list.currentIndex = Math.max(0, list.currentIndex - 1);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            win.launch(win.results[list.currentIndex]);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.6)
                }
            }

            // Results
            ListView {
                id: list
                width: parent.width
                height: Math.min(count, 6) * 52
                visible: count > 0
                model: win.results
                clip: true
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                delegate: Rectangle {
                    id: rowItem
                    required property var modelData
                    required property int index
                    readonly property bool selected: ListView.isCurrentItem

                    width: list.width
                    height: 52
                    radius: 14
                    color: selected ? theme.surfaceHigh : "transparent"

                    IconImage {
                        id: icon
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 32
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    }
                    Column {
                        anchors.left: icon.right
                        anchors.leftMargin: 14
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Text {
                            width: parent.width
                            text: modelData.name
                            elide: Text.ElideRight
                            color: rowItem.selected ? theme.accent : theme.text
                            font.family: settings.font
                            font.pixelSize: 14
                        }
                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: modelData.comment || modelData.genericName || ""
                            elide: Text.ElideRight
                            color: theme.textDim
                            font.family: settings.font
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = rowItem.index
                        onClicked: win.launch(modelData)
                    }
                }
            }
        }
    }
}
