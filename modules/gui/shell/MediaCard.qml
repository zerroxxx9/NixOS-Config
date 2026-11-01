// Now-playing card for the quick settings panel: cover art, title/artist,
// prev / play-pause / next, and a waveform-style seek bar with elapsed and
// total time. Hidden when no MPRIS player is running.
import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris

Rectangle {
    id: card

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool playing: !!player && player.isPlaying
    readonly property real length: player && player.lengthSupported ? player.length : 0
    readonly property real position: player && player.positionSupported ? player.position : 0
    readonly property real ratio: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    visible: !!player
    implicitHeight: 128
    radius: 20
    color: theme.surfaceHigh

    function fmt(s) {
        s = Math.max(0, Math.floor(s));
        const m = Math.floor(s / 60);
        return m + ":" + String(s % 60).padStart(2, "0");
    }

    // Position is not pushed by MPRIS; poll while playing.
    Timer {
        interval: 500
        repeat: true
        running: card.visible && card.playing
        onTriggered: card.player.positionChanged()
    }

    // --- top row: cover, text, controls ---------------------------------
    Item {
        id: top
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 56

        Item {
            id: cover
            width: 56
            height: 56
            Image {
                id: art
                anchors.fill: parent
                source: card.player ? card.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 112
                sourceSize.height: 112
                asynchronous: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: artMask
                }
            }
            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: 10
                visible: false
                layer.enabled: true
            }
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: theme.surface
                visible: art.status !== Image.Ready
                z: -1
            }
        }

        Column {
            anchors.left: cover.right
            anchors.leftMargin: 14
            anchors.right: controls.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: card.player ? (card.player.trackTitle || "Unknown") : ""
                color: theme.text
                font.family: settings.font
                font.weight: Font.DemiBold
                font.pixelSize: 16
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: card.player ? card.player.trackArtist : ""
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 13
            }
        }

        Row {
            id: controls
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "⏮"
                color: card.player && card.player.canGoPrevious ? theme.text : theme.textDim
                font.pixelSize: 16
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (card.player.canGoPrevious) card.player.previous()
                }
            }
            Rectangle {
                width: 48
                height: 48
                radius: 24
                color: theme.text
                Text {
                    anchors.centerIn: parent
                    text: card.playing ? "⏸" : "▶"
                    color: theme.surface
                    font.pixelSize: 18
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.player.togglePlaying()
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "⏭"
                color: card.player && card.player.canGoNext ? theme.text : theme.textDim
                font.pixelSize: 16
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (card.player.canGoNext) card.player.next()
                }
            }
        }
    }

    // --- waveform seek bar ------------------------------------------------
    Item {
        id: wave
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: top.bottom
        anchors.margins: 14
        anchors.topMargin: 8
        height: 30

        readonly property int step: 9
        readonly property int bars: Math.max(1, Math.floor(width / step))

        Repeater {
            model: wave.bars
            delegate: Rectangle {
                required property int index
                // Stable pseudo-waveform; played bars are bright and thick.
                readonly property real h: 0.25 + 0.75 * Math.abs(Math.sin(index * 0.9) * Math.cos(index * 0.37 + 1.3))
                readonly property bool played: (index + 0.5) / wave.bars <= card.ratio
                x: index * wave.step
                width: played ? 5 : 4
                height: Math.max(played ? 5 : 4, wave.height * h)
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: played ? theme.text : Qt.rgba(theme.text.r, theme.text.g, theme.text.b, 0.15)
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !!card.player && card.player.canSeek && card.length > 0
            cursorShape: Qt.PointingHandCursor
            function seek(x) {
                card.player.position = Math.max(0, Math.min(1, x / width)) * card.length;
            }
            onPressed: mouse => seek(mouse.x)
            onPositionChanged: mouse => { if (pressed) seek(mouse.x); }
        }
    }

    Text {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 14
        anchors.bottomMargin: 10
        text: card.fmt(card.position)
        color: theme.textDim
        font.family: settings.font
        font.pixelSize: 12
    }
    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14
        anchors.bottomMargin: 10
        text: card.fmt(card.length)
        color: theme.textDim
        font.family: settings.font
        font.pixelSize: 12
    }
}
