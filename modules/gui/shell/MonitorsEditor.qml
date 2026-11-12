// Monitor arrangement editor for Settings → Display: drag monitors to set their
// order/position (snaps to edges), pick resolution, refresh rate, scale and
// rotation, then Apply. Applying goes through `monitors-layout save`, which
// applies the layout live and stores it so it survives login and reloads.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: ed
    Layout.fillWidth: true
    implicitHeight: col.implicitHeight

    property var layout: []
    property bool dirty: false
    property int selected: 0
    property string status: ""

    readonly property var scaleOptions: [1, 1.25, 1.5, 1.75, 2]
    readonly property var rotations: [
        { label: "Normal", value: 0 },
        { label: "90°", value: 1 },
        { label: "180°", value: 2 },
        { label: "270°", value: 3 }
    ]
    readonly property var current: layout.length > 0 ? layout[Math.min(selected, layout.length - 1)] : null

    function refresh() {
        if (!dirty)
            probe.running = true;
    }
    Component.onCompleted: probe.running = true

    // --- geometry helpers -------------------------------------------------

    function modeSize(m) {
        const r = /^(\d+)x(\d+)/.exec(m.mode);
        return r ? [parseInt(r[1]), parseInt(r[2])] : [m.w, m.h];
    }
    function logicalW(m) {
        const s = modeSize(m);
        return Math.round((m.transform % 2 === 1 ? s[1] : s[0]) / m.scale);
    }
    function logicalH(m) {
        const s = modeSize(m);
        return Math.round((m.transform % 2 === 1 ? s[0] : s[1]) / m.scale);
    }
    function overlaps(ax, ay, aw, ah, b) {
        return ax < b.x + logicalW(b) && ax + aw > b.x && ay < b.y + logicalH(b) && ay + ah > b.y;
    }
    function overlapsAny(idx, x, y) {
        const m = layout[idx];
        const w = logicalW(m), h = logicalH(m);
        return layout.some((o, i) => i !== idx && overlaps(x, y, w, h, o));
    }
    function anyOverlap() {
        return layout.some((a, i) => overlapsAny(i, a.x, a.y));
    }
    function normalise() {
        if (!layout.length) return;
        const mx = Math.min(...layout.map(m => m.x));
        const my = Math.min(...layout.map(m => m.y));
        for (const m of layout) { m.x = Math.round(m.x - mx); m.y = Math.round(m.y - my); }
    }
    // Lay monitors out side by side in their current left-to-right order.
    function pack() {
        const sorted = layout.slice().sort((a, b) => a.x - b.x);
        let cx = 0;
        for (const m of sorted) { m.x = cx; cx += logicalW(m); }
    }

    // Snap a dropped monitor to the nearest free edge of another monitor.
    function snapTo(idx, rx, ry) {
        const m = layout[idx];
        const w = logicalW(m), h = logicalH(m);
        const near = 80;
        let best = null, bestD = Infinity;

        function consider(x, y) {
            if (overlapsAny(idx, x, y)) return;
            const d = Math.hypot(x - rx, y - ry);
            if (d < bestD) { bestD = d; best = [x, y]; }
        }
        function alignY(o, oh, y) {
            for (const c of [o.y, o.y + oh - h, o.y + (oh - h) / 2])
                if (Math.abs(c - ry) < 60) return c;
            return y;
        }
        function alignX(o, ow, x) {
            for (const c of [o.x, o.x + ow - w, o.x + (ow - w) / 2])
                if (Math.abs(c - rx) < 60) return c;
            return x;
        }

        layout.forEach((o, i) => {
            if (i === idx) return;
            const ow = logicalW(o), oh = logicalH(o);
            const cy = alignY(o, oh, Math.max(o.y - h + near, Math.min(o.y + oh - near, ry)));
            consider(o.x + ow, cy);
            consider(o.x - w, cy);
            const cx = alignX(o, ow, Math.max(o.x - w + near, Math.min(o.x + ow - near, rx)));
            consider(cx, o.y + oh);
            consider(cx, o.y - h);
        });

        if (best) {
            m.x = Math.round(best[0]);
            m.y = Math.round(best[1]);
        }
        normalise();
    }

    function commit() {
        layout = layout.slice();
        dirty = true;
        status = "";
    }

    // --- edits ------------------------------------------------------------

    function setMode(mode) {
        current.mode = mode;
        const r = /@([\d.]+)/.exec(mode);
        current.hz = r ? parseFloat(r[1]) : current.hz;
        if (anyOverlap()) pack();
        normalise();
        commit();
    }
    function setScale(v) {
        current.scale = v;
        if (anyOverlap()) pack();
        normalise();
        commit();
    }
    function setTransform(v) {
        current.transform = v;
        if (anyOverlap()) pack();
        normalise();
        commit();
    }
    function swapOrder() {
        // Reverse the left-to-right order, tops aligned.
        const sorted = layout.slice().sort((a, b) => a.x - b.x).reverse();
        let cx = 0;
        for (const m of sorted) { m.x = cx; m.y = 0; cx += logicalW(m); }
        commit();
    }
    function reset() {
        dirty = false;
        status = "";
        probe.running = true;
    }
    function apply() {
        const out = {};
        for (const m of layout)
            out[m.name] = { mode: m.mode, x: m.x, y: m.y, scale: m.scale, transform: m.transform };
        saver.command = [settings.userBin + "/monitors-layout", "save", JSON.stringify(out)];
        saver.running = true;
        status = "Applying …";
    }

    function resolutions(m) {
        const seen = {};
        const out = [];
        for (const s of m.modes) {
            const res = s.split("@")[0];
            if (!seen[res]) { seen[res] = true; out.push(res); }
        }
        return out;
    }
    function refreshRates(m) {
        const res = m.mode.split("@")[0];
        return m.modes.filter(s => s.split("@")[0] === res);
    }
    function hzLabel(mode) {
        const hz = parseFloat(mode.split("@")[1]);
        return (Math.round(hz * 100) / 100).toString() + " Hz";
    }

    // --- data -------------------------------------------------------------

    Process {
        id: probe
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text).map(m => {
                        const modes = (m.availableModes || []).map(s => s.replace("Hz", ""));
                        let mode = modes.find(s => s.startsWith(m.width + "x" + m.height + "@")
                            && Math.abs(parseFloat(s.split("@")[1]) - m.refreshRate) < 0.1);
                        if (!mode) mode = m.width + "x" + m.height + "@" + m.refreshRate.toFixed(2);
                        return {
                            name: m.name,
                            desc: m.description || "",
                            w: m.width, h: m.height,
                            hz: m.refreshRate,
                            mode: mode,
                            modes: modes,
                            scale: Math.round(m.scale * 100) / 100,
                            transform: m.transform,
                            x: m.x, y: m.y
                        };
                    });
                    ed.layout = list;
                    ed.selected = Math.min(ed.selected, Math.max(0, list.length - 1));
                    ed.dirty = false;
                } catch (e) {
                    ed.status = "Could not read monitors";
                }
            }
        }
    }
    Process {
        id: saver
        onExited: code => {
            ed.status = code === 0 ? "Applied and saved" : "Could not apply layout";
            if (code === 0) ed.dirty = false;
            reprobe.restart();
        }
    }
    Timer { id: reprobe; interval: 1200; onTriggered: probe.running = true }

    // --- chips ------------------------------------------------------------

    component Chip: Rectangle {
        id: chip
        property string text
        property bool on: false
        signal clicked
        implicitWidth: chipText.implicitWidth + 24
        implicitHeight: 30
        radius: 8
        color: on ? Qt.alpha(theme.accent, 0.26) : (chipArea.containsMouse ? Qt.lighter(theme.surfaceHigh, 1.2) : theme.surfaceHigh)
        Behavior on color { ColorAnimation { duration: 120 } }
        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.text
            color: chip.on ? theme.accent : theme.text
            font.family: settings.font
            font.pixelSize: 12
        }
        MouseArea {
            id: chipArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }
    component SubLabel: Text {
        color: theme.textDim
        font.family: settings.font
        font.pixelSize: 11
        topPadding: 4
    }

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 8

        // ---- arrangement canvas
        Rectangle {
            id: canvas
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            radius: 12
            color: theme.surfaceHigh
            clip: true

            readonly property real minX: ed.layout.length ? Math.min(...ed.layout.map(m => m.x)) : 0
            readonly property real minY: ed.layout.length ? Math.min(...ed.layout.map(m => m.y)) : 0
            readonly property real maxX: ed.layout.length ? Math.max(...ed.layout.map(m => m.x + ed.logicalW(m))) : 1
            readonly property real maxY: ed.layout.length ? Math.max(...ed.layout.map(m => m.y + ed.logicalH(m))) : 1
            readonly property real padW: ed.layout.length ? Math.max(...ed.layout.map(m => ed.logicalW(m))) : 0
            readonly property real padH: ed.layout.length ? Math.max(...ed.layout.map(m => ed.logicalH(m))) : 0
            readonly property real f: Math.min(width / (maxX - minX + padW), height / (maxY - minY + padH))
            readonly property real originX: minX - (width / f - (maxX - minX)) / 2
            readonly property real originY: minY - (height / f - (maxY - minY)) / 2

            Repeater {
                model: ed.layout

                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool sel: ed.selected === index
                    x: (modelData.x - canvas.originX) * canvas.f
                    y: (modelData.y - canvas.originY) * canvas.f
                    width: ed.logicalW(modelData) * canvas.f
                    height: ed.logicalH(modelData) * canvas.f
                    radius: 8
                    color: sel ? Qt.alpha(theme.accent, 0.3) : Qt.alpha(theme.text, 0.1)
                    border.width: sel ? 2 : 1
                    border.color: sel ? theme.accent : theme.outline
                    z: drag.drag.active ? 2 : 0

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (index + 1) + "  ·  " + tile.modelData.name
                            color: theme.text
                            font.family: settings.font
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: ed.modeSize(tile.modelData).join("×") + " · " + tile.modelData.scale + "×"
                            color: theme.textDim
                            font.family: settings.font
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: drag
                        anchors.fill: parent
                        cursorShape: drag.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        drag.target: tile
                        drag.minimumX: 0
                        drag.maximumX: canvas.width - tile.width
                        drag.minimumY: 0
                        drag.maximumY: canvas.height - tile.height
                        onPressed: ed.selected = tile.index
                        onReleased: {
                            const rx = tile.x / canvas.f + canvas.originX;
                            const ry = tile.y / canvas.f + canvas.originY;
                            const i = tile.index;
                            Qt.callLater(() => {
                                ed.snapTo(i, rx, ry);
                                ed.commit();
                            });
                        }
                    }
                }
            }

            Text {
                visible: ed.layout.length === 0
                anchors.centerIn: parent
                text: "No monitors detected"
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 13
            }
        }

        Text {
            visible: ed.layout.length > 1
            Layout.fillWidth: true
            text: "Drag monitors to change their order and position. Tiles snap to each other's edges."
            color: theme.textDim
            font.family: settings.font
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }

        // ---- selected monitor settings
        ColumnLayout {
            visible: ed.current !== null
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: ed.current ? ed.current.name + (ed.current.desc ? "  ·  " + ed.current.desc : "") : ""
                color: theme.text
                font.family: settings.font
                font.pixelSize: 14
                elide: Text.ElideRight
                Layout.fillWidth: true
                topPadding: 4
            }

            SubLabel { text: "Resolution" }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ed.current ? ed.resolutions(ed.current) : []
                    Chip {
                        required property string modelData
                        text: modelData
                        on: ed.current.mode.split("@")[0] === modelData
                        onClicked: {
                            // Keep the refresh rate if the new resolution offers it, else take its best.
                            const opts = ed.current.modes.filter(s => s.split("@")[0] === modelData);
                            const same = opts.find(s => Math.abs(parseFloat(s.split("@")[1]) - ed.current.hz) < 0.5);
                            ed.setMode(same || opts[0]);
                        }
                    }
                }
            }

            SubLabel { text: "Refresh rate" }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ed.current ? ed.refreshRates(ed.current) : []
                    Chip {
                        required property string modelData
                        text: ed.hzLabel(modelData)
                        on: ed.current.mode === modelData
                        onClicked: ed.setMode(modelData)
                    }
                }
            }

            SubLabel { text: "Scale" }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ed.scaleOptions
                    Chip {
                        required property real modelData
                        text: modelData + "×"
                        on: ed.current && Math.abs(ed.current.scale - modelData) < 0.01
                        onClicked: ed.setScale(modelData)
                    }
                }
            }

            SubLabel { text: "Rotation" }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: ed.rotations
                    Chip {
                        required property var modelData
                        text: modelData.label
                        on: ed.current && ed.current.transform === modelData.value
                        onClicked: ed.setTransform(modelData.value)
                    }
                }
            }
        }

        // ---- actions
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 8

            Text {
                text: ed.status
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 12
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Chip {
                visible: ed.layout.length > 1
                text: "Swap order"
                onClicked: ed.swapOrder()
            }
            Chip {
                visible: ed.dirty
                text: "Reset"
                onClicked: ed.reset()
            }
            Rectangle {
                implicitWidth: 88
                implicitHeight: 30
                radius: 8
                opacity: ed.dirty ? 1 : 0.4
                color: theme.accent
                Text {
                    anchors.centerIn: parent
                    text: "Apply"
                    color: theme.accentText
                    font.family: settings.font
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: ed.dirty
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ed.apply()
                }
            }
        }
    }
}
