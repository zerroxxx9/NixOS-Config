import QtQuick
import QtQuick.Window
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import QtMultimedia
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window
    focus: true

    Caching { id: paths }
    readonly property string videoPath: paths.getRunDir("updater") + "/video.mp4"
    
    // WAYLAND ANTI-DEADLOCK: Guarantee the initial frame is never 0x0.
    // If mainCard.width evaluates to 0 on tick 1, it falls back to raw 500.
    implicitWidth: mainCard.width || 500
    implicitHeight: mainCard.height || 600

    property bool _init: false

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    
    function s(val) { 
        // Failsafe: If Screen.width isn't ready on tick 1, return the raw value
        let res = scaler.s(val);
        return res > 0 ? res : val; 
    }

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette + Added Blob Colors)
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }
    
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle || _theme.base
    readonly property color crust: _theme.crust
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color green: _theme.green
    
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color blue: _theme.blue || "#89b4fa"

    // -------------------------------------------------------------------------
    // STATE & POLLING
    // -------------------------------------------------------------------------
    property string localVersion: "..."
    property string remoteVersion: "..."
    
    // Dynamic URL based on the user's current version vs the manifest
    property string videoUrl: ""
    property bool uiExpanded: false
    property bool videoReady: false
    
    property var pendingCommits: []
    property int typeIndex: 0

    ListModel { id: commitModel }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    Keys.onEscapePressed: {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
        event.accepted = true;
    }

    // =========================================================================
    // ASYNC BOOT MANAGER
    // Ensures UI maps perfectly in the compositor before firing heavy scripts
    // =========================================================================
    Timer {
        id: bootSequence
        interval: 250 // Give Hyprland a quarter-second to map the window
        running: true
        onTriggered: {
            window._init = true;
            localVerProcess.running = true;
            remoteVerProcess.running = true;
            videoResolveProcess.running = true;
            commitFetchProcess.running = true;
        }
    }

    // --- 1. LOCAL VERSION FETCH ---
    Process {
        id: localVerProcess
        running: false
        command: ["bash", "-c", "source ~/.local/state/imperative-dots-version 2>/dev/null && [ -n \"$LOCAL_VERSION\" ] && echo $LOCAL_VERSION || echo '0.0.0'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text ? this.text.trim() : "";
                if (out !== "") window.localVersion = out;
            }
        }
    }

    // --- 2. REMOTE VERSION FETCH ---
    Process {
        id: remoteVerProcess
        running: false
        command: ["bash", "-c", "true"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text ? this.text.trim() : "";
                if (out !== "") window.remoteVersion = out;
            }
        }
    }

    // --- 3. DYNAMIC VIDEO RESOLUTION ---
    property string videoResolveScript: `
print("")
`

    Process {
        id: videoResolveProcess
        running: false
        command: ["python3", "-c", window.videoResolveScript]
        stdout: StdioCollector {
            onStreamFinished: {
                let url = this.text ? this.text.trim() : "";
                if (url !== "" && url.startsWith("http")) {
                    window.videoUrl = url;
                    window.uiExpanded = true;
                    videoDownloadProcess.running = true;
                }
            }
        }
    }

    // --- 4. VIDEO DOWNLOAD (BACKGROUND DISK WRITE) ---
    Process {
        id: videoDownloadProcess
        running: false
        // Quietly pulls the mp4 to RAM/tmpfs to avoid locking the UI thread
        command: ["bash", "-c", "true"]
        onExited: {
            if (exitCode === 0) {
                videoPlayer.source = "file://" + window.videoPath;
                videoPlayer.play();
                window.videoReady = true; // Fades out spinner, fades in video
            }
        }
    }

    // --- 5. COMMIT LOG FETCH ---
    property string fetchScript: `
print("Remote update checks disabled. Use nix flake update and rebuild.")
`

    Process {
        id: commitFetchProcess
        running: false
        command: ["python3", "-c", window.fetchScript]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text ? this.text.trim() : "";
                if (out !== "") {
                    let blocks = out.split("---SPLIT---");
                    let validLines = [];
                    for (let i = 0; i < blocks.length; i++) {
                        let blockTrimmed = blocks[i].trim();
                        if (blockTrimmed === "") continue;
                        let lines = blockTrimmed.split(/\r\n|\n/);
                        for (let j = 0; j < lines.length; j++) {
                            let trimmed = lines[j].trim();
                            if (trimmed.length > 0) validLines.push(trimmed);
                        }
                    }
                    commitModel.clear();
                    if (validLines.length > 0) {
                        window.pendingCommits = validLines;
                        window.typeIndex = 0;
                        commitBoxTimer.start();
                    } else {
                        commitModel.append({ "lineText": "No changelog available." });
                    }
                } else {
                    commitModel.clear();
                    commitModel.append({ "lineText": "No changelog available." });
                }
            }
        }
    }

    Timer {
        id: commitBoxTimer
        interval: 100
        repeat: true
        onTriggered: {
            if (window.typeIndex < window.pendingCommits.length) {
                commitModel.append({ "lineText": window.pendingCommits[window.typeIndex] });
                window.typeIndex++;
            } else {
                stop();
            }
        }
    }

    // =========================================================================
    // UI LAYOUT
    // =========================================================================
    Rectangle {
        id: mainCard
        width: window.uiExpanded ? window.s(950) : window.s(500)
        height: window.uiExpanded ? window.s(850) : window.s(600)
        anchors.centerIn: parent 
        
        radius: window.s(16)
        color: window.base
        border.color: window.surface1
        border.width: 1
        clip: true

        Behavior on width { enabled: window._init; NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }
        Behavior on height { enabled: window._init; NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }

        // --- AMBIENT BLOBS ---
        Rectangle {
            width: parent.width * 0.8; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * window.s(150)
            y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * window.s(100)
            opacity: 0.08
            color: window.mauve
            Behavior on color { ColorAnimation { duration: 1000 } }
        }
        
        Rectangle {
            width: parent.width * 0.9; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(-150)
            y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(-100)
            opacity: 0.06
            color: window.blue
            Behavior on color { ColorAnimation { duration: 1000 } }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: window.s(25)
            spacing: window.s(20)

            // --- ANIMATED CHOREOGRAPHED VERSIONS ---
            Item {
                id: versionContainer
                Layout.fillWidth: true
                Layout.preferredHeight: window.s(60)

                Text { 
                    id: oldVer
                    text: window.localVersion
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(22)
                    color: window.subtext0 
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 0 
                }
                
                Text { 
                    id: newVer
                    text: window.remoteVersion
                    font.family: "JetBrains Mono"
                    font.weight: Font.Black
                    font.pixelSize: window.s(48) 
                    color: window.green 
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: window.s(20)
                    opacity: 0
                    scale: 0.8 
                }

                MultiEffect {
                    id: newVerEffect
                    source: newVer
                    anchors.fill: newVer
                    shadowEnabled: true
                    shadowColor: window.green
                    shadowBlur: 0.0
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    opacity: newVer.opacity
                }

                SequentialAnimation {
                    id: versionAnim

                    PauseAnimation { duration: 150 }

                    ParallelAnimation {
                        NumberAnimation { target: oldVer; property: "anchors.horizontalCenterOffset"; to: window.s(-30); duration: 1200; easing.type: Easing.OutExpo }
                        NumberAnimation { target: oldVer; property: "opacity"; to: 0.0; duration: 1000; easing.type: Easing.OutSine }

                        SequentialAnimation {
                            PauseAnimation { duration: 400 } 
                            ParallelAnimation {
                                NumberAnimation { target: newVer; property: "opacity"; to: 1; duration: 800; easing.type: Easing.OutSine }
                                NumberAnimation { target: newVer; property: "anchors.horizontalCenterOffset"; to: 0; duration: 1200; easing.type: Easing.OutExpo }
                                NumberAnimation { target: newVer; property: "scale"; to: 1.0; duration: 1200; easing.type: Easing.OutBack; easing.overshoot: 1.4 }
                            }
                            ScriptAction { script: glowAnim.start() }
                        }
                    }
                }

                SequentialAnimation {
                    id: glowAnim
                    loops: Animation.Infinite
                    NumberAnimation { target: newVerEffect; property: "shadowBlur"; to: 0.8; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { target: newVerEffect; property: "shadowBlur"; to: 0.2; duration: 1500; easing.type: Easing.InOutSine }
                }

                Connections {
                    target: window
                    function onRemoteVersionChanged() {
                        if (window.remoteVersion !== "..." && window.remoteVersion !== "") {
                            versionAnim.start();
                        }
                    }
                }
            }

            // --- STRICT 16:9 DYNAMIC VIDEO PREVIEW ---
            Item {
                id: videoContainer
                Layout.fillWidth: true
                // Perfectly clamps height to a 16:9 ratio of the dynamic width
                Layout.preferredHeight: window.uiExpanded ? (width * 9 / 16) : 0 
                visible: window.uiExpanded || height > 0
                clip: true
                
                Behavior on Layout.preferredHeight { enabled: window._init; NumberAnimation { duration: 600; easing.type: Easing.OutExpo } }

                Rectangle {
                    anchors.fill: parent
                    radius: window.s(12)
                    color: window.crust 
                    border.color: window.surface2 
                    border.width: 1
                    clip: true

                    // Loading State Animation (Visible while downloading)
                    Item {
                        anchors.centerIn: parent
                        width: window.s(42)
                        height: window.s(42)
                        visible: window.uiExpanded && !window.videoReady
                        
                        Text {
                            anchors.centerIn: parent
                            text: "󰑮"
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: window.s(42)
                            color: window.mauve
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            transformOrigin: Item.Center
                            
                            RotationAnimation on rotation {
                                from: 0; to: 360; duration: 2500; loops: Animation.Infinite; running: parent.visible
                            }
                        }
                    }

                    MediaPlayer {
                        id: videoPlayer
                        videoOutput: videoOutput
                        loops: MediaPlayer.Infinite
                    }

                    VideoOutput {
                        id: videoOutput
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectFit 
                        
                        // Fades in smoothly once the local video is physically ready
                        opacity: window.videoReady ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 800; easing.type: Easing.InOutQuad } }
                    }
                }
            }

            // --- CLEAN COMMIT LIST ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: changelogList
                    anchors.fill: parent
                    clip: true
                    model: commitModel
                    spacing: window.s(8)

                    ScrollBar.vertical: ScrollBar {
                        active: true
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { 
                            implicitWidth: window.s(3); radius: window.s(1.5); color: window.surface2; opacity: 0.5 
                        }
                    }

                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400; easing.type: Easing.OutExpo }
                            NumberAnimation { property: "scale"; from: 0.95; to: 1; duration: 450; easing.type: Easing.OutBack }
                            NumberAnimation { property: "y"; from: y + window.s(15); duration: 450; easing.type: Easing.OutExpo }
                        }
                    }

                    delegate: Rectangle {
                        width: changelogList.width - window.s(12) 
                        height: Math.max(window.s(40), commitText.implicitHeight + window.s(20))
                        color: window.surface0 
                        radius: window.s(12)

                        // Subtle Matugen Tint Overlay
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: window.mauve
                            opacity: 0.05
                        }
                        
                        Text {
                            id: commitText
                            anchors.fill: parent
                            anchors.margins: window.s(10)
                            anchors.leftMargin: window.s(16)
                            anchors.rightMargin: window.s(16)
                            text: model.lineText
                            font.family: "JetBrains Mono"
                            font.pixelSize: window.s(13)
                            color: window.text
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                            lineHeight: 1.4
                        }
                    }
                }
            }

            // --- HOLD TO UPDATE BUTTON ---
            Rectangle {
                id: updateBtn
                Layout.alignment: Qt.AlignHCenter 
                Layout.preferredWidth: window.s(240) 
                Layout.preferredHeight: window.s(54)
                radius: window.s(12)
                color: window.surface0
                border.color: btnMa.containsMouse ? window.green : window.surface2
                border.width: btnMa.containsMouse ? window.s(2) : 1
                clip: true
                
                scale: btnMa.pressed ? 0.98 : (btnMa.containsMouse ? 1.01 : 1.0)
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                property real fillLevel: 0.0
                property bool triggered: false

                Canvas {
                    id: waveCanvas
                    anchors.fill: parent
                    
                    property real wavePhase: 0.0
                    NumberAnimation on wavePhase {
                        running: updateBtn.fillLevel > 0.0 && updateBtn.fillLevel < 1.0
                        loops: Animation.Infinite
                        from: 0; to: Math.PI * 2
                        duration: 1000
                    }
                    
                    onWavePhaseChanged: requestPaint()
                    Connections { target: updateBtn; function onFillLevelChanged() { waveCanvas.requestPaint() } }
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        if (updateBtn.fillLevel <= 0.001) return;

                        var currentW = width * updateBtn.fillLevel;
                        var r = window.s(12);

                        ctx.save();
                        ctx.beginPath();
                        ctx.moveTo(0, 0);
                        
                        if (updateBtn.fillLevel < 0.99) {
                            var waveAmp = window.s(8) * Math.sin(updateBtn.fillLevel * Math.PI); 
                            var cp1x = currentW + Math.sin(wavePhase) * waveAmp;
                            var cp2x = currentW + Math.cos(wavePhase + Math.PI) * waveAmp;

                            ctx.lineTo(currentW, 0);
                            ctx.bezierCurveTo(cp2x, height * 0.33, cp1x, height * 0.66, currentW, height);
                            ctx.lineTo(0, height);
                        } else {
                            ctx.lineTo(width, 0);
                            ctx.lineTo(width, height);
                            ctx.lineTo(0, height);
                        }
                        ctx.closePath();
                        ctx.clip(); 

                        ctx.beginPath();
                        ctx.roundedRect(0, 0, width, height, r, r);
                        var grad = ctx.createLinearGradient(0, 0, width, 0);
                        grad.addColorStop(0, Qt.darker(window.green, 1.1).toString());
                        grad.addColorStop(1, window.green.toString());
                        ctx.fillStyle = grad;
                        ctx.fill();

                        ctx.restore();
                    }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: window.s(10)
                    
                    Text { 
                        text: "󰚰"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: window.s(18)
                        color: updateBtn.fillLevel > 0.5 ? window.crust : window.green 
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    Text { 
                        text: updateBtn.fillLevel > 0 ? "HOLDING..." : "UPDATE"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Black
                        font.pixelSize: window.s(14)
                        color: updateBtn.fillLevel > 0.5 ? window.crust : window.green 
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: btnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: updateBtn.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor
                    
                    onPressed: {
                        if (!updateBtn.triggered) {
                            drainAnim.stop();
                            fillAnim.start();
                        }
                    }
                    
                    onReleased: {
                        if (!updateBtn.triggered && updateBtn.fillLevel < 1.0) {
                            fillAnim.stop();
                            drainAnim.start();
                        }
                    }
                }

                NumberAnimation {
                    id: fillAnim
                    target: updateBtn
                    property: "fillLevel"
                    to: 1.0
                    duration: 1200 * (1.0 - updateBtn.fillLevel)
                    easing.type: Easing.InSine
                    onFinished: {
                        updateBtn.triggered = true;
                        Quickshell.execDetached(["notify-send", "Updater disabled", "Use nix flake update and rebuild from your dotfiles."]);
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                    }
                }

                NumberAnimation {
                    id: drainAnim
                    target: updateBtn
                    property: "fillLevel"
                    to: 0.0
                    duration: 800 * updateBtn.fillLevel
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
