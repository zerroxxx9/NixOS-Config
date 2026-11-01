// Clipboard history (cliphist) as a popup that opens at the mouse cursor: search
// field plus rows of text snippets and image thumbnails. Enter or click copies the
// entry, Ctrl+D deletes it, Escape or a click outside closes. A transparent
// full-screen overlay holds the card so outside clicks can be caught.
// Toggled over IPC (`quickshell -c shell ipc call clipboard toggle`).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: win
    property bool open: false
    // Cursor position in Hyprland's global layout coordinates.
    property real cursorX: 0
    property real cursorY: 0
    signal closeRequested

    readonly property bool onThisScreen: screen !== null
        && cursorX >= screen.x && cursorX < screen.x + screen.width
        && cursorY >= screen.y && cursorY < screen.y + screen.height
    readonly property bool shown: onThisScreen && (open || card.opacity > 0)

    visible: shown
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "pill-panel"
    WlrLayershell.keyboardFocus: (open && onThisScreen) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        onPressed: win.closeRequested()
    }

    readonly property string thumbDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/cliphist-thumbs"

    property string query: ""
    property var entries: []   // [{ id, text, image }]
    property var results: []
    property int thumbRev: 0

    function refilter() {
        const q = query.trim().toLowerCase();
        results = q === "" ? entries : entries.filter(e => e.text.toLowerCase().includes(q));
        list.currentIndex = 0;
    }

    function reload() {
        lister.running = false;
        lister.running = true;
    }

    function pick(entry) {
        if (!entry)
            return;
        copier.command = ["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", entry.id];
        copier.running = true;
        closeRequested();
    }

    function remove(entry) {
        if (!entry)
            return;
        deleter.command = ["sh", "-c", 'printf "%s\\t\\n" "$1" | cliphist delete; rm -f "$2/$1"', "sh", entry.id, thumbDir];
        deleter.running = true;
        entries = entries.filter(e => e.id !== entry.id);
        const keep = list.currentIndex;
        refilter();
        list.currentIndex = Math.min(keep, list.count - 1);
    }

    Process { id: copier }
    Process {
        id: deleter
    }

    // Decode image entries once so the rows can show them.
    Process {
        id: thumbs
        onExited: win.thumbRev++
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 1)
                        continue;
                    const body = line.slice(tab + 1);
                    out.push({
                        id: line.slice(0, tab),
                        text: body,
                        image: /^\[\[ binary data .*(png|jpe?g|webp|bmp|gif)/i.test(body)
                    });
                }
                win.entries = out;
                win.refilter();

                const ids = out.filter(e => e.image).slice(0, 40).map(e => e.id);
                if (ids.length > 0) {
                    thumbs.command = ["sh", "-c",
                        'd="$1"; shift; mkdir -p "$d"; for id in "$@"; do [ -s "$d/$id" ] || cliphist decode "$id" > "$d/$id"; done',
                        "sh", win.thumbDir].concat(ids);
                    thumbs.running = true;
                }
            }
        }
    }

    onOpenChanged: {
        if (open) {
            query = "";
            input.text = "";
            reload();
            Qt.callLater(() => input.forceActiveFocus());
        }
    }

    Item {
        id: card
        readonly property real margin: 8
        width: 520
        implicitHeight: content.implicitHeight + 16
        height: implicitHeight
        // Top-left corner at the cursor, nudged back inside the screen.
        x: Math.max(margin, Math.min(win.cursorX - win.screen.x, win.width - width - margin))
        y: Math.max(margin, Math.min(win.cursorY - win.screen.y, win.height - height - margin))
        opacity: win.open ? 1 : 0
        scale: win.open ? 1 : 0.96
        transformOrigin: Item.TopLeft
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        // Swallow clicks on the card so they don't reach the close area.
        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, theme.opacity * 0.6)
            border.width: 1
            border.color: Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.6)
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
                    text: "󰅍"
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
                        text: "Search clipboard"
                        color: theme.textDim
                        font: input.font
                    }

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (event.key === Qt.Key_Escape) {
                            win.closeRequested();
                        } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_N || event.key === Qt.Key_J))) {
                            list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                        } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_P || event.key === Qt.Key_K))) {
                            list.currentIndex = Math.max(0, list.currentIndex - 1);
                        } else if (ctrl && event.key === Qt.Key_D) {
                            win.remove(win.results[list.currentIndex]);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            win.pick(win.results[list.currentIndex]);
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
                height: 6 * 52
                model: win.results
                clip: true
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: win.query === "" ? "Clipboard is empty" : "No matches"
                    color: theme.textDim
                    font.family: settings.font
                    font.pixelSize: 13
                }

                delegate: Rectangle {
                    id: rowItem
                    required property var modelData
                    required property int index
                    readonly property bool selected: ListView.isCurrentItem

                    width: list.width
                    height: 52
                    radius: 14
                    color: selected ? theme.surfaceHigh : "transparent"

                    Rectangle {
                        id: thumbBox
                        visible: modelData.image
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36
                        radius: 8
                        color: theme.surfaceHigh
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: win.thumbRev >= 0 && modelData.image ? "file://" + win.thumbDir + "/" + modelData.id : ""
                            sourceSize.width: 72
                            sourceSize.height: 72
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                    Text {
                        anchors.left: modelData.image ? thumbBox.right : parent.left
                        anchors.leftMargin: modelData.image ? 12 : 16
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.text.trim()
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        color: rowItem.selected ? theme.accent : theme.text
                        font.family: settings.font
                        font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = rowItem.index
                        onClicked: win.pick(modelData)
                    }
                }
            }
        }
    }
}
