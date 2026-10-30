import QtQuick
import Quickshell
import Quickshell.Io

// ZapFast status + driver for the Omarchy bar widget.
//
// Tracks ZapFast lifecycle (process liveness, Hyprland window visibility),
// captures unread message notifications via D-Bus LauncherEntry signals,
// syncs theme settings, and executes window toggle, show, hide, reload-themes, and quit.
Item {
  id: root
  visible: false

  property string launchCommand: Quickshell.env("ZAPFAST_LAUNCH_COMMAND") || "uwsm-app -- zapfast"
  property bool running: false
  property bool installed: false
  property int pid: 0
  property bool appVisible: false
  property int unreadCount: 0
  property string theme: "system"

  readonly property string home: Quickshell.env("HOME") || ""
  readonly property string settingsPath:
    (Quickshell.env("XDG_CONFIG_HOME") || home + "/.config") + "/zapfast/settings.json"

  readonly property var launchArgs: {
    var s = String(root.launchCommand || "").trim()
    return s === "" ? ["zapfast"] : s.split(/\s+/)
  }

  // Watch ZapFast's settings.json to detect theme changes
  FileView {
    id: settingsView
    path: root.settingsPath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      try {
        var parsed = JSON.parse(text())
        if (parsed && parsed.theme) {
          root.theme = String(parsed.theme)
        }
      } catch (e) {}
    }
  }

  // Check if zapfast is installed on PATH
  Process {
    id: whichProc
    running: false
    command: ["sh", "-c",
      'p=$(command -v zapfast 2>/dev/null) || exit 1; p=$(readlink -f "$p" 2>/dev/null || printf %s "$p"); test -x "$p"']
    onExited: (code) => root.installed = code === 0
  }

  function checkInstalled() {
    whichProc.running = true
  }

  // Probe process liveness and Hyprland window visibility
  Process {
    id: statusProc
    running: false
    command: ["sh", "-c",
      'if pgrep -x zapfast >/dev/null 2>&1; then
         pid=$(pgrep -x zapfast | head -n 1)
         if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.class == \\"zapfast\\" and .mapped == true)" >/dev/null 2>&1; then
           visible=true
         else
           visible=false
         fi
         echo "{\\"running\\":true,\\"pid\\":$pid,\\"visible\\":$visible}"
       else
         echo "{\\"running\\":false,\\"pid\\":0,\\"visible\\":false}"
       fi']
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var res = JSON.parse(line)
          root.running = res.running === true
          root.pid = res.pid || 0
          root.appVisible = res.visible === true
          if (!root.running) {
            root.unreadCount = 0
          }
        } catch (e) {}
      }
    }
  }

  function checkStatus() {
    if (!statusProc.running) {
      statusProc.running = true
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkStatus()
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkInstalled()
  }

  // Listen to D-Bus signal from ZapFast (fastframe-dock emits Unity LauncherEntry Update signal)
  Process {
    id: busMonitor
    running: root.running
    command: [
      "busctl", "--user", "monitor", "--json=short",
      "--match=type='signal',interface='com.canonical.Unity.LauncherEntry'"
    ]
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var msg = JSON.parse(line)
          if (msg.payload && msg.payload.data && msg.payload.data[0] === "application://zapfast.desktop") {
            var props = msg.payload.data[1] || {}
            var visible = props["count-visible"] ? props["count-visible"].data === true : false
            var count = (visible && props.count) ? Number(props.count.data) : 0
            root.unreadCount = isFinite(count) && count > 0 ? count : 0
          }
        } catch (e) {}
      }
    }
  }

  // Handle smart window toggle
  Process {
    id: toggleProc
    running: false
    command: ["sh", "-c",
      'if ! pgrep -x zapfast >/dev/null 2>&1; then
         uwsm-app -- zapfast 2>/dev/null || zapfast
         exit 0
       fi
       active=$(hyprctl activewindow -j 2>/dev/null | jq -r ".class // empty")
       if [ "$active" = "zapfast" ]; then
         hyprctl dispatch closewindow class:^zapfast$
       else
         if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.class == \\"zapfast\\" and .mapped == true)" >/dev/null 2>&1; then
           hyprctl dispatch focuswindow class:^zapfast$
         else
           zapfast
         fi
       fi']
    onExited: {
      checkStatusTimer.start()
    }
  }

  Timer {
    id: checkStatusTimer
    interval: 350
    repeat: false
    onTriggered: root.checkStatus()
  }

  function launch() {
    Quickshell.execDetached(root.launchArgs)
    checkStatusTimer.start()
  }

  function toggle() {
    if (!root.running) {
      launch()
      return
    }
    toggleProc.running = true
  }

  function show() {
    Quickshell.execDetached(["sh", "-c",
      'if hyprctl clients -j 2>/dev/null | jq -e ".[] | select(.class == \\"zapfast\\" and .mapped == true)" >/dev/null 2>&1; then
         hyprctl dispatch focuswindow class:^zapfast$
       else
         zapfast
       fi'])
    checkStatusTimer.start()
  }

  function hide() {
    Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "class:^zapfast$"])
    checkStatusTimer.start()
  }

  function reloadThemes() {
    Quickshell.execDetached(["sh", "-c",
      'if [ -x "$HOME/.config/zapfast/themes/.omarchy-hook" ]; then
         "$HOME/.config/zapfast/themes/.omarchy-hook" >/dev/null 2>&1 || true
       elif [ -f /usr/share/zapfast/omarchy/zapfast-theme ]; then
         /usr/share/zapfast/omarchy/zapfast-theme >/dev/null 2>&1 || true
       fi
       zapfast reload-themes >/dev/null 2>&1 || true'])
  }

  function quit() {
    Quickshell.execDetached(["zapfast", "quit"])
    checkStatusTimer.start()
  }

  Component.onCompleted: {
    root.checkInstalled()
    root.checkStatus()
  }
}
