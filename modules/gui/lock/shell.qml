// Lock screen (Wayland session lock, own quickshell instance: `quickshell -c lock`).
// Stage 1 "clock": dimmed wallpaper, big stacked time, date top-left, press any key.
// Stage 2 "login": blurred wallpaper and a card with avatar, name and password pill.
// Colours come from the wallpaper theme (same theme.json as the shell).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower

ShellRoot {
    id: root

    property string stage: "clock"      // "clock" | "login"
    property string password: ""
    property bool busy: false
    property bool failed: false
    property string wallpaper: ""
    property int failCount: 0
    readonly property var shapes: ["●", "◆", "▲", "■", "★", "⬟"]
    readonly property var battery: UPower.displayDevice

    Settings { id: settings }
    Theme { id: theme; path: settings.themeFile }

    SystemClock { id: clock; precision: SystemClock.Seconds }

    FileView {
        path: settings.stateDir + "/current-wallpaper"
        onLoaded: root.wallpaper = text().trim()
    }

    Process { id: runner }
    function run(cmd) { runner.command = cmd; runner.running = true; }

    function submit() {
        if (busy || password === "")
            return;
        busy = true;
        failed = false;
        pam.start();
    }

    function fail() {
        busy = false;
        failed = true;
        failCount++;
        password = "";
    }

    function handleKey(event) {
        if (root.busy) {
            event.accepted = true;
            return;
        }
        if (root.stage === "clock") {
            if (event.key !== Qt.Key_Shift && event.key !== Qt.Key_Control && event.key !== Qt.Key_Alt && event.key !== Qt.Key_Meta)
                root.stage = "login";
            // Keep the first printable key as the start of the password.
            if (event.text.length === 1 && event.text >= " " && event.text !== "\x7f")
                root.password += event.text;
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_Escape) {
            root.password = "";
            root.failed = false;
            root.stage = "clock";
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submit();
        } else if (event.key === Qt.Key_Backspace) {
            root.password = (event.modifiers & Qt.ControlModifier) ? "" : root.password.slice(0, -1);
            root.failed = false;
        } else if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) {
            root.password = "";
        } else if (event.text.length === 1 && event.text >= " " && event.text !== "\x7f") {
            root.password += event.text;
            root.failed = false;
        }
        event.accepted = true;
    }

    PamContext {
        id: pam
        config: "quickshell-lock"
        user: settings.username
        onResponseRequiredChanged: if (responseRequired) respond(root.password)
        onCompleted: result => {
            if (result === PamResult.Success) {
                lock.locked = false;
                Qt.callLater(Qt.quit);
            } else {
                root.fail();
            }
        }
        onError: root.fail()
    }

    WlSessionLock {
        id: lock
        locked: true

        WlSessionLockSurface {
            id: surface
            color: theme.surface

            Item {
                id: scene
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()
                Keys.onPressed: event => root.handleKey(event)

                // --- background ------------------------------------------------
                Image {
                    id: bg
                    anchors.fill: parent
                    source: root.wallpaper ? "file://" + root.wallpaper : ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: surface.width
                    sourceSize.height: surface.height
                    asynchronous: true
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: bg
                    blurEnabled: true
                    blurMax: 64
                    blur: root.stage === "login" ? 1 : 0
                    Behavior on blur { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: root.stage === "login" ? 0.3 : 0.45
                    Behavior on opacity { NumberAnimation { duration: 350 } }
                }

                // Click anywhere on the clock page to continue.
                MouseArea {
                    anchors.fill: parent
                    enabled: root.stage === "clock"
                    onClicked: root.stage = "login"
                }

                // --- stage 1: clock ---------------------------------------------
                Item {
                    id: clockPage
                    anchors.fill: parent
                    opacity: root.stage === "clock" ? 1 : 0
                    visible: opacity > 0
                    transform: Translate {
                        y: root.stage === "clock" ? 0 : -40
                        Behavior on y { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 22
                        text: Qt.formatDateTime(clock.date, "dddd, MMMM d")
                        color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.7)
                        font.family: settings.font
                        font.pixelSize: 17
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: -surface.height * 0.02

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "HH")
                            color: theme.accent
                            font.family: settings.font
                            font.weight: Font.Light
                            font.pixelSize: Math.round(surface.height * 0.2)
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "mm")
                            color: theme.text
                            font.family: settings.font
                            font.weight: Font.Light
                            font.pixelSize: Math.round(surface.height * 0.2)
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 56
                        text: "Press any key to unlock"
                        color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.6)
                        font.family: settings.font
                        font.pixelSize: 13
                    }
                }

                // --- stage 2: login ---------------------------------------------
                Item {
                    id: loginPage
                    anchors.fill: parent
                    opacity: root.stage === "login" ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                    // Battery and power buttons, top right.
                    Column {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 18
                        spacing: 8

                        Text {
                            anchors.right: parent.right
                            visible: root.battery && root.battery.isPresent
                            text: Math.round((root.battery?.percentage ?? 0) * 100) + "%"
                            color: Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.8)
                            font.family: settings.font
                            font.pixelSize: 12
                        }
                        Rectangle {
                            anchors.right: parent.right
                            width: powerRow.width + 24
                            height: 34
                            radius: 17
                            color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.7)

                            Row {
                                id: powerRow
                                anchors.centerIn: parent
                                spacing: 6

                                Repeater {
                                    model: [
                                        { glyph: "☾", cmd: ["systemctl", "suspend"] },
                                        { glyph: "↻", cmd: ["systemctl", "reboot"] },
                                        { glyph: "⏻", cmd: ["systemctl", "poweroff"] }
                                    ]
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: pArea.containsMouse ? theme.surfaceHigh : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: parent.modelData.glyph
                                            color: theme.text
                                            font.pixelSize: 15
                                        }
                                        MouseArea {
                                            id: pArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.run(parent.modelData.cmd)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: card
                        anchors.centerIn: parent
                        width: 330
                        height: 420
                        radius: 28
                        color: Qt.rgba(theme.surface.r, theme.surface.g, theme.surface.b, 0.92)
                        border.width: 1
                        border.color: Qt.rgba(theme.outline.r, theme.outline.g, theme.outline.b, 0.5)
                        scale: root.stage === "login" ? 1 : 0.95
                        Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                        Item {
                            id: avatar
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 44
                            width: 132
                            height: 132

                            Image {
                                id: avatarImg
                                anchors.fill: parent
                                source: "file://" + settings.avatar
                                sourceSize.width: 264
                                sourceSize.height: 264
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: avatarMask
                                }
                            }
                            Rectangle {
                                id: avatarMask
                                anchors.fill: parent
                                radius: width / 2
                                visible: false
                                layer.enabled: true
                            }
                        }

                        Text {
                            id: nameText
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: avatar.bottom
                            anchors.topMargin: 22
                            text: settings.username
                            color: theme.text
                            font.family: settings.font
                            font.weight: Font.DemiBold
                            font.pixelSize: 22
                        }

                        Rectangle {
                            id: sessionChip
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: nameText.bottom
                            anchors.topMargin: 8
                            width: chipText.width + 22
                            height: 24
                            radius: 8
                            color: theme.surfaceHigh
                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: "Hyprland"
                                color: theme.textDim
                                font.family: settings.font
                                font.pixelSize: 12
                            }
                        }

                        // Password pill: one shape per typed character.
                        Rectangle {
                            id: pill
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 32
                            width: parent.width - 56
                            height: 50
                            radius: 25
                            color: theme.surfaceHigh
                            border.width: root.failed ? 2 : 0
                            border.color: theme.error

                            SequentialAnimation {
                                id: shake
                                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -12; duration: 50 }
                                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 12; duration: 80 }
                                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: -8; duration: 70 }
                                NumberAnimation { target: pill; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
                            }
                            Connections {
                                target: root
                                function onFailCountChanged() { shake.restart(); }
                            }

                            Item {
                                id: dots
                                anchors.left: parent.left
                                anchors.leftMargin: 20
                                anchors.right: submitBtn.left
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                height: 24
                                clip: true

                                Text {
                                    visible: root.password === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.failed ? "Wrong password" : (root.busy ? "Checking…" : "Password")
                                    color: root.failed ? theme.error : theme.textDim
                                    font.family: settings.font
                                    font.pixelSize: 14
                                }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.min(0, dots.width - width)
                                    spacing: 5
                                    Repeater {
                                        model: root.password.length
                                        delegate: Text {
                                            required property int index
                                            text: root.shapes[index % root.shapes.length]
                                            color: theme.text
                                            font.pixelSize: 14
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                id: submitBtn
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                width: 38
                                height: 38
                                radius: 19
                                color: theme.accent
                                opacity: root.busy ? 0.5 : 1
                                Text {
                                    anchors.centerIn: parent
                                    text: "→"
                                    color: theme.accentText
                                    font.pixelSize: 18
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.submit()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
