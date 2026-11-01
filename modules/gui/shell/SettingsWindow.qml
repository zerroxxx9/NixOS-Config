import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

FloatingWindow {
    id: win
    property bool open: false
    property int page: 0
    property int eggClicks: 0
    readonly property bool egg: eggClicks >= 5
    property int mood: 0
    signal closeRequested
    signal wallpapersRequested

    visible: open
    title: "Settings"
    implicitWidth: 880
    implicitHeight: 640
    minimumSize: Qt.size(700, 580)
    color: theme.surface
    onClosed: closeRequested()
    onVisibleChanged: if (visible) refresh()

    readonly property var pages: [
        { name: "Sound", icon: "\uf028" },
        { name: "Network", icon: "\uf1eb" },
        { name: "Bluetooth", icon: "\uf294" },
        { name: "Display", icon: "\uf108" },
        { name: "Power", icon: "\uf011" },
        { name: "Appearance", icon: "\uf1fc" },
        { name: "Notifications", icon: "\uf0f3" },
        { name: "Keyboard", icon: "\uf11c" },
        { name: "VPN", icon: "\uf132" },
        { name: "About", icon: "\uf05a" }
    ]

    function run(cmd) {
        runner.command = cmd;
        runner.running = true;
    }
    Process { id: runner }

    function refresh() {
        wifiRadio.running = true;
        wifiList.running = true;
        monitors.running = true;
        profileGet.running = true;
        lightProbe.running = true;
        dndProbe.running = true;
        kbProbe.running = true;
        tsProbe.running = true;
        aboutProbe.running = true;
    }

    property bool wifiOn: false
    property var networks: []
    property string netStatus: ""
    property var monitorInfo: []
    property string profile: ""
    property bool hasBacklight: false
    property real brightness: 0
    property bool dnd: false
    property string currentWallpaper: ""
    property var keyboards: []
    property bool tsInstalled: true
    property bool tsUp: false
    property string tsStatus: ""
    property var aboutLines: []

    readonly property var audioNodes: Pipewire.nodes.values.filter(n => n.audio && !n.isStream)
    readonly property var sinks: audioNodes.filter(n => n.isSink)
    readonly property var sources: audioNodes.filter(n => !n.isSink)
    PwObjectTracker { objects: win.audioNodes }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isPresent && battery.isLaptopBattery

    Process {
        id: wifiRadio
        command: [settings.bin + "/nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: win.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: wifiList
        command: [settings.bin + "/nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const line of text.split("\n")) {
                    const f = line.replace(/\\:/g, "\u0001").split(":").map(x => x.replace(/\u0001/g, ":"));
                    if (f.length < 4 || !f[1] || seen[f[1]])
                        continue;
                    seen[f[1]] = true;
                    out.push({ active: f[0] === "*", ssid: f[1], signal: parseInt(f[2]) || 0, secure: f[3] !== "" && f[3] !== "--" });
                }
                out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
                win.networks = out;
            }
        }
    }
    Process {
        id: wifiConnect
        property string ssid
        command: [settings.bin + "/nmcli", "device", "wifi", "connect", ssid]
        stdout: StdioCollector { onStreamFinished: win.netStatus = text.trim() }
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") win.netStatus = text.trim() }
        onExited: wifiList.running = true
    }
    Process {
        id: monitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    win.monitorInfo = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    Process {
        id: profileGet
        command: [settings.bin + "/powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: win.profile = text.trim() }
    }
    Process {
        id: lightProbe
        command: [settings.bin + "/brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                win.hasBacklight = f.length >= 5;
                if (win.hasBacklight)
                    win.brightness = parseInt(f[3]) / 100;
            }
        }
    }

    Process {
        id: dndProbe
        command: [settings.bin + "/makoctl", "mode"]
        stdout: StdioCollector { onStreamFinished: win.dnd = text.split("\n").includes("do-not-disturb") }
    }
    FileView {
        path: settings.stateDir + "/current-wallpaper"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: win.currentWallpaper = text().trim()
    }
    Process {
        id: kbProbe
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    win.keyboards = JSON.parse(text).keyboards.filter(k => k.main || k.active_keymap);
                } catch (e) {}
            }
        }
    }
    Process {
        id: tsProbe
        command: [settings.bin + "/tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    win.tsUp = j.BackendState === "Running";
                    win.tsStatus = j.BackendState + (j.Self ? "  \u00b7  " + j.Self.HostName + "  \u00b7  " + (j.Self.TailscaleIPs || [""])[0] : "");
                } catch (e) {
                    win.tsUp = false;
                    win.tsStatus = "Unavailable";
                }
            }
        }
        onExited: code => win.tsInstalled = code !== 127
    }
    Process {
        id: tsToggle
        command: [settings.bin + "/tailscale", win.tsUp ? "down" : "up"]
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") win.tsStatus = text.trim() }
        onExited: tsProbe.running = true
    }
    Process {
        id: aboutProbe
        command: [settings.bin + "/sh", "-c", "hostname; uname -sr; nixos-version; uptime -p; df -h --output=used,size,pcent / | tail -n1; echo \"$XDG_CURRENT_DESKTOP\""]
        stdout: StdioCollector { onStreamFinished: win.aboutLines = text.trim().split("\n") }
    }

    component Heading: Text {
        color: theme.text
        font.family: settings.font
        font.pixelSize: 22
        font.weight: Font.Medium
    }
    component Label: Text {
        color: theme.textDim
        font.family: settings.font
        font.pixelSize: 12
    }
    component Section: Text {
        color: theme.textDim
        font.family: settings.font
        font.pixelSize: 11
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1
        topPadding: 6
    }
    component Row_: Rectangle {
        id: r
        property string title
        property string subtitle
        property string trailing
        property bool selected: false
        signal clicked

        Layout.fillWidth: true
        implicitHeight: 52
        radius: 14
        color: selected ? theme.accent : (m.containsMouse ? Qt.lighter(theme.surfaceHigh, 1.15) : theme.surfaceHigh)
        Behavior on color { ColorAnimation { duration: 140 } }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: tail.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            Text {
                width: parent.width
                text: r.title
                elide: Text.ElideRight
                color: r.selected ? theme.accentText : theme.text
                font.family: settings.font
                font.pixelSize: 14
            }
            Text {
                visible: r.subtitle !== ""
                width: parent.width
                text: r.subtitle
                elide: Text.ElideRight
                color: r.selected ? Qt.rgba(theme.accentText.r, theme.accentText.g, theme.accentText.b, 0.7) : theme.textDim
                font.family: settings.font
                font.pixelSize: 11
            }
        }
        Text {
            id: tail
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: r.trailing
            color: r.selected ? theme.accentText : theme.textDim
            font.family: settings.font
            font.pixelSize: 12
        }
        MouseArea {
            id: m
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: r.clicked()
        }
    }
    component Toggle: Rectangle {
        id: t
        property bool checked: false
        signal toggled
        implicitWidth: 46
        implicitHeight: 26
        radius: 13
        color: checked ? theme.accent : theme.surfaceHigh
        Behavior on color { ColorAnimation { duration: 140 } }
        Rectangle {
            y: 3
            x: t.checked ? parent.width - width - 3 : 3
            width: 20
            height: 20
            radius: 10
            color: t.checked ? theme.accentText : theme.textDim
            Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: t.toggled()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 200
            color: theme.surfaceHigh

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 4

                Text {
                    text: "Settings"
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    padding: 8
                    bottomPadding: 14
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            win.eggClicks++;
                            if (win.eggClicks === 5)
                                win.page = win.pages.length;
                        }
                    }
                }
                Repeater {
                    model: win.egg ? win.pages.concat([{ name: "???", icon: "\uf1b0" }]) : win.pages
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: parent.width
                        height: 40
                        radius: 12
                        color: win.page === index ? theme.accent : (sm.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent")
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 14
                            spacing: 12
                            Text {
                                text: modelData.icon
                                color: win.page === index ? theme.accentText : theme.text
                                font.family: settings.font
                                font.pixelSize: 15
                                width: 18
                            }
                            Text {
                                text: modelData.name
                                color: win.page === index ? theme.accentText : theme.text
                                font.family: settings.font
                                font.pixelSize: 14
                            }
                        }
                        MouseArea {
                            id: sm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { win.page = index; win.refresh(); }
                        }
                    }
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: win.page

            Flickable {
                contentHeight: soundCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: soundCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    Heading { text: "Sound" }
                    Section { text: "Output" }
                    SliderRow {
                        Layout.fillWidth: true
                        icon: Pipewire.defaultAudioSink?.audio?.muted ? "\uf026" : "\uf028"
                        value: Math.min(Pipewire.defaultAudioSink?.audio?.volume ?? 0, 1)
                        onMoved: v => { if (Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume = v; }
                    }
                    Repeater {
                        model: win.sinks
                        delegate: Row_ {
                            required property var modelData
                            title: modelData.description || modelData.nickname || modelData.name
                            selected: Pipewire.defaultAudioSink === modelData
                            trailing: Math.round((modelData.audio?.volume ?? 0) * 100) + " %"
                            onClicked: Pipewire.preferredDefaultAudioSink = modelData
                        }
                    }
                    Section { text: "Input" }
                    SliderRow {
                        Layout.fillWidth: true
                        icon: Pipewire.defaultAudioSource?.audio?.muted ? "\uf131" : "\uf130"
                        value: Math.min(Pipewire.defaultAudioSource?.audio?.volume ?? 0, 1)
                        onMoved: v => { if (Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.volume = v; }
                    }
                    Repeater {
                        model: win.sources
                        delegate: Row_ {
                            required property var modelData
                            title: modelData.description || modelData.nickname || modelData.name
                            selected: Pipewire.defaultAudioSource === modelData
                            trailing: modelData.audio?.muted ? "Muted" : Math.round((modelData.audio?.volume ?? 0) * 100) + " %"
                            onClicked: Pipewire.preferredDefaultAudioSource = modelData
                        }
                    }
                }
            }

            Flickable {
                contentHeight: netCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: netCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Heading { text: "Network"; Layout.fillWidth: true }
                        Label { text: "Wi-Fi" }
                        Toggle {
                            checked: win.wifiOn
                            onToggled: {
                                win.wifiOn = !win.wifiOn;
                                win.run([settings.bin + "/nmcli", "radio", "wifi", win.wifiOn ? "on" : "off"]);
                                relist.restart();
                            }
                        }
                    }
                    Timer { id: relist; interval: 2500; onTriggered: wifiList.running = true }
                    Label {
                        visible: win.netStatus !== ""
                        text: win.netStatus
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    Section { text: "Available networks" }
                    Label { visible: win.wifiOn && win.networks.length === 0; text: "No networks found" }
                    Label { visible: !win.wifiOn; text: "Wi-Fi is off" }
                    Repeater {
                        model: win.wifiOn ? win.networks : []
                        delegate: Row_ {
                            required property var modelData
                            title: modelData.ssid
                            subtitle: modelData.secure ? "Secured" : "Open"
                            trailing: modelData.active ? "Connected  ·  " + modelData.signal + " %" : modelData.signal + " %"
                            selected: modelData.active
                            onClicked: {
                                if (modelData.active)
                                    return;
                                win.netStatus = "Connecting to " + modelData.ssid + " … (new secured networks need a saved password: nmtui)";
                                wifiConnect.ssid = modelData.ssid;
                                wifiConnect.running = true;
                            }
                        }
                    }
                }
            }

            Flickable {
                contentHeight: btCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: btCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Heading { text: "Bluetooth"; Layout.fillWidth: true }
                        Toggle {
                            visible: win.adapter !== null
                            checked: win.adapter?.enabled ?? false
                            onToggled: if (win.adapter) win.adapter.enabled = !win.adapter.enabled
                        }
                    }
                    Label { visible: !win.adapter; text: "No Bluetooth adapter" }
                    RowLayout {
                        visible: win.adapter?.enabled ?? false
                        Layout.fillWidth: true
                        Label { text: "Scan for new devices"; Layout.fillWidth: true }
                        Toggle {
                            checked: win.adapter?.discovering ?? false
                            onToggled: if (win.adapter) win.adapter.discovering = !win.adapter.discovering
                        }
                    }
                    Repeater {
                        model: win.adapter?.enabled ? win.adapter.devices : null
                        delegate: Row_ {
                            required property var modelData
                            title: modelData.name || modelData.address
                            subtitle: modelData.paired ? "Paired" : "Not paired"
                            trailing: modelData.connected ? "Connected" : ""
                            selected: modelData.connected
                            onClicked: {
                                if (modelData.connected)
                                    modelData.disconnect();
                                else if (modelData.paired)
                                    modelData.connect();
                                else
                                    modelData.pair();
                            }
                        }
                    }
                }
            }

            Flickable {
                contentHeight: dispCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: dispCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    Heading { text: "Display" }
                    Section { visible: win.hasBacklight; text: "Brightness" }
                    SliderRow {
                        visible: win.hasBacklight
                        Layout.fillWidth: true
                        icon: "\uf185"
                        value: win.brightness
                        onMoved: v => {
                            win.brightness = v;
                            win.run([settings.bin + "/brightnessctl", "-c", "backlight", "set", Math.round(v * 100) + "%"]);
                        }
                    }
                    Section { text: "Night light" }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Warm colours (3800 K)"; Layout.fillWidth: true }
                        Toggle {
                            id: nightToggle
                            Component.onCompleted: nightProbe.running = true
                            onToggled: {
                                checked = !checked;
                                win.run([settings.bin + "/nightlight", "toggle"]);
                            }
                            Process {
                                id: nightProbe
                                command: [settings.bin + "/nightlight", "status"]
                                onExited: code => nightToggle.checked = code === 0
                            }
                        }
                    }
                    Section { text: "Monitors" }
                    Repeater {
                        model: win.monitorInfo
                        delegate: Row_ {
                            required property var modelData
                            title: modelData.name + (modelData.description ? "  ·  " + modelData.description : "")
                            subtitle: modelData.width + "×" + modelData.height + " @ " + Math.round(modelData.refreshRate) + " Hz  ·  scale " + modelData.scale
                            trailing: modelData.x + "," + modelData.y
                        }
                    }
                    Label {
                        text: "Layout, scale and resolution are set per host in hosts/<host>/variables.nix (hyprland.monitors)."
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            Flickable {
                contentHeight: powCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: powCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    Heading { text: "Power" }
                    Section { visible: win.hasBattery; text: "Battery" }
                    Row_ {
                        visible: win.hasBattery
                        title: Math.round((win.battery?.percentage ?? 0) * 100) + " %"
                        subtitle: win.battery && win.battery.state === UPowerDeviceState.Charging ? "Charging" : "Not charging"
                    }
                    Section { text: "Power profile" }
                    Repeater {
                        model: [
                            { id: "power-saver", name: "Power saver", note: "Longer battery life" },
                            { id: "balanced", name: "Balanced", note: "Default" },
                            { id: "performance", name: "Performance", note: "Maximum speed" }
                        ]
                        delegate: Row_ {
                            required property var modelData
                            title: modelData.name
                            subtitle: modelData.note
                            selected: win.profile === modelData.id
                            onClicked: {
                                win.profile = modelData.id;
                                win.run([settings.bin + "/powerprofilesctl", "set", modelData.id]);
                            }
                        }
                    }
                    Section { text: "Session" }
                    Row {
                        spacing: 8
                        RoundButton { icon: "\uf023"; onActivated: win.run(["loginctl", "lock-session"]) }
                        RoundButton { icon: "\uf186"; confirm: true; onActivated: win.run([settings.bin + "/systemctl", "suspend"]) }
                        RoundButton { icon: "\uf021"; confirm: true; onActivated: win.run([settings.bin + "/systemctl", "reboot"]) }
                        RoundButton { icon: "\uf011"; confirm: true; onActivated: win.run([settings.bin + "/systemctl", "poweroff"]) }
                    }
                    Label {
                        text: "Idle lock after 5 min and screen off after 11 min are set in modules/gui/shell.nix (hypridle)."
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            Flickable {
                contentHeight: appCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: appCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    Heading { text: "Appearance" }
                    Section { text: "Current wallpaper" }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 200
                        radius: 16
                        color: theme.surfaceHigh
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: win.currentWallpaper !== "" ? "file://" + win.currentWallpaper : ""
                            sourceSize.width: 900
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                    Row_ {
                        title: "Choose wallpaper"
                        subtitle: "Colours of the whole desktop follow the wallpaper"
                        trailing: "\u203a"
                        onClicked: win.wallpapersRequested()
                    }
                    Row_ {
                        title: "Random wallpaper"
                        trailing: "\u203a"
                        onClicked: win.run([settings.bin + "/random-wallpaper"])
                    }
                }
            }

            Flickable {
                contentHeight: notCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: notCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    Heading { text: "Notifications" }
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Do not disturb"; Layout.fillWidth: true }
                        Toggle {
                            checked: win.dnd
                            onToggled: {
                                win.dnd = !win.dnd;
                                win.run([settings.bin + "/makoctl", "mode", win.dnd ? "-a" : "-r", "do-not-disturb"]);
                            }
                        }
                    }
                    Row_ {
                        title: "Clear all notifications"
                        trailing: "\u203a"
                        onClicked: win.run([settings.bin + "/makoctl", "dismiss", "--all"])
                    }
                    Row_ {
                        title: "Restore last notification"
                        trailing: "\u203a"
                        onClicked: win.run([settings.bin + "/makoctl", "restore"])
                    }
                    Row_ {
                        title: "Send test notification"
                        trailing: "\u203a"
                        onClicked: win.run([settings.bin + "/notify-send", "Settings", "This is a test notification"])
                    }
                }
            }

            Flickable {
                contentHeight: kbCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: kbCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    Heading { text: "Keyboard" }
                    Section { text: "Active layout" }
                    Repeater {
                        model: win.keyboards
                        delegate: Row_ {
                            required property var modelData
                            title: modelData.active_keymap
                            subtitle: modelData.name
                            trailing: "Next layout"
                            onClicked: {
                                win.run(["hyprctl", "switchxkblayout", modelData.name, "next"]);
                                kbRefresh.restart();
                            }
                        }
                    }
                    Timer { id: kbRefresh; interval: 300; onTriggered: kbProbe.running = true }
                    Label {
                        text: "Layouts, repeat rate and options are set in the Hyprland input block (modules/gui/hyprland.nix)."
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                }
            }

            Flickable {
                contentHeight: vpnCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: vpnCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Heading { text: "VPN"; Layout.fillWidth: true }
                        Toggle {
                            visible: win.tsInstalled
                            checked: win.tsUp
                            onToggled: tsToggle.running = true
                        }
                    }
                    Label {
                        visible: !win.tsInstalled
                        text: "Tailscale is not enabled on this host (modules.software.tailscale)."
                        wrapMode: Text.Wrap
                        Layout.fillWidth: true
                    }
                    Row_ {
                        visible: win.tsInstalled
                        title: "Tailscale"
                        subtitle: win.tsStatus
                        trailing: win.tsUp ? "Connected" : "Off"
                        selected: win.tsUp
                    }
                }
            }

            Flickable {
                contentHeight: aboutCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: aboutCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 8

                    Heading { text: "About" }
                    Repeater {
                        model: [
                            { k: "Hostname", i: 0 },
                            { k: "Kernel", i: 1 },
                            { k: "NixOS", i: 2 },
                            { k: "Uptime", i: 3 },
                            { k: "Desktop", i: 5 }
                        ]
                        delegate: Row_ {
                            required property var modelData
                            title: modelData.k
                            trailing: win.aboutLines[modelData.i] ?? ""
                        }
                    }
                    Row_ {
                        title: "Disk (/)"
                        trailing: (win.aboutLines[4] ?? "").trim().replace(/\s+/g, " ")
                    }
                    Row_ {
                        title: "Rebuild"
                        subtitle: "Configuration lives in ~/.dotfiles"
                    }
                }
            }

            Flickable {
                contentHeight: eggCol.implicitHeight + 48
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: eggCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 12

                    Heading { text: "You found it" }
                    Text {
                        id: cat
                        readonly property var faces: ["o.o", "-.-", "^.^", "o.O", ">.<", "u.u"]
                        readonly property var quotes: [
                            "it works on my machine (declaratively)",
                            "have you tried turning it off and nixos-rebuild-ing it again?",
                            "rollback is just a reboot away",
                            "purrfectly reproducible",
                            "sudo make me a sandwich",
                            "meow."
                        ]
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: theme.accent
                        font.family: "monospace"
                        font.pixelSize: 28
                        text: " /\\_/\\\n( " + faces[win.mood % faces.length] + " )\n > ^ <  ~"
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.mood = (win.mood + 1 + Math.floor(Math.random() * 4)) % cat.faces.length
                        }
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: cat.quotes[win.mood % cat.quotes.length]
                    }
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: "(click the cat)"
                        opacity: 0.6
                    }
                }
            }
        }
    }
}
