import QtQuick

// Icon + horizontal slider, value 0..1.
Item {
    id: row
    property string icon
    property real value: 0
    signal moved(real value)

    implicitHeight: 28
    implicitWidth: 150

    Text {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        text: row.icon
        color: theme.textDim
        font.family: settings.font
        font.pixelSize: 15
        width: 20
    }

    Item {
        id: track
        anchors.left: glyph.right
        anchors.leftMargin: 8
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: theme.surfaceHigh

            Rectangle {
                width: Math.max(parent.height, parent.width * row.value)
                height: parent.height
                radius: 3
                color: theme.accent
            }
        }
        Rectangle {
            x: Math.max(0, Math.min(track.width - width, track.width * row.value - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: theme.accent
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function setFrom(mouse) {
                row.moved(Math.max(0, Math.min(1, mouse.x / width)));
            }
            onPressed: mouse => setFrom(mouse)
            onPositionChanged: mouse => { if (pressed) setFrom(mouse); }
        }
    }
}
