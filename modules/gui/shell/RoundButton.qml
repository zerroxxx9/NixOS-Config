import QtQuick

// Round icon button. `confirm` makes the first click arm it (red) and the
// second, within 3 s, fire — so reboot/power-off can't happen by accident.
Rectangle {
    id: btn
    property string icon
    property bool confirm: false
    property bool armed: false
    signal activated

    implicitWidth: 36
    implicitHeight: 36
    radius: 18
    color: armed ? theme.error : (area.containsMouse ? Qt.lighter(theme.surfaceHigh, 1.25) : theme.surfaceHigh)
    Behavior on color { ColorAnimation { duration: 140 } }

    Text {
        anchors.centerIn: parent
        text: btn.icon
        color: btn.armed ? theme.surface : theme.text
        font.family: settings.font
        font.pixelSize: 15
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: btn.armed = false
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!btn.confirm || btn.armed) {
                btn.armed = false;
                btn.activated();
            } else {
                btn.armed = true;
                disarm.restart();
            }
        }
    }
}
