# Changelog

All notable changes to the **Omarchy ZapFast** plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-30

### Added
- **Native Omarchy Bar Widget (`BarWidget`)**:
  - Themed status bar icon with animated glowing layers and pulse indicators when ZapFast is active.
  - Dual icon style support: WhatsApp glyph (`󰖣`) or ZapFast brand vector icon (`zapfast.svg`).
  - Seamless auto-theming following Omarchy desktop color palettes and luminance.
- **Smart Window Toggle & Tray Lifecycle**:
  - 1-click toggle: launches ZapFast if closed, focuses and raises it if hidden in the tray, or sends it to the tray if currently visible.
  - Native integration with Omarchy's Hyprland Lua dispatcher (`hl.dsp.window.close({ window = 'class:zapfast' })`) to cleanly hide the window without killing the background process.
  - Zero-lag process liveness monitoring via PID check and Hyprland client state.
- **Real-Time Unread Badges**:
  - Live message counter pill badge (`"3"`, `"99+"`) rendered directly over the status bar icon.
  - Built-in `busctl` listener streaming Linux Unity LauncherEntry D-Bus signals (`com.canonical.Unity.LauncherEntry`) emitted by ZapFast's `fastframe-dock`.
  - Configurable unread modes: **Count** (pill badge), **Highlight** (recolors icon to urgent accent), and **None**.
- **Omarchy Theme Synchronization**:
  - Middle-click shortcut and dedicated popup action to synchronize active Omarchy palette and trigger `zapfast reload-themes`.
  - Reads `~/.config/zapfast/settings.json` reactively via Quickshell `FileView`.
- **Interactive Control Panel (`PopupCard`)**:
  - Right-click popup card displaying ZapFast status (*Open*, *In tray*, *Closed*, *Not installed*).
  - Quick action buttons: *Open/Hide ZapFast*, *Reload Omarchy Theme*, *Unread mode cycle*, and *Quit ZapFast*.
  - Inline installer helper for Arch Linux / AUR (`yay -S --needed zapfast-bin`) when not installed.
