// The panel that drops from the pill: notifications card, toggle tiles,
// sliders, power buttons and the wallpaper strip.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Qt.labs.folderlistmodel

Item {
    id: panel
    signal closeRequested
    signal wallpapersRequested
    signal settingsRequested

    implicitWidth: 560
    implicitHeight: col.implicitHeight + 20
    // Clip the top rounded corners away so the panel grows straight out of the bar.
    clip: true

    Rectangle {
        y: -radius
        width: parent.width
        height: parent.height + radius
        radius: 24
        // Same fill as the top bar so the two read as one surface.
        color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, theme.opacity * 0.6)
    }

    // --- state -------------------------------------------------------------
    property bool wifiOn: false
    property string wifiName: ""
    property bool dnd: false
    property bool nightLight: false
    property bool hasBacklight: false
    property real brightness: 0
    property string currentWallpaper: ""

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: panel.sink ? [panel.sink] : [] }

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isPresent && battery.isLaptopBattery
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btOn: adapter ? adapter.enabled : false
    readonly property string btDevice: {
        if (!adapter)
            return "No adapter";
        const d = adapter.devices.values.find(x => x.connected);
        return d ? d.name : (btOn ? "On" : "Off");
    }

    function run(cmd) {
        runner.command = cmd;
        runner.running = true;
    }
    Process { id: runner }

    function refresh() {
        wifiProbe.running = true;
        connProbe.running = true;
        dndProbe.running = true;
        nightProbe.running = true;
        lightProbe.running = true;
    }
    Component.onCompleted: refresh()

    Process {
        id: wifiProbe
        command: [settings.bin + "/nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: panel.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: connProbe
        command: [settings.bin + "/nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n").map(x => x.split(":")).find(x => x[1] && (x[1].includes("wireless") || x[1].includes("ethernet")));
                panel.wifiName = l ? l[0] : "Not connected";
            }
        }
    }
    Process {
        id: dndProbe
        command: [settings.bin + "/makoctl", "mode"]
        stdout: StdioCollector { onStreamFinished: panel.dnd = text.split("\n").includes("do-not-disturb") }
    }
    Process {
        id: nightProbe
        command: [settings.bin + "/nightlight", "status"]
        onExited: code => panel.nightLight = code === 0
    }
    Process {
        id: lightProbe
        command: [settings.bin + "/brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                panel.hasBacklight = f.length >= 5;
                if (panel.hasBacklight)
                    panel.brightness = parseInt(f[3]) / 100;
            }
        }
    }
    FileView {
        path: settings.stateDir + "/current-wallpaper"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: panel.currentWallpaper = text().trim()
    }

    // --- layout ------------------------------------------------------------
    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Notifications card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: 16
            color: "transparent"

            Rectangle {
                id: bellBox
                width: 44
                height: 44
                radius: 14
                color: theme.surfaceHigh
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.centerIn: parent
                    text: panel.dnd ? "" : ""
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 17
                }
            }
            Column {
                anchors.left: bellBox.right
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: panel.dnd ? "Do not disturb" : "Notifications"
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                Text {
                    text: panel.dnd ? "Silenced" : "All caught up"
                    color: theme.textDim
                    font.family: settings.font
                    font.pixelSize: 11
                }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: clearLabel.implicitWidth + 28
                height: 30
                radius: 15
                color: clearArea.containsMouse ? Qt.lighter(theme.surfaceHigh, 1.25) : theme.surfaceHigh
                Text {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear"
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 12
                }
                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: panel.run([settings.bin + "/makoctl", "dismiss", "--all"])
                }
            }
        }

        // Toggle tiles
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            Tile {
                Layout.fillWidth: true
                icon: ""
                title: "Wi-Fi"
                subtitle: panel.wifiOn ? panel.wifiName : "Off"
                on: panel.wifiOn
                onClicked: {
                    panel.wifiOn = !panel.wifiOn;
                    panel.run([settings.bin + "/nmcli", "radio", "wifi", panel.wifiOn ? "on" : "off"]);
                }
            }
            Tile {
                Layout.fillWidth: true
                icon: ""
                title: "Bluetooth"
                subtitle: panel.btDevice
                on: panel.btOn
                onClicked: if (panel.adapter) panel.adapter.enabled = !panel.adapter.enabled
            }
            Tile {
                Layout.fillWidth: true
                icon: ""
                title: "Do not disturb"
                subtitle: panel.dnd ? "On" : "Off"
                on: panel.dnd
                onClicked: {
                    panel.dnd = !panel.dnd;
                    panel.run([settings.bin + "/makoctl", "mode", panel.dnd ? "-a" : "-r", "do-not-disturb"]);
                }
            }
            Tile {
                Layout.fillWidth: true
                icon: ""
                title: "Night light"
                subtitle: panel.nightLight ? "On" : "Off"
                on: panel.nightLight
                onClicked: {
                    panel.nightLight = !panel.nightLight;
                    panel.run([settings.bin + "/nightlight", "toggle"]);
                }
            }
        }

        // Sliders, battery, power
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            SliderRow {
                Layout.fillWidth: true
                icon: panel.sink && panel.sink.audio && panel.sink.audio.muted ? "" : ""
                value: panel.sink && panel.sink.audio ? Math.min(panel.sink.audio.volume, 1) : 0
                onMoved: v => { if (panel.sink && panel.sink.audio) panel.sink.audio.volume = v; }
            }
            SliderRow {
                visible: panel.hasBacklight
                Layout.fillWidth: true
                icon: ""
                value: panel.brightness
                onMoved: v => {
                    panel.brightness = v;
                    panel.run([settings.bin + "/brightnessctl", "-c", "backlight", "set", Math.round(v * 100) + "%"]);
                }
            }
            Column {
                visible: panel.hasBattery
                Text {
                    text: Math.round((panel.battery?.percentage ?? 0) * 100) + " %"
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 13
                }
                Text {
                    text: panel.battery && panel.battery.state === UPowerDeviceState.Charging ? "Charging" : "Not charging"
                    color: theme.textDim
                    font.family: settings.font
                    font.pixelSize: 11
                }
            }
            Row {
                spacing: 8
                RoundButton {
                    icon: "\uf013"
                    onActivated: { panel.closeRequested(); panel.settingsRequested(); }
                }
                RoundButton {
                    icon: ""
                    onActivated: { panel.run(["loginctl", "lock-session"]); panel.closeRequested(); }
                }
                RoundButton {
                    icon: ""
                    confirm: true
                    onActivated: panel.run([settings.bin + "/systemctl", "suspend"])
                }
                RoundButton {
                    icon: ""
                    confirm: true
                    onActivated: panel.run([settings.bin + "/systemctl", "reboot"])
                }
                RoundButton {
                    icon: ""
                    confirm: true
                    onActivated: panel.run([settings.bin + "/systemctl", "poweroff"])
                }
            }
        }

        // Wallpaper strip
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ListView {
                id: strip
                Layout.fillWidth: true
                implicitHeight: 54
                orientation: ListView.Horizontal
                spacing: 8
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                model: FolderListModel {
                    folder: "file://" + settings.wallpaperDir
                    nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                    showDirs: false
                    sortField: FolderListModel.Name
                }

                delegate: Rectangle {
                    required property string filePath
                    readonly property bool current: panel.currentWallpaper === filePath

                    width: 80
                    height: 54
                    radius: 12
                    color: theme.surfaceHigh

                    Image {
                        id: thumb
                        anchors.fill: parent
                        anchors.margins: current ? 2 : 0
                        source: "file://" + filePath
                        sourceSize.width: 160
                        sourceSize.height: 108
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: thumbMask
                        }
                    }
                    // Rounded mask for the image, matching the inner edge of the border.
                    Rectangle {
                        id: thumbMask
                        anchors.fill: thumb
                        radius: parent.radius - (current ? 2 : 0)
                        visible: false
                        layer.enabled: true
                    }
                    // Active border drawn over the image so no square corners poke out.
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: current ? 2 : 0
                        border.color: theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: panel.run([settings.bin + "/set-wallpaper", filePath])
                    }
                }

                WheelHandler {
                    onWheel: event => strip.contentX = Math.max(0, Math.min(strip.contentWidth - strip.width, strip.contentX - event.angleDelta.y))
                }
            }

            Rectangle {
                implicitWidth: wpLabel.implicitWidth + 44
                implicitHeight: 54
                radius: 16
                color: wpArea.containsMouse ? Qt.lighter(theme.surfaceHigh, 1.15) : theme.surfaceHigh
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: ""
                        color: theme.text
                        font.family: settings.font
                        font.pixelSize: 15
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: wpLabel
                        text: "Wallpapers"
                        color: theme.text
                        font.family: settings.font
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: wpArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { panel.closeRequested(); panel.wallpapersRequested(); }
                }
            }
        }
    }
}
