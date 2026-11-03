import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

Item {
    id: menu
    property string kind: ""
    property real anchorX: 0
    property real windowWidth: 0
    signal closeRequested

    readonly property int maxHeight: 380
    readonly property bool open: kind !== ""
    property string shownKind: ""
    onKindChanged: if (kind !== "") { shownKind = kind; refresh(); }

    readonly property bool shown: open || card.opacity > 0
    visible: shown
    width: 300
    height: Math.min(maxHeight, card.implicitHeight - card.radius)
    x: Math.max(8, Math.min(windowWidth - width - 8, Math.round(anchorX - width / 2)))
    clip: true

    property bool wifiOn: false
    property var networks: []
    property bool scanning: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    PwObjectTracker { objects: menu.sink ? [menu.sink] : [] }

    function run(cmd) {
        runner.command = cmd;
        runner.running = true;
    }
    Process { id: runner }

    function refresh() {
        if (kind === "wifi") {
            radioProbe.running = true;
            scan.running = true;
            scanning = true;
        } else if (kind === "bluetooth" && adapter) {
            adapter.discovering = true;
        }
    }
    onOpenChanged: {
        if (!open && adapter && adapter.discovering)
            adapter.discovering = false;
    }

    Process {
        id: radioProbe
        command: [settings.bin + "/nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: menu.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: scan
        command: [settings.bin + "/nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const line of text.split("\n")) {
                    const f = line.split(/(?<!\\):/).map(s => s.replace(/\\:/g, ":"));
                    if (f.length < 4 || f[3] === "" || seen[f[3]])
                        continue;
                    seen[f[3]] = true;
                    out.push({ ssid: f[3], signal: parseInt(f[1]) || 0, secure: f[2] !== "" && f[2] !== "--", active: f[0] === "*" });
                }
                out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
                menu.networks = out;
                menu.scanning = false;
            }
        }
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: content.implicitHeight + 24 + radius
        height: menu.height + radius
        y: menu.open ? -radius : -height
        opacity: menu.open ? 1 : 0
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        radius: 20
        color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, theme.opacity * 0.6)

        Column {
            id: content
            x: 12
            y: 12 + card.radius
            width: parent.width - 24
            spacing: 8

            Item {
                width: parent.width
                height: 30
                visible: menu.shownKind !== "volume"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: menu.shownKind === "wifi" ? "Wi-Fi" : "Bluetooth"
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                Rectangle {
                    id: sw
                    readonly property bool on: menu.shownKind === "wifi" ? menu.wifiOn : (menu.adapter ? menu.adapter.enabled : false)
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 22
                    radius: 11
                    color: on ? theme.accent : theme.surfaceHigh
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Rectangle {
                        width: 16
                        height: 16
                        radius: 8
                        y: 3
                        x: sw.on ? parent.width - width - 3 : 3
                        color: sw.on ? theme.accentText : theme.textDim
                        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (menu.shownKind === "wifi") {
                                menu.wifiOn = !menu.wifiOn;
                                menu.run([settings.bin + "/nmcli", "radio", "wifi", menu.wifiOn ? "on" : "off"]);
                                if (menu.wifiOn) { menu.scanning = true; scanDelay.restart(); }
                                else menu.networks = [];
                            } else if (menu.adapter) {
                                menu.adapter.enabled = !menu.adapter.enabled;
                            }
                        }
                    }
                }
            }
            Timer { id: scanDelay; interval: 2500; onTriggered: scan.running = true }

            Column {
                width: parent.width
                spacing: 2
                visible: menu.shownKind === "wifi"

                Text {
                    visible: !menu.wifiOn || (menu.networks.length === 0)
                    width: parent.width
                    height: 36
                    verticalAlignment: Text.AlignVCenter
                    text: !menu.wifiOn ? "Wi-Fi is off" : menu.scanning ? "Scanning…" : "No networks found"
                    color: theme.textDim
                    font.family: settings.font
                    font.pixelSize: 12
                }
                ListView {
                    width: parent.width
                    height: Math.min(contentHeight, 260)
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: menu.wifiOn ? menu.networks : []
                    delegate: MenuRow {
                        required property var modelData
                        width: ListView.view.width
                        icon: modelData.secure ? "" : ""
                        label: modelData.ssid
                        detail: modelData.active ? "Connected" : modelData.signal + "%"
                        highlighted: modelData.active
                        onClicked: {
                            if (modelData.active)
                                menu.run([settings.bin + "/nmcli", "connection", "down", "id", modelData.ssid]);
                            else
                                menu.run([settings.bin + "/nmcli", "device", "wifi", "connect", modelData.ssid]);
                            scanDelay.restart();
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 2
                visible: menu.shownKind === "bluetooth"

                Text {
                    visible: !menu.adapter || !menu.adapter.enabled || btList.count === 0
                    width: parent.width
                    height: 36
                    verticalAlignment: Text.AlignVCenter
                    text: !menu.adapter ? "No adapter" : !menu.adapter.enabled ? "Bluetooth is off" : "Searching…"
                    color: theme.textDim
                    font.family: settings.font
                    font.pixelSize: 12
                }
                ListView {
                    id: btList
                    width: parent.width
                    height: Math.min(contentHeight, 260)
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    model: menu.adapter && menu.adapter.enabled
                        ? menu.adapter.devices.values
                            .filter(d => d.name && d.name !== "")
                            .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
                        : []
                    delegate: MenuRow {
                        required property var modelData
                        width: ListView.view.width
                        icon: ""
                        label: modelData.name
                        detail: modelData.connected ? "Connected" : modelData.paired ? "Paired" : ""
                        highlighted: modelData.connected
                        onClicked: {
                            if (!modelData.paired)
                                modelData.pair();
                            else
                                modelData.connected = !modelData.connected;
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 8
                visible: menu.shownKind === "volume"

                Row {
                    width: parent.width
                    spacing: 10
                    Rectangle {
                        width: 30
                        height: 30
                        radius: 15
                        anchors.verticalCenter: parent.verticalCenter
                        color: muteArea.containsMouse ? Qt.lighter(theme.surfaceHigh, 1.25) : theme.surfaceHigh
                        Text {
                            anchors.centerIn: parent
                            text: menu.sink && menu.sink.audio && menu.sink.audio.muted ? "" : ""
                            color: theme.text
                            font.family: settings.font
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: muteArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (menu.sink && menu.sink.audio) menu.sink.audio.muted = !menu.sink.audio.muted
                        }
                    }
                    SliderRow {
                        width: parent.width - 30 - 10 - 42 - 10
                        anchors.verticalCenter: parent.verticalCenter
                        icon: ""
                        value: menu.sink && menu.sink.audio ? Math.min(menu.sink.audio.volume, 1) : 0
                        onMoved: v => { if (menu.sink && menu.sink.audio) menu.sink.audio.volume = v; }
                    }
                    Text {
                        width: 42
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: Math.round((menu.sink && menu.sink.audio ? menu.sink.audio.volume : 0) * 100) + "%"
                        color: theme.text
                        font.family: settings.font
                        font.pixelSize: 12
                    }
                }

                Text {
                    text: "Output"
                    color: theme.textDim
                    font.family: settings.font
                    font.pixelSize: 11
                }
                Column {
                    width: parent.width
                    spacing: 2
                    Repeater {
                        model: menu.sinks
                        MenuRow {
                            required property var modelData
                            width: parent.width
                            icon: ""
                            label: modelData.description || modelData.nickname || modelData.name
                            detail: ""
                            highlighted: menu.sink === modelData
                            onClicked: Pipewire.preferredDefaultAudioSink = modelData
                        }
                    }
                }
            }
        }
    }

    component MenuRow: Rectangle {
        id: row
        property string icon
        property string label
        property string detail
        property bool highlighted: false
        signal clicked

        height: 36
        radius: 12
        color: highlighted ? theme.accent : (area.containsMouse ? theme.surfaceHigh : "transparent")
        Behavior on color { ColorAnimation { duration: 120 } }
        readonly property color fg: highlighted ? theme.accentText : theme.text

        Text {
            id: glyph
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: row.icon
            color: row.fg
            font.family: settings.font
            font.pixelSize: 13
            width: 16
        }
        Text {
            anchors.left: glyph.right
            anchors.leftMargin: 10
            anchors.right: detailText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.label
            elide: Text.ElideRight
            color: row.fg
            font.family: settings.font
            font.pixelSize: 12
        }
        Text {
            id: detailText
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: row.detail
            color: row.highlighted ? Qt.rgba(row.fg.r, row.fg.g, row.fg.b, 0.7) : theme.textDim
            font.family: settings.font
            font.pixelSize: 11
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }
}
