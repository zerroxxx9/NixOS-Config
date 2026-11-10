// Full-width top bar: workspace numbers on the left, the island (clock, now
// playing, VPN) in the middle, status and tray on the right. Clicking the
// island opens the quick settings panel.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray

Item {
    id: bar
    required property string screenName
    signal islandClicked
    signal menuRequested(string kind, real x)
    property bool panelOpen: false

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === screenName) ?? null

    // Workspace labels: "3" -> 3, "3-left" -> 3; special workspaces are skipped.
    function label(ws) {
        const n = parseInt(ws.name);
        return isNaN(n) ? ws.id : n;
    }
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.monitor && w.monitor.name === screenName && !w.name.startsWith("special"))
        .sort((a, b) => label(a) - label(b))

    // --- state -------------------------------------------------------------
    property bool wifiUp: false
    property string wifiName: ""
    property bool wired: false
    property var vpns: []
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property int volumePct: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    PwObjectTracker { objects: bar.sink ? [bar.sink] : [] }
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isPresent && battery.isLaptopBattery
    readonly property bool btOn: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null

    Process {
        id: wifiProbe
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const c = text.split("\n").map(l => l.split(":")).find(f => f[1] && (f[1].includes("wireless") || f[1].includes("ethernet")));
                bar.wifiUp = !!c;
                bar.wifiName = c ? c[0] : "";
                bar.wired = !!c && c[1].includes("ethernet");
            }
        }
    }
    Process {
        id: vpnProbe
        command: ["systemctl", "list-units", "--state=active", "--plain", "--no-legend", "openvpn-*.service"]
        stdout: StdioCollector {
            onStreamFinished: bar.vpns = text.split("\n")
                .map(l => l.trim().split(/\s+/)[0])
                .filter(u => u.startsWith("openvpn-"))
                .map(u => u.replace(/^openvpn-/, "").replace(/\.service$/, ""))
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: { wifiProbe.running = true; vpnProbe.running = true; }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    function batteryGlyph(pct) {
        return pct > 87 ? "" : pct > 62 ? "" : pct > 37 ? "" : pct > 12 ? "" : "";
    }

    function gotoWorkspace(name) {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = "${name}" })` : `workspace ${name}`);
    }

    // --- background --------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, theme.opacity * 0.6)
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.3)
        opacity: bar.panelOpen ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    // --- left: workspace numbers (square, chunky blocks) -------------------
    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 1

        Repeater {
            model: bar.workspaces
            Rectangle {
                required property var modelData
                readonly property bool active: bar.monitor && bar.monitor.activeWorkspace === modelData
                width: 30
                height: parent.height
                radius: 0
                // Only the active workspace is highlighted.
                color: active ? Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.2) : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                // Slightly lighter bar along the top edge of the active block.
                Rectangle {
                    visible: parent.active
                    anchors.top: parent.top
                    width: parent.width
                    height: 2
                    color: theme.accent
                }

                Text {
                    anchors.centerIn: parent
                    text: bar.label(modelData)
                    color: parent.active ? theme.text : theme.textDim
                    font.family: settings.font
                    font.pixelSize: 13
                    font.weight: parent.active ? Font.Bold : Font.Normal
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.gotoWorkspace(modelData.name)
                }
            }
        }
    }

    // --- middle: clock and date as plain text; VPN and now-playing appear
    // inline when active. Clicking it opens the quick settings panel. --------
    Item {
        id: island
        anchors.centerIn: parent
        height: parent.height
        width: islandRow.implicitWidth
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Row {
            id: islandRow
            anchors.centerIn: parent
            spacing: 12

            // VPN
            Repeater {
                model: bar.vpns
                Row {
                    required property string modelData
                    spacing: 5
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "\uf023"
                        color: theme.success
                        font.family: settings.font
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData
                        color: theme.success
                        font.family: settings.font
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Text {
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: theme.text
                font.family: settings.font
                font.pixelSize: 13
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: Qt.formatDateTime(clock.date, "ddd d MMM")
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }

            // Now playing
            Row {
                visible: !!bar.player
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: "\uf001"
                    color: theme.accent
                    font.family: settings.font
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    width: Math.min(implicitWidth, 240)
                    elide: Text.ElideRight
                    text: bar.player ? (bar.player.trackArtist ? bar.player.trackTitle + " — " + bar.player.trackArtist : bar.player.trackTitle) : ""
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.islandClicked()
        }
    }

    // --- right: tray and status -------------------------------------------
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        // Tray
        Row {
            spacing: 8
            visible: SystemTray.items.values.length > 0
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: SystemTray.items
                Image {
                    required property var modelData
                    width: 16
                    height: 16
                    source: modelData.icon
                    sourceSize.width: 32
                    sourceSize.height: 32
                    smooth: true
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -3
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton)
                                modelData.activate();
                            else if (mouse.button === Qt.MiddleButton)
                                modelData.secondaryActivate();
                            else if (modelData.hasMenu)
                                modelData.display(Window.window, mapToItem(null, mouse.x, mouse.y).x, mapToItem(null, mouse.x, mouse.y).y + 12);
                        }
                    }
                }
            }
        }

        Text {
            id: btIcon
            text: ""
            color: bar.btOn ? theme.text : theme.textDim
            font.family: settings.font
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.menuRequested("bluetooth", btIcon.mapToItem(bar, btIcon.width / 2, 0).x)
            }
        }

        // Volume: scroll to change.
        MouseArea {
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: volume.implicitWidth
            implicitHeight: volume.implicitHeight
            cursorShape: Qt.PointingHandCursor
            onClicked: bar.menuRequested("volume", mapToItem(bar, width / 2, 0).x)
            onWheel: wheel => {
                if (bar.sink && bar.sink.audio)
                    bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
            }
            Row {
                id: volume
                spacing: 6
                Text {
                    text: bar.muted || bar.volumePct === 0 ? "" : bar.volumePct < 50 ? "" : ""
                    color: bar.muted ? theme.textDim : theme.text
                    font.family: settings.font
                    font.pixelSize: 14
                }
                Text {
                    text: bar.volumePct + "%"
                    color: bar.muted ? theme.textDim : theme.text
                    font.family: settings.font
                    font.pixelSize: 12
                }
            }
        }

        Row {
            id: wifiRow
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.menuRequested("wifi", wifiRow.mapToItem(bar, wifiRow.width / 2, 0).x)
            }
            Text {
                text: !bar.wifiUp ? "" : bar.wired ? "󰈀" : ""
                color: bar.wifiUp ? theme.text : theme.textDim
                font.family: settings.font
                font.pixelSize: 14
            }
            Text {
                visible: bar.wifiUp
                text: bar.wired ? "Wired" : (bar.wifiName.length > 16 ? bar.wifiName.slice(0, 15) + "…" : bar.wifiName)
                color: theme.text
                font.family: settings.font
                font.pixelSize: 12
            }
        }

        Row {
            visible: bar.hasBattery
            spacing: 6
            anchors.verticalCenter: parent.verticalCenter
            readonly property int pct: Math.round((bar.battery?.percentage ?? 0) * 100)
            Text {
                text: bar.batteryGlyph(parent.pct)
                color: parent.pct <= 15 ? theme.error : theme.success
                font.family: settings.font
                font.pixelSize: 14
            }
            Text {
                text: parent.pct + "%"
                color: parent.pct <= 15 ? theme.error : theme.text
                font.family: settings.font
                font.pixelSize: 12
            }
        }
    }
}
