import QtQuick

// Round toolbar icon button; `active` shows it as toggled on.
Rectangle {
    id: btn
    property string icon
    property string tip
    property bool active: false
    signal activated

    implicitWidth: 32
    implicitHeight: 30
    radius: 8
    opacity: enabled ? 1 : 0.3
    color: active ? Qt.alpha(theme.accent, 0.26) : (area.containsMouse && enabled ? Qt.alpha(theme.text, 0.09) : "transparent")
    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
        anchors.centerIn: parent
        text: btn.icon
        color: btn.active ? theme.accent : theme.text
        font.family: settings.font
        font.pixelSize: 14
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.activated()
    }
}
