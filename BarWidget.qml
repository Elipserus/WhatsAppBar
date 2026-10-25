import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// WhatsApp Web on the bar: a click hides its window in a special workspace
// and the next brings it back (call windows are never touched). A badge
// counts the chats that have notified since you last looked at WhatsApp.
BarWidget {
  id: root
  moduleName: "io.github.elipserus.whatsapp"

  readonly property string helper: decodeURIComponent(Qt.resolvedUrl("whatsapp-toggle").toString().replace(/^file:\/\//, ""))

  property bool running: false
  property bool hidden: false
  property string address: ""
  property string activeAddress: ""
  readonly property bool focused: address !== "" && activeAddress === address && !hidden

  // Chats (by notification title) that wrote since WhatsApp was last in view.
  // WhatsApp Web doesn't expose its unread count, so its notifications are
  // the only signal available.
  property var unreadChats: ({})
  readonly property int unreadCount: Object.keys(unreadChats).length
  // Each notification file can be reported twice (toast, then history).
  property var seenNotifications: ({})
  // Notifications saved before the widget started are old news.
  readonly property real startedAt: Date.now()

  function refresh() {
    if (!statusProc.running) statusProc.running = true
    else pendingRefresh = true
  }
  property bool pendingRefresh: false

  function toggle() {
    if (!running) return
    hidden = !hidden
    if (!hidden) clearUnread()
    Quickshell.execDetached([helper, "toggle"])
  }

  function clearUnread() {
    if (unreadCount > 0) unreadChats = ({})
  }

  // `key` is the notification's file name, "<timestamp ms>-<id>".
  function noteNotification(key, chat) {
    if (seenNotifications[key] || parseInt(key, 10) < startedAt) return
    seenNotifications[key] = true
    if (chat === "" || focused || unreadChats[chat]) return
    var next = Object.assign({}, unreadChats)
    next[chat] = true
    unreadChats = next
  }

  visible: running

  readonly property real logoSize: Style.bar.iconFont * 0.9
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  IpcHandler {
    target: "io.github.elipserus.whatsapp"

    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
    function clear(): void { root.clearUnread() }
  }

  Process {
    id: statusProc
    command: [root.helper, "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = text.trim().split(" ")
        root.running = parts[0] === "1"
        root.hidden = parts.length > 1 && parts[1] === "1"
        root.address = parts.length > 2 && parts[2] !== "-" ? parts[2] : ""
        if (root.pendingRefresh) {
          root.pendingRefresh = false
          root.refresh()
        }
      }
    }
  }

  // Window events drive updates; looking at WhatsApp clears the badge.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      switch (event.name) {
      case "activewindowv2":
        root.activeAddress = event.data ? "0x" + event.data : ""
        if (root.focused) root.clearUnread()
        break
      case "openwindow":
      case "closewindow":
      case "movewindowv2":
      case "windowtitlev2":
        root.refresh()
      }
    }
  }

  // Plugins can't reach the shell's notification service, but it saves every
  // notification to disk; the helper watches those files.
  Process {
    command: [root.helper, "watch"]
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        var tab = line.indexOf("\t")
        if (tab > 0) root.noteNotification(line.slice(0, tab), line.slice(tab + 1))
      }
    }
  }

  // Safety net in case an event is missed.
  Timer {
    interval: 10000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: (root.hidden ? "Mostrar WhatsApp" : "Ocultar WhatsApp")
      + (root.unreadCount === 1 ? " · 1 conversación sin leer"
        : root.unreadCount > 1 ? " · " + root.unreadCount + " conversaciones sin leer" : "")
    onPressed: root.toggle()

    iconComponent: Component {
      Item {
        // WhatsApp logo from Simple Icons (CC0), on a 24x24 viewBox, drawn
        // at 90% of the bar's icon font size.
        Shape {
          id: logo
          anchors.centerIn: parent
          width: 24
          height: 24
          scale: root.logoSize / 24
          preferredRendererType: Shape.CurveRenderer

          ShapePath {
            fillColor: button.foreground
            strokeWidth: -1
            PathSvg {
              path: "M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"
            }
          }
        }

        // Unread chats, just the number beside the logo's bottom-right
        // corner, clear of the logo so it stays readable.
        Text {
          visible: root.unreadCount > 0
          x: parent.width / 2 + root.logoSize / 2 + Style.space(1)
          y: parent.height / 2 + root.logoSize / 2 - implicitHeight * 0.6
          text: root.unreadCount > 9 ? "9+" : String(root.unreadCount)
          color: button.foreground
          font.family: Style.font.family
          font.pixelSize: Math.max(7, Style.font.caption - 1)
          font.bold: true
        }
      }
    }
  }
}
