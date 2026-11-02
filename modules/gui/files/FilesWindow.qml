// The file manager window: places sidebar, toolbar, grid/list view, preview
// pane, context menu and a small prompt for rename / new folder.
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: win

    property string start: "/"
    property string cwd: start
    property var backStack: []
    property var fwdStack: []

    // Selection: path -> true. Reassigned on every change so bindings update.
    property var sel: ({})
    property int cur: -1
    property int anchorIdx: -1

    property bool showHidden: false
    property bool listMode: false
    property bool previewOn: true
    property string clipMode: ""   // "copy" | "cut" | ""
    property var clipPaths: []

    readonly property var selPaths: Object.keys(sel)
    readonly property string curPath: cur >= 0 && cur < fm.count ? fm.get(cur, "filePath") : ""
    readonly property string previewPath: selPaths.length === 1 ? selPaths[0] : ""

    title: "Files"
    implicitWidth: 1100
    implicitHeight: 700
    minimumSize: Qt.size(720, 460)
    color: theme.surface

    // ---------------------------------------------------------------- helpers

    readonly property var places: [
        { header: "Favourites" },
        { name: "Home", icon: "", path: settings.home },
        { name: "Documents", icon: "", path: settings.home + "/Documents" },
        { name: "Downloads", icon: "", path: settings.home + "/Downloads" },
        { name: "Pictures", icon: "", path: settings.home + "/Pictures" },
        { name: "Videos", icon: "", path: settings.home + "/Videos" },
        { name: "Music", icon: "", path: settings.home + "/Music" },
        { name: "Dotfiles", icon: "", path: settings.home + "/.dotfiles" },
        { header: "Locations" },
        { name: "Trash", icon: "", path: settings.trashDir },
        { name: "System", icon: "", path: "/" }
    ]

    function baseName(p) {
        const parts = p.split("/").filter(x => x !== "");
        return parts.length ? parts[parts.length - 1] : "/";
    }
    function parentOf(p) {
        const parts = p.split("/").filter(x => x !== "");
        parts.pop();
        return "/" + parts.join("/");
    }
    function toUrl(p) {
        return "file://" + p.split("/").map(encodeURIComponent).join("/");
    }
    function humanSize(n) {
        const u = ["B", "KB", "MB", "GB", "TB"];
        let i = 0;
        while (n >= 1024 && i < u.length - 1) { n /= 1024; i++; }
        return (i === 0 ? n : n.toFixed(n < 10 ? 1 : 0)) + " " + u[i];
    }
    function humanDate(d) {
        return Qt.formatDateTime(d, "d MMM yyyy, HH:mm");
    }

    readonly property var imageExt: ["png", "jpg", "jpeg", "gif", "webp", "bmp", "svg", "avif", "ico", "tif", "tiff"]
    readonly property var videoExt: ["mp4", "mkv", "webm", "mov", "avi", "flv", "wmv", "m4v"]
    readonly property var audioExt: ["mp3", "flac", "ogg", "opus", "wav", "m4a", "aac"]
    readonly property var archiveExt: ["zip", "tar", "gz", "xz", "bz2", "zst", "7z", "rar", "tgz"]
    readonly property var textExt: ["txt", "md", "nix", "qml", "js", "ts", "tsx", "jsx", "json", "toml", "yaml", "yml", "conf", "ini", "sh", "fish", "bash", "py", "rs", "go", "c", "h", "cpp", "hpp", "css", "html", "xml", "lua", "log", "csv", "lock", "service", "desktop", "rasi", "java", "kt", "sql", "env", "gitignore", "cfg"]

    function kindOf(isDir, suffix) {
        if (isDir) return "dir";
        const s = suffix.toLowerCase();
        if (imageExt.includes(s)) return "image";
        if (videoExt.includes(s)) return "video";
        if (audioExt.includes(s)) return "audio";
        if (archiveExt.includes(s)) return "archive";
        if (s === "pdf") return "pdf";
        if (textExt.includes(s)) return "text";
        return "file";
    }
    function iconFor(kind) {
        switch (kind) {
        case "dir": return "";
        case "image": return "";
        case "video": return "";
        case "audio": return "";
        case "archive": return "";
        case "pdf": return "";
        case "text": return "";
        default: return "";
        }
    }
    function kindLabel(kind) {
        return { dir: "Folder", image: "Image", video: "Video", audio: "Audio", archive: "Archive", pdf: "PDF document", text: "Text / code" }[kind] || "File";
    }

    // ------------------------------------------------------------- navigation

    function go(path, pushHistory) {
        let p = path.trim();
        if (p === "") return;
        if (p.startsWith("~")) p = settings.home + p.slice(1);
        if (!p.startsWith("/")) p = cwd + "/" + p;
        const parts = [];
        for (const seg of p.split("/")) {
            if (seg === "" || seg === ".") continue;
            if (seg === "..") parts.pop(); else parts.push(seg);
        }
        p = "/" + parts.join("/");
        if (p === cwd) return;
        if (pushHistory !== false) {
            backStack = backStack.concat([cwd]);
            fwdStack = [];
        }
        cwd = p;
        search.text = "";
        clearSel();
    }
    function goBack() {
        if (!backStack.length) return;
        const p = backStack[backStack.length - 1];
        backStack = backStack.slice(0, -1);
        fwdStack = fwdStack.concat([cwd]);
        go(p, false);
    }
    function goForward() {
        if (!fwdStack.length) return;
        const p = fwdStack[fwdStack.length - 1];
        fwdStack = fwdStack.slice(0, -1);
        backStack = backStack.concat([cwd]);
        go(p, false);
    }
    function goUp() { go(parentOf(cwd)); }

    function openIndex(i) {
        if (i < 0 || i >= fm.count) return;
        const p = fm.get(i, "filePath");
        if (fm.get(i, "fileIsDir")) go(p);
        else run(["xdg-open", p]);
    }

    // -------------------------------------------------------------- selection

    function clearSel() { sel = ({}); cur = -1; anchorIdx = -1; }
    function selectOnly(i) {
        if (i < 0 || i >= fm.count) { clearSel(); return; }
        const s = {};
        s[fm.get(i, "filePath")] = true;
        sel = s;
        cur = i;
        anchorIdx = i;
        view.positionViewAtIndex(i, GridView.Contain);
    }
    function toggleSel(i) {
        const p = fm.get(i, "filePath");
        const s = Object.assign({}, sel);
        if (s[p]) delete s[p]; else s[p] = true;
        sel = s;
        cur = i;
        anchorIdx = i;
    }
    function rangeSel(i) {
        if (anchorIdx < 0) { selectOnly(i); return; }
        const s = {};
        for (let k = Math.min(anchorIdx, i); k <= Math.max(anchorIdx, i); k++)
            s[fm.get(k, "filePath")] = true;
        sel = s;
        cur = i;
        view.positionViewAtIndex(i, GridView.Contain);
    }
    function selectAll() {
        const s = {};
        for (let k = 0; k < fm.count; k++) s[fm.get(k, "filePath")] = true;
        sel = s;
    }
    function move(delta, extend) {
        if (fm.count === 0) return;
        const next = cur < 0 ? 0 : Math.max(0, Math.min(fm.count - 1, cur + delta));
        if (extend) rangeSel(next); else selectOnly(next);
    }

    // ------------------------------------------------------------- operations

    function run(cmd) {
        const p = runnerComp.createObject(win, { command: cmd });
        p.running = true;
    }
    Component {
        id: runnerComp
        Process {
            onExited: destroy()
        }
    }

    function copySel(cut) {
        if (!selPaths.length) return;
        clipPaths = selPaths.slice();
        clipMode = cut ? "cut" : "copy";
    }
    function paste() {
        if (!clipPaths.length) return;
        run(["files-op", clipMode === "cut" ? "move" : "copy", cwd].concat(clipPaths));
        if (clipMode === "cut") { clipPaths = []; clipMode = ""; }
    }
    function trashSel() {
        if (!selPaths.length) return;
        const paths = selPaths.slice();
        clearSel();
        run(["files-op", "trash"].concat(paths));
    }
    function askRename() {
        if (selPaths.length !== 1) return;
        prompt.open("Rename", baseName(selPaths[0]), "Rename", name => {
            if (name !== "" && name !== baseName(selPaths[0]))
                run(["files-op", "rename", selPaths[0], parentOf(selPaths[0]) + "/" + name]);
        });
    }
    function askNewFolder() {
        prompt.open("New folder", "", "Create", name => {
            if (name !== "") run(["files-op", "mkdir", cwd + "/" + name]);
        });
    }

    // ------------------------------------------------------------------ model

    FolderListModel {
        id: fm
        folder: win.toUrl(win.cwd)
        showHidden: win.showHidden
        showDirsFirst: true
        showDotAndDotDot: false
        caseSensitive: false
        sortField: FolderListModel.Name
        nameFilters: search.text === "" ? ["*"] : ["*" + search.text + "*"]
    }

    // Folder / selection summary for the status line.
    readonly property string statusText: {
        const n = fm.count;
        const sc = selPaths.length;
        if (sc === 0) return n + (n === 1 ? " item" : " items");
        let total = 0;
        let files = 0;
        for (let k = 0; k < n; k++) {
            if (sel[fm.get(k, "filePath")] && !fm.get(k, "fileIsDir")) { total += fm.get(k, "fileSize"); files++; }
        }
        return sc + " selected" + (files ? " · " + humanSize(total) : "") + " of " + n;
    }

    // ----------------------------------------------------------------- layout

    Item {
        id: root
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            const shift = event.modifiers & Qt.ShiftModifier;
            const alt = event.modifiers & Qt.AltModifier;
            const cols = win.listMode ? 1 : Math.max(1, Math.floor(view.width / view.cellWidth));
            event.accepted = true;
            if (ctrl && event.key === Qt.Key_A) win.selectAll();
            else if (ctrl && event.key === Qt.Key_C) win.copySel(false);
            else if (ctrl && event.key === Qt.Key_X) win.copySel(true);
            else if (ctrl && event.key === Qt.Key_V) win.paste();
            else if (ctrl && event.key === Qt.Key_H) win.showHidden = !win.showHidden;
            else if (ctrl && event.key === Qt.Key_L) { pathField.forceActiveFocus(); pathField.selectAll(); }
            else if (ctrl && event.key === Qt.Key_F) search.forceActiveFocus();
            else if (ctrl && shift && event.key === Qt.Key_N) win.askNewFolder();
            else if (ctrl && event.key === Qt.Key_W) win.close();
            else if (alt && event.key === Qt.Key_Left) win.goBack();
            else if (alt && event.key === Qt.Key_Right) win.goForward();
            else if (alt && event.key === Qt.Key_Up) win.goUp();
            else if (event.key === Qt.Key_Backspace) win.goUp();
            else if (event.key === Qt.Key_Delete) win.trashSel();
            else if (event.key === Qt.Key_F2) win.askRename();
            else if (event.key === Qt.Key_Space) { if (win.cur >= 0) win.toggleSel(win.cur); }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (win.selPaths.length === 1) win.openIndex(win.cur);
                else if (win.selPaths.length > 1) for (let k = 0; k < fm.count; k++) if (win.sel[fm.get(k, "filePath")] && !fm.get(k, "fileIsDir")) win.run(["xdg-open", fm.get(k, "filePath")]);
            }
            else if (event.key === Qt.Key_Left) win.move(-1, shift);
            else if (event.key === Qt.Key_Right) win.move(1, shift);
            else if (event.key === Qt.Key_Up) win.move(-cols, shift);
            else if (event.key === Qt.Key_Down) win.move(cols, shift);
            else if (event.key === Qt.Key_Home) win.move(-fm.count, shift);
            else if (event.key === Qt.Key_End) win.move(fm.count, shift);
            else if (event.key === Qt.Key_Escape) { menu.close(); win.clearSel(); }
            else if (!ctrl && !alt && event.text.length === 1 && event.text >= " ") {
                search.forceActiveFocus();
                search.text = event.text;
                search.cursorPosition = search.text.length;
            }
            else event.accepted = false;
        }

        // ---- sidebar
        Rectangle {
            id: side
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 200
            color: theme.surfaceHigh

            Column {
                anchors { fill: parent; leftMargin: 10; rightMargin: 10; topMargin: 14 }
                spacing: 1

                Repeater {
                    model: win.places

                    Item {
                        id: row
                        required property var modelData
                        readonly property bool isHeader: modelData.header !== undefined
                        readonly property bool active: !isHeader && win.cwd === modelData.path
                        width: parent.width
                        height: isHeader ? 32 : 30

                        Text {
                            visible: row.isHeader
                            anchors { left: parent.left; leftMargin: 10; bottom: parent.bottom; bottomMargin: 4 }
                            text: row.modelData.header ?? ""
                            color: theme.textDim
                            font.family: settings.font
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            visible: !row.isHeader
                            anchors.fill: parent
                            radius: 8
                            color: row.active ? Qt.alpha(theme.accent, 0.26)
                                 : (hov.containsMouse ? Qt.alpha(theme.text, 0.07) : "transparent")
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Row {
                                anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
                                spacing: 10
                                Text {
                                    width: 18
                                    horizontalAlignment: Text.AlignHCenter
                                    text: row.modelData.icon ?? ""
                                    color: theme.accent
                                    font.family: settings.font
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: row.modelData.name ?? ""
                                    color: theme.text
                                    font.family: settings.font
                                    font.pixelSize: 13
                                }
                            }
                            MouseArea {
                                id: hov
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: win.go(row.modelData.path)
                            }
                        }
                    }
                }
            }
        }

        // ---- toolbar
        Item {
            id: toolbar
            anchors { left: side.right; right: parent.right; top: parent.top; margins: 12 }
            height: 40

            Row {
                id: navButtons
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                ToolButton { icon: "\uf053"; enabled: win.backStack.length > 0; onActivated: win.goBack() }
                ToolButton { icon: "\uf054"; enabled: win.fwdStack.length > 0; onActivated: win.goForward() }
                ToolButton { icon: "\uf077"; enabled: win.cwd !== "/"; onActivated: win.goUp() }
            }

            Row {
                id: actionButtons
                spacing: 6
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                ToolButton { icon: ""; tip: "New folder"; onActivated: win.askNewFolder() }
                ToolButton { icon: win.listMode ? "" : ""; tip: "Grid / list"; onActivated: win.listMode = !win.listMode }
                ToolButton { icon: win.showHidden ? "" : ""; tip: "Hidden files"; onActivated: win.showHidden = !win.showHidden }
                ToolButton { icon: ""; tip: "Preview pane"; active: win.previewOn; onActivated: win.previewOn = !win.previewOn }
            }

            Rectangle {
                id: searchBox
                anchors { right: actionButtons.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                width: 190
                height: 30
                radius: 9
                color: Qt.alpha(theme.text, 0.07)
                border.width: search.activeFocus ? 1 : 0
                border.color: theme.accent

                Text {
                    anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                    text: ""
                    color: theme.textDim
                    font.family: settings.font
                    font.pixelSize: 13
                }
                TextInput {
                    id: search
                    anchors { fill: parent; leftMargin: 36; rightMargin: 12 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: theme.text
                    selectionColor: theme.accent
                    selectedTextColor: theme.accentText
                    font.family: settings.font
                    font.pixelSize: 13
                    clip: true
                    Keys.onEscapePressed: { text = ""; root.forceActiveFocus(); }
                    Keys.onReturnPressed: root.forceActiveFocus()
                    Text {
                        visible: search.text === "" && !search.activeFocus
                        text: "Filter files"
                        color: theme.textDim
                        font: search.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                anchors { left: navButtons.right; leftMargin: 10; right: searchBox.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                height: 30
                radius: 9
                color: pathField.activeFocus ? Qt.alpha(theme.text, 0.07) : "transparent"
                border.width: pathField.activeFocus ? 1 : 0
                border.color: theme.accent

                // Shows the folder name like a title; click (or Ctrl+L) to edit the full path.
                TextInput {
                    id: pathField
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: theme.text
                    selectionColor: theme.accent
                    selectedTextColor: theme.accentText
                    font.family: settings.font
                    font.pixelSize: activeFocus ? 13 : 16
                    font.weight: activeFocus ? Font.Normal : Font.DemiBold
                    clip: true
                    text: win.baseName(win.cwd)
                    onAccepted: { win.go(text); root.forceActiveFocus(); }
                    Keys.onEscapePressed: root.forceActiveFocus()
                    onActiveFocusChanged: {
                        text = activeFocus ? win.cwd : win.baseName(win.cwd);
                        if (activeFocus) selectAll();
                    }
                    Connections {
                        target: win
                        function onCwdChanged() { if (!pathField.activeFocus) pathField.text = win.baseName(win.cwd); }
                    }
                }
            }
        }

        // ---- file view
        Item {
            id: content
            anchors {
                left: side.right; top: toolbar.bottom; bottom: statusBar.top
                right: previewPane.visible ? previewPane.left : parent.right
                margins: 12; topMargin: 8
            }

            GridView {
                id: view
                anchors.fill: parent
                clip: true
                model: fm
                cellWidth: win.listMode ? width : 124
                cellHeight: win.listMode ? 38 : 136
                boundsBehavior: Flickable.StopAtBounds
                currentIndex: win.cur

                delegate: Item {
                    id: cell
                    required property int index
                    required property string fileName
                    required property string filePath
                    required property string fileSuffix
                    required property bool fileIsDir
                    required property var fileSize
                    required property var fileModified
                    readonly property string kind: win.kindOf(fileIsDir, fileSuffix)
                    readonly property bool selected: win.sel[filePath] === true
                    readonly property bool cut: win.clipMode === "cut" && win.clipPaths.includes(filePath)

                    width: view.cellWidth
                    height: view.cellHeight
                    opacity: cut ? 0.45 : 1

                    // list: full-row highlight
                    Rectangle {
                        visible: win.listMode
                        anchors { fill: parent; leftMargin: 4; rightMargin: 4; topMargin: 2; bottomMargin: 2 }
                        radius: 8
                        color: cell.selected ? Qt.alpha(theme.accent, 0.26)
                             : (cellHover.containsMouse ? Qt.alpha(theme.text, 0.06) : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    // grid: soft plate behind the icon, accent pill behind the name
                    Rectangle {
                        visible: !win.listMode
                        x: (parent.width - 88) / 2
                        y: 6
                        width: 88
                        height: 84
                        radius: 12
                        color: cell.selected ? Qt.alpha(theme.text, 0.14)
                             : (cellHover.containsMouse ? Qt.alpha(theme.text, 0.06) : "transparent")
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    // grid layout
                    Column {
                        visible: !win.listMode
                        anchors { fill: parent; margins: 8 }
                        spacing: 6

                        Item {
                            width: parent.width
                            height: 72

                            Image {
                                id: thumb
                                anchors.centerIn: parent
                                visible: cell.kind === "image" && status === Image.Ready
                                width: 72; height: 72
                                source: cell.kind === "image" && !win.listMode ? win.toUrl(cell.filePath) : ""
                                sourceSize: Qt.size(160, 160)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }
                            Text {
                                anchors.centerIn: parent
                                visible: !thumb.visible
                                text: win.iconFor(cell.kind)
                                color: cell.fileIsDir ? theme.accent : theme.textDim
                                font.family: settings.font
                                font.pixelSize: cell.fileIsDir ? 54 : 44
                            }
                        }
                        Item {
                            width: parent.width
                            height: nameText.implicitHeight + 4

                            Rectangle {
                                anchors.centerIn: nameText
                                width: nameText.contentWidth + 12
                                height: nameText.contentHeight + 4
                                radius: 6
                                color: theme.accent
                                visible: cell.selected
                            }
                            Text {
                                id: nameText
                                width: parent.width - 4
                                anchors.centerIn: parent
                                text: cell.fileName
                                color: cell.selected ? theme.accentText : theme.text
                                font.family: settings.font
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WrapAnywhere
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }

                    // list layout
                    Item {
                        visible: win.listMode
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }

                        Text {
                            id: listIcon
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24
                            horizontalAlignment: Text.AlignHCenter
                            text: win.iconFor(cell.kind)
                            color: cell.fileIsDir ? theme.accent : theme.textDim
                            font.family: settings.font
                            font.pixelSize: 17
                        }
                        Text {
                            anchors { left: listIcon.right; leftMargin: 12; right: listSize.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            text: cell.fileName
                            color: theme.text
                            font.family: settings.font
                            font.pixelSize: 13
                            elide: Text.ElideMiddle
                        }
                        Text {
                            id: listSize
                            anchors { right: listDate.left; rightMargin: 16; verticalCenter: parent.verticalCenter }
                            width: 70
                            horizontalAlignment: Text.AlignRight
                            text: cell.fileIsDir ? "" : win.humanSize(cell.fileSize)
                            color: theme.textDim
                            font.family: settings.font
                            font.pixelSize: 12
                        }
                        Text {
                            id: listDate
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: 130
                            horizontalAlignment: Text.AlignRight
                            text: win.humanDate(cell.fileModified)
                            color: theme.textDim
                            font.family: settings.font
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: cellHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onPressed: mouse => {
                            root.forceActiveFocus();
                            if (mouse.button === Qt.RightButton) {
                                if (!cell.selected) win.selectOnly(cell.index);
                                menu.openAt(mapToItem(root, mouse.x, mouse.y), true);
                            } else if (mouse.modifiers & Qt.ControlModifier) win.toggleSel(cell.index);
                            else if (mouse.modifiers & Qt.ShiftModifier) win.rangeSel(cell.index);
                            else win.selectOnly(cell.index);
                        }
                        onDoubleClicked: mouse => {
                            if (mouse.button === Qt.LeftButton && !(mouse.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)))
                                win.openIndex(cell.index);
                        }
                    }
                }

                // Clicks on empty space: deselect / background menu.
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onPressed: mouse => {
                        root.forceActiveFocus();
                        win.clearSel();
                        if (mouse.button === Qt.RightButton)
                            menu.openAt(mapToItem(root, mouse.x, mouse.y), false);
                    }
                }

                // Thin scroll indicator.
                Rectangle {
                    visible: view.contentHeight > view.height
                    anchors.right: parent.right
                    width: 4
                    radius: 2
                    color: theme.outline
                    y: view.height * (view.contentY / view.contentHeight)
                    height: Math.max(24, view.height * view.height / view.contentHeight)
                }
            }

            Text {
                visible: fm.count === 0
                anchors.centerIn: parent
                text: search.text !== "" ? "No matches" : "This folder is empty"
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 14
            }
        }

        // ---- preview pane
        Rectangle {
            id: previewPane
            visible: win.previewOn
            anchors { right: parent.right; top: toolbar.bottom; bottom: statusBar.top; topMargin: 8; rightMargin: 12 }
            width: 260
            radius: 14
            color: theme.surfaceHigh

            property string kind: ""
            property string name: ""
            property var size: 0
            property var modified: new Date()
            property bool isDir: false
            property string snippet: ""
            property string videoThumb: ""
            property var dirEntries: []
            property int dirTotal: 0
            property string dirFor: ""

            function refresh() {
                snippet = "";
                videoThumb = "";
                dirEntries = [];
                dirTotal = 0;
                const p = win.previewPath;
                if (p === "") { kind = ""; return; }
                const idx = fm.indexOf(win.toUrl(p));
                if (idx < 0) { kind = ""; return; }
                name = fm.get(idx, "fileName");
                isDir = fm.get(idx, "fileIsDir");
                size = fm.get(idx, "fileSize");
                modified = fm.get(idx, "fileModified");
                kind = win.kindOf(isDir, fm.get(idx, "fileSuffix"));
                if (kind === "dir") {
                    dirFor = p;
                    dirProc.running = false;
                    dirProc.command = ["find", p, "-mindepth", "1", "-maxdepth", "1", "-printf", "%y\t%f\n"];
                    dirProc.running = true;
                } else if (kind === "text" && size < 50 * 1024 * 1024) {
                    textProc.command = ["head", "-c", "4096", "--", p];
                    textProc.running = true;
                } else if (kind === "video") {
                    thumbProc.command = ["files-op", "thumb", p];
                    thumbProc.running = true;
                }
            }
            Connections {
                target: win
                function onPreviewPathChanged() { previewPane.refresh(); }
            }

            Process {
                id: textProc
                stdout: StdioCollector {
                    onStreamFinished: if (win.previewPath !== "") previewPane.snippet = text
                }
            }
            Process {
                id: dirProc
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (previewPane.dirFor !== win.previewPath) return;
                        const all = text.split("\n").filter(l => l !== "").map(l => {
                            const t = l.indexOf("\t");
                            return { dir: l.slice(0, t) === "d", name: l.slice(t + 1) };
                        }).filter(e => win.showHidden || !e.name.startsWith("."));
                        all.sort((a, b) => (b.dir - a.dir) || a.name.localeCompare(b.name));
                        previewPane.dirTotal = all.length;
                        previewPane.dirEntries = all.slice(0, 200);
                    }
                }
            }
            Process {
                id: thumbProc
                stdout: StdioCollector {
                    onStreamFinished: if (text.trim() !== "") previewPane.videoThumb = text.trim()
                }
            }

            Text {
                visible: previewPane.kind === ""
                anchors.centerIn: parent
                width: parent.width - 40
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: win.selPaths.length > 1 ? win.selPaths.length + " items selected" : "Select a file to preview it"
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 13
            }

            Column {
                visible: previewPane.kind !== ""
                anchors { fill: parent; margins: 16 }
                spacing: 12

                Rectangle {
                    width: parent.width
                    height: previewPane.kind === "dir" ? 230 : 170
                    radius: 14
                    color: theme.surface
                    clip: true

                    Image {
                        id: bigImage
                        anchors.fill: parent
                        visible: status === Image.Ready
                        source: previewPane.kind === "image" ? win.toUrl(win.previewPath)
                              : (previewPane.kind === "video" && previewPane.videoThumb !== "" ? "file://" + previewPane.videoThumb : "")
                        sourceSize: Qt.size(520, 520)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }
                    Text {
                        anchors { fill: parent; margins: 10 }
                        visible: previewPane.kind === "text" && previewPane.snippet !== ""
                        text: previewPane.snippet
                        color: theme.text
                        font.family: "monospace"
                        font.pixelSize: 9
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        clip: true
                    }
                    ListView {
                        id: dirList
                        anchors { fill: parent; margins: 6 }
                        visible: previewPane.kind === "dir" && previewPane.dirEntries.length > 0
                        clip: true
                        model: previewPane.dirEntries
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Row {
                            required property var modelData
                            height: 24
                            spacing: 8
                            leftPadding: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.dir ? "\uf07b" : "\uf15b"
                                color: modelData.dir ? theme.accent : theme.textDim
                                font.family: settings.font
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                width: dirList.width - 40
                                text: modelData.name
                                color: theme.text
                                font.family: settings.font
                                font.pixelSize: 12
                                elide: Text.ElideMiddle
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: previewPane.kind === "dir" && previewPane.dirEntries.length === 0
                        text: "Empty folder"
                        color: theme.textDim
                        font.family: settings.font
                        font.pixelSize: 12
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: previewPane.kind !== "dir" && !bigImage.visible && !(previewPane.kind === "text" && previewPane.snippet !== "")
                        text: win.iconFor(previewPane.kind)
                        color: previewPane.isDir ? theme.accent : theme.textDim
                        font.family: settings.font
                        font.pixelSize: 56
                    }
                }

                Text {
                    width: parent.width
                    text: previewPane.name
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                Repeater {
                    model: [
                        { k: "Type", v: win.kindLabel(previewPane.kind) },
                        { k: "Items", v: previewPane.isDir ? String(previewPane.dirTotal) : "" },
                        { k: "Size", v: previewPane.isDir ? "" : win.humanSize(previewPane.size) },
                        { k: "Modified", v: win.humanDate(previewPane.modified) }
                    ].filter(r => r.v !== "")

                    Row {
                        required property var modelData
                        width: parent.width
                        spacing: 8
                        Text {
                            width: 62
                            text: modelData.k
                            color: theme.textDim
                            font.family: settings.font
                            font.pixelSize: 12
                        }
                        Text {
                            width: parent.width - 70
                            text: modelData.v
                            color: theme.text
                            font.family: settings.font
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }

        // ---- status bar
        Rectangle {
            id: statusBar
            anchors { left: side.right; right: parent.right; bottom: parent.bottom }
            height: 30
            color: "transparent"

            Text {
                anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                text: win.statusText
                color: theme.textDim
                font.family: settings.font
                font.pixelSize: 12
            }
            Text {
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                visible: win.clipPaths.length > 0
                text: (win.clipMode === "cut" ? "Cut " : "Copied ") + win.clipPaths.length + (win.clipPaths.length === 1 ? " item" : " items")
                color: theme.accent
                font.family: settings.font
                font.pixelSize: 12
            }
        }

        // ---- context menu
        Item {
            id: menu
            anchors.fill: parent
            visible: false
            z: 10
            property bool onItem: false
            property point at: Qt.point(0, 0)

            function openAt(pt, item) {
                onItem = item;
                at = pt;
                visible = true;
            }
            function close() { visible = false; }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onPressed: menu.close()
            }

            Rectangle {
                x: Math.min(menu.at.x, root.width - width - 8)
                y: Math.min(menu.at.y, root.height - height - 8)
                width: 200
                height: menuCol.implicitHeight + 12
                radius: 18
                color: theme.surfaceHigh
                border.width: 1
                border.color: theme.outline

                Column {
                    id: menuCol
                    anchors { fill: parent; margins: 6 }

                    Repeater {
                        model: menu.onItem
                            ? [
                                { label: "Open", act: "open", on: true },
                                { label: "Cut", act: "cut", on: true },
                                { label: "Copy", act: "copy", on: true },
                                { label: "Paste", act: "paste", on: win.clipPaths.length > 0 },
                                { label: "Rename", act: "rename", on: win.selPaths.length === 1 },
                                { label: "Move to trash", act: "trash", on: true }
                            ]
                            : [
                                { label: "New folder", act: "mkdir", on: true },
                                { label: "Paste", act: "paste", on: win.clipPaths.length > 0 },
                                { label: "Select all", act: "all", on: true }
                            ]

                        Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 32
                            radius: 16
                            opacity: modelData.on ? 1 : 0.4
                            color: itemHover.containsMouse && modelData.on ? Qt.lighter(theme.surfaceHigh, 1.3) : "transparent"

                            Text {
                                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                                text: modelData.label
                                color: modelData.act === "trash" ? theme.error : theme.text
                                font.family: settings.font
                                font.pixelSize: 13
                            }
                            MouseArea {
                                id: itemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: modelData.on
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    menu.close();
                                    switch (modelData.act) {
                                    case "open": win.openIndex(win.cur); break;
                                    case "cut": win.copySel(true); break;
                                    case "copy": win.copySel(false); break;
                                    case "paste": win.paste(); break;
                                    case "rename": win.askRename(); break;
                                    case "trash": win.trashSel(); break;
                                    case "mkdir": win.askNewFolder(); break;
                                    case "all": win.selectAll(); break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- rename / new-folder prompt
        Item {
            id: prompt
            anchors.fill: parent
            visible: false
            z: 20
            property string heading: ""
            property string confirmLabel: ""
            property var callback: null

            function open(title, initial, label, cb) {
                heading = title;
                confirmLabel = label;
                callback = cb;
                promptInput.text = initial;
                visible = true;
                promptInput.forceActiveFocus();
                // Select the name without its extension.
                const dot = initial.lastIndexOf(".");
                promptInput.select(0, dot > 0 ? dot : initial.length);
            }
            function accept() {
                const cb = callback;
                const value = promptInput.text.trim();
                visible = false;
                root.forceActiveFocus();
                if (cb && value !== "" && value.indexOf("/") < 0) cb(value);
            }
            function cancel() {
                visible = false;
                root.forceActiveFocus();
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.45)
                MouseArea { anchors.fill: parent; onClicked: prompt.cancel() }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 380
                height: 150
                radius: 24
                color: theme.surfaceHigh
                border.width: 1
                border.color: theme.outline

                Text {
                    anchors { left: parent.left; top: parent.top; margins: 22 }
                    text: prompt.heading
                    color: theme.text
                    font.family: settings.font
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 22; rightMargin: 22; verticalCenterOffset: 4 }
                    height: 38
                    radius: 19
                    color: theme.surface
                    border.width: 1
                    border.color: theme.accent

                    TextInput {
                        id: promptInput
                        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: theme.text
                        selectionColor: theme.accent
                        selectedTextColor: theme.accentText
                        font.family: settings.font
                        font.pixelSize: 14
                        clip: true
                        onAccepted: prompt.accept()
                        Keys.onEscapePressed: prompt.cancel()
                    }
                }

                Row {
                    anchors { right: parent.right; bottom: parent.bottom; margins: 18 }
                    spacing: 8

                    Rectangle {
                        width: 84; height: 32; radius: 16
                        color: cancelHover.containsMouse ? Qt.lighter(theme.surfaceHigh, 1.3) : "transparent"
                        Text { anchors.centerIn: parent; text: "Cancel"; color: theme.text; font.family: settings.font; font.pixelSize: 13 }
                        MouseArea { id: cancelHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: prompt.cancel() }
                    }
                    Rectangle {
                        width: 96; height: 32; radius: 16
                        color: theme.accent
                        Text { anchors.centerIn: parent; text: prompt.confirmLabel; color: theme.accentText; font.family: settings.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: prompt.accept() }
                    }
                }
            }
        }
    }

    Component.onCompleted: root.forceActiveFocus()
}
