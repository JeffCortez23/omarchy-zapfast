# ZapFast Omarchy Plugin

Native Omarchy status bar widget and controls for [ZapFast](https://zapfast.rocks) (the fast, native Rust WhatsApp desktop client).

Designed following the [PrettyZap](https://github.com/prettyletto/prettyzap) bar widget pattern, customized specifically for ZapFast's native architecture, Hyprland window management, and Linux desktop integration.

---

## Features

- **Native Status Bar Widget:** Sits cleanly in your Omarchy status bar with an active glow indicator.
- **Smart Window Toggle:**
  - Left-click on the bar icon launches ZapFast if closed, focuses it if hidden in the tray or in another workspace, or minimizes/closes it into the tray if currently focused.
- **Live Unread Badges:**
  - Real-time unread message counter badge (`"3"`, `"99+"`) listening directly to ZapFast's Linux LauncherEntry D-Bus signals.
  - Cycle between **Count**, **Highlight icon**, or **None**.
- **Omarchy Theme Sync:**
  - Middle-click or popup button reloads Omarchy's color palette into ZapFast instantly (`zapfast reload-themes`).
- **Native Popup Control Panel:**
  - Right-click opens the PopupCard with live status (Open / In tray / Closed / Not installed), quick toggle, theme reloader, badge mode cycler, and **Quit ZapFast**.

---

## Installation

### 1. Make sure ZapFast is installed

```bash
yay -S --needed zapfast-bin
```

### 2. Install this Omarchy Plugin

Link or copy this plugin to your Omarchy plugins directory:

```bash
# Clone the repository
git clone https://github.com/<your-username>/zapfast-omarchy.git ~/.config/omarchy/plugins/crmne.zapfast

# Enable it in Omarchy
omarchy plugin enable crmne.zapfast
```

Or add it to your `~/.config/omarchy/shell.json` in the status bar section:

```json
{
  "id": "crmne.zapfast"
}
```

---

## Mouse Controls

| Action | Result |
| :--- | :--- |
| **Left Click** | Smart Toggle (Launch ZapFast / Surface window / Hide to tray) |
| **Middle Click** | Reload Omarchy theme palette into ZapFast |
| **Right Click** | Open / Close the native control popup card |

---

## Configuration

In `~/.config/omarchy/shell.json`, you can customize the widget under its entry:

```json
{
  "id": "crmne.zapfast",
  "icon": "glyph", // "glyph" (WhatsApp symbol) or "brand" (ZapFast logo)
  "badge": "Count", // "Count", "Highlight", or "None"
  "launchCommand": "uwsm-app -- zapfast"
}
```

---

## License

MIT
