// One lyric line, typeset as words of different sizes that pop in on cue.
import QtQuick
import QtQuick.Effects
import "typeset.js" as Typeset

Item {
    id: line

    required property var lineData
    required property real nextTime
    required property real posMs
    required property var cfg
    required property string capsFamily
    required property string scriptFamily
    required property real maxW
    property color textColor: cfg.color

    readonly property var toks: Typeset.tokens(lineData.text)
    readonly property var wordStyles: Typeset.styles(toks, cfg)
    readonly property var wordTimes: cfg.wordByWord
        ? Typeset.times(lineData, toks, nextTime, cfg.wordSpread / 100)
        : toks.map(() => lineData.time)

    // natural word widths, filled in once the probes exist
    property var widths: []
    readonly property var rowIndexes: widths.length === toks.length ? Typeset.rows(widths, cfg.wordGap, maxW) : []

    // flips on one frame after creation so words already sung (after a seek or
    // a restart) appear immediately instead of animating in
    property bool animate: false

    width: maxW
    implicitHeight: content.implicitHeight
    height: implicitHeight

    function display(i) {
        return !wordStyles[i].script && cfg.uppercase ? toks[i].toUpperCase() : toks[i];
    }

    function family(i) {
        return wordStyles[i].script ? scriptFamily : capsFamily;
    }

    // words wider than the column are scaled down to fit
    function scaleFor(i) {
        const w = widths[i] ?? 0;
        return w > maxW ? maxW / w : 1;
    }

    function measure() {
        const w = [];
        for (let i = 0; i < toks.length; i++) {
            const probe = probes.itemAt(i);
            if (!probe)
                return;
            w.push(probe.implicitWidth);
        }
        widths = w;
    }

    Component.onCompleted: {
        measure();
        Qt.callLater(() => line.animate = true);
    }

    Repeater {
        id: probes
        model: line.toks.length
        delegate: Text {
            required property int index
            visible: false
            text: line.display(index)
            font.family: line.family(index)
            font.pixelSize: Math.round(line.wordStyles[index].size)
            onImplicitWidthChanged: line.measure()
        }
    }

    Column {
        id: content
        width: line.width
        layer.enabled: line.cfg.shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#99000000"
            shadowBlur: 0.7
            shadowVerticalOffset: 3
        }

        Repeater {
            model: line.rowIndexes
            delegate: Row {
                id: row
                required property var modelData
                spacing: line.cfg.wordGap
                x: line.cfg.rowAlign === "end" ? content.width - width
                    : line.cfg.rowAlign === "center" ? (content.width - width) / 2 : 0

                Repeater {
                    model: row.modelData
                    delegate: Text {
                        id: word
                        required property int modelData

                        readonly property bool shown: line.posMs >= line.wordTimes[modelData] - 30
                        readonly property int h: Typeset.hash(line.toks[modelData] + modelData)
                        readonly property real jitterY: line.cfg.wobble ? (h % 9) - 4 : 0
                        property real lift: shown ? jitterY : jitterY + 18

                        text: line.display(modelData)
                        color: line.textColor
                        font.family: line.family(modelData)
                        font.pixelSize: Math.round(line.wordStyles[modelData].size * line.scaleFor(modelData))
                        rotation: line.cfg.wobble ? ((h >> 3) % 7 - 3) * 0.7 : 0
                        transformOrigin: Item.Center
                        opacity: shown ? 1 : 0
                        scale: shown ? 1 : 0.8
                        transform: Translate { y: word.lift }

                        Behavior on opacity {
                            enabled: line.animate
                            NumberAnimation { duration: Math.round(line.cfg.wordInMs * 0.6); easing.type: Easing.OutQuad }
                        }
                        Behavior on scale {
                            enabled: line.animate
                            NumberAnimation { duration: line.cfg.wordInMs; easing.type: Easing.OutBack }
                        }
                        Behavior on lift {
                            enabled: line.animate
                            NumberAnimation { duration: line.cfg.wordInMs; easing.type: Easing.OutBack }
                        }
                    }
                }
            }
        }
    }
}
