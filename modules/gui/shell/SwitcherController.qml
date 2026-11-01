// State for the Alt+Tab window switcher: the window list (most recently used
// first), the selection, and the IPC entry points. The per-screen overlay is
// WindowSwitcher.qml. Binds (see hyprland.nix):
//   quickshell -c shell ipc call switcher next|prev|commit|cancel
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: ctl

    property bool open: false
    property bool loading: false
    property bool commitPending: false
    // Net number of Tab presses; entry 0 is the window you are already on.
    property int steps: 0
    property var entries: []
    property string screenName: ""

    readonly property int count: entries.length
    readonly property int index: count > 0 ? ((steps % count) + count) % count : 0

    function step(delta) {
        if (!open && !loading) {
            steps = 0;
            commitPending = false;
            loading = true;
            screenName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
            Hyprland.refreshToplevels();
            lister.running = true;
        }
        steps += delta;
    }

    function commit() {
        if (loading) {
            commitPending = true;
            return;
        }
        if (!open)
            return;
        const e = entries[index];
        open = false;
        focusEntry(e);
    }

    function cancel() {
        loading = false;
        commitPending = false;
        open = false;
    }

    function select(i) {
        steps = i;
    }

    function focusEntry(e) {
        if (!e)
            return;
        if (e.toplevel) {
            e.toplevel.activate();
        } else {
            focuser.command = ["hyprctl", "dispatch", 'hl.dsp.focus({ window = "address:' + e.address + '" })'];
            focuser.running = true;
        }
    }

    IpcHandler {
        target: "switcher"
        function next(): void { ctl.step(1); }
        function prev(): void { ctl.step(-1); }
        function commit(): void { ctl.commit(); }
        function cancel(): void { ctl.cancel(); }
    }

    Process { id: focuser }

    Process {
        id: lister
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let clients = [];
                try {
                    clients = JSON.parse(text);
                } catch (e) {}
                clients = clients.filter(c => c.mapped && !c.hidden)
                    .sort((a, b) => a.focusHistoryID - b.focusHistoryID);

                const strip = a => String(a).replace(/^0x/, "");
                const tops = Hyprland.toplevels.values;
                ctl.entries = clients.map(c => {
                    const t = tops.find(x => strip(x.address) === strip(c.address));
                    return {
                        address: c.address,
                        title: c.title,
                        cls: c.class,
                        workspace: c.workspace.name,
                        width: c.size[0],
                        height: c.size[1],
                        toplevel: t ? t.wayland : null
                    };
                });
                ctl.loading = false;

                if (ctl.entries.length === 0) {
                    ctl.commitPending = false;
                } else if (ctl.commitPending) {
                    // Alt came up before the overlay did: switch without showing it.
                    ctl.commitPending = false;
                    if (ctl.index !== 0)
                        ctl.focusEntry(ctl.entries[ctl.index]);
                } else {
                    ctl.open = true;
                }
            }
        }
    }
}
