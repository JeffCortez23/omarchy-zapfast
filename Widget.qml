import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// ZapFast native Quattro / Omarchy bar widget.
// The bar owns the trigger and the PopupCard owns the detail surface.
BarWidget {
  id: root
  moduleName: "crmne.zapfast"
  property bool popupOpen: false
  readonly property color foreground: bar ? bar.foreground : Color.foreground

  // Omarchy palette luminance check for light/dark
  readonly property bool isDark: {
    var surface = bar ? bar.background : Color.background
    var luminance = (0.2126 * surface.r) + (0.7152 * surface.g) + (0.0722 * surface.b)
    return luminance < 0.5
  }

  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }

  function statusText() {
    if (!data.installed) return "Not installed"
    if (data.running && data.appVisible) return "Open · " + themeLabel()
    if (data.running) return "In tray · " + themeLabel()
    return "Closed"
  }

  function themeLabel() {
    return data.theme === "system" ? "System theme" : (data.theme ? data.theme + " theme" : "Default theme")
  }

  function toggleApp() { data.toggle() }

  function handleBarClick(buttonCode) {
    if (buttonCode === Qt.RightButton) {
      root.toggle()
    } else if (buttonCode === Qt.MiddleButton) {
      data.reloadThemes()
    } else if (!data.installed) {
      root.open()
    } else {
      data.toggle()
    }
  }

  function triggerPress(buttonCode) { handleBarClick(buttonCode) }

  Data { id: data }

  Component.onCompleted: {
    data.launchCommand = String(setting("launchCommand", "uwsm-app -- zapfast"))
    root.showBrand = String(setting("icon", "glyph")) === "brand"
  }

  implicitWidth: Style.bar.statusSlot
  implicitHeight: barSize

  // Icon style: brand (ZapFast logo) or glyph (WhatsApp text glyph)
  property bool showBrand: false

  // How unread messages are surfaced: "count", "highlight", or "none"
  readonly property string badgeMode: {
    var v = String(setting("badge", "Count")).toLowerCase()
    return (v === "highlight" || v === "none") ? v : "count"
  }
  readonly property bool hasUnread: data.unreadCount > 0
  readonly property bool highlightActive: root.badgeMode === "highlight" && root.hasUnread
  readonly property color alertColor: root.bar ? root.bar.urgent : Color.urgent
  readonly property string badgeLabel:
    root.badgeMode === "highlight" ? "Highlight icon"
    : root.badgeMode === "none" ? "None" : "Count"

  function cycleBadge() {
    var next = root.badgeMode === "count" ? "Highlight"
      : root.badgeMode === "highlight" ? "None" : "Count"
    root.persist("badge", next)
  }

  // Persist settings in Omarchy shell.json
  function persist(key, value) {
    var entry = { id: root.moduleName }
    for (var k in root.settings) {
      if (k !== "id") entry[k] = root.settings[k]
    }
    entry[key] = value
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
  }

  // Brand Icon
  Image {
    visible: root.showBrand
    anchors.centerIn: parent
    width: Math.min(barSize, Style.space(24))
    height: Math.min(barSize, Style.space(24))
    source: Qt.resolvedUrl("assets/zapfast-widget-32.png")
    sourceSize.width: 32
    sourceSize.height: 32
    fillMode: Image.PreserveAspectFit
  }

  // WhatsApp Glyph Glowing layers when running
  Text {
    visible: !root.showBrand
    anchors.centerIn: parent
    text: "󰖣"
    color: root.highlightActive ? root.alertColor : Commons.Color.accent
    opacity: data.running ? 0.16 : 0
    scale: 1.55
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.bar.iconFont + Style.space(2)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    visible: !root.showBrand
    anchors.centerIn: parent
    text: "󰖣"
    color: root.highlightActive ? root.alertColor : Commons.Color.accent
    opacity: data.running ? 0.28 : 0
    scale: 1.24
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.bar.iconFont + Style.space(2)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  Text {
    visible: !root.showBrand
    anchors.centerIn: parent
    text: "󰖣"
    color: root.highlightActive ? root.alertColor
      : (data.running ? Commons.Color.accent : root.foreground)
    font.family: root.bar ? root.bar.fontFamily : Style.font.family
    font.pixelSize: Style.bar.iconFont + Style.space(2)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  // Unread badge pill
  Rectangle {
    visible: root.hasUnread && root.badgeMode === "count"
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.horizontalCenterOffset: Style.space(8)
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -Style.space(7)
    width: data.unreadCount >= 100
      ? Style.space(24)
      : data.unreadCount >= 10 ? Style.space(17) : Style.space(14)
    height: Style.space(14)
    radius: height / 2
    color: "#d9485f"
    border.color: root.foreground
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: data.unreadCount >= 100 ? "99+" : String(data.unreadCount)
      color: "white"
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: data.unreadCount >= 100 ? 7 : 8
      font.bold: true
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) { root.handleBarClick(mouse.button) }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(280))
    contentHeight: popup.fittedContentHeight(contentColumn.implicitHeight)

    Column {
      id: contentColumn
      width: parent.width
      spacing: Style.space(10)

      Row {
        width: parent.width
        spacing: Style.space(10)

        Image {
          width: Style.space(36)
          height: Style.space(36)
          source: Qt.resolvedUrl("assets/zapfast-widget-64.png")
          sourceSize.width: 64
          sourceSize.height: 64
          fillMode: Image.PreserveAspectFit
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Text {
            text: "ZapFast"
            color: root.foreground
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

          Text {
            text: root.statusText()
            color: Qt.darker(root.foreground, 1.45)
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
          }
        }
      }

      PanelSeparator {
        visible: data.installed
        foreground: root.foreground
      }

      Button {
        width: parent.width
        visible: data.installed
        text: data.appVisible ? "Hide ZapFast" : "Open ZapFast"
        iconText: data.appVisible ? "󰍃" : "󰖰"
        leftAlign: true
        foreground: root.foreground
        onClicked: {
          root.toggleApp()
          root.close()
        }
      }

      Column {
        visible: !data.installed
        width: parent.width
        spacing: Style.space(6)

        Text {
          width: parent.width
          text: "ZapFast is not installed. Install it from the AUR, then reopen the app:"
          color: root.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Text {
          width: parent.width
          text: "yay -S --needed zapfast-bin"
          color: root.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WrapAnywhere
        }
      }

      Button {
        width: parent.width
        visible: data.installed
        text: "Reload Omarchy Theme"
        iconText: "󰏘"
        leftAlign: true
        foreground: root.foreground
        enabled: data.running
        onClicked: {
          data.reloadThemes()
          root.close()
        }
      }

      Button {
        width: parent.width
        text: "Unread: " + root.badgeLabel
        iconText: "󰎟"
        leftAlign: true
        foreground: root.foreground
        onClicked: root.cycleBadge()
      }

      Button {
        width: parent.width
        visible: data.installed
        text: "Quit ZapFast"
        iconText: "󰗼"
        leftAlign: true
        foreground: root.foreground
        enabled: data.running
        onClicked: {
          data.quit()
          root.close()
        }
      }
    }
  }
}
