import QtQuick

// Toggle tile: filled with the accent while on.
Rectangle {
    id: tile
    property string icon
    property string title
    property string subtitle
    property bool on: false
    signal clicked

    implicitHeight: 56
    radius: 16
    color: on ? theme.accent : (hover.containsMouse ? Qt.lighter(theme.surfaceHigh, 1.15) : theme.surfaceHigh)
    Behavior on color { ColorAnimation { duration: 140 } }

    readonly property color fg: on ? theme.accentText : theme.text
    readonly property color fgDim: on ? Qt.rgba(fg.r, fg.g, fg.b, 0.7) : theme.textDim

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 16
        spacing: 14

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: tile.icon
            color: tile.fg
            font.family: settings.font
            font.pixelSize: 18
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                text: tile.title
                color: tile.fg
                font.family: settings.font
                font.pixelSize: 14
                font.weight: Font.Medium
            }
            Text {
                text: tile.subtitle
                color: tile.fgDim
                font.family: settings.font
                font.pixelSize: 11
            }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.clicked()
    }
}
