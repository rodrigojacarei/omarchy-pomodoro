# Omarchy Pomodoro 🍅

A beautiful, fully integrated Pomodoro focus timer plugin for **[Omarchy Linux](https://omarchy.org/)**.

Designed specifically for the Omarchy status bar and Quickshell desktop environment, following Omarchy's design language, typography, and interactive keyboard/mouse controls.

---

## ✨ Features

- **Status Bar Widget**:
  - Live countdown timer (`󰔛 24:59`) directly on the Omarchy bar.
  - Phase indicator icons: `󰔛` Focus, `󰚢` Short Break, `󰒲` Long Break.
  - State highlighting: active accent color when running, dimmed when paused.
  - Interactive mouse actions:
    - **Left Click**: Open / close rich popup panel.
    - **Right Click**: Quick Start / Pause without opening popup.
    - **Middle Click**: Skip to next phase.
    - **Scroll Wheel**: Adjust remaining time ±1 minute on the fly.

- **Rich Popup Panel**:
  - **Hero Header**: Displays current phase, cycle status (`ROUND 2/4`), and quick start/pause toggle.
  - **Large Digital Clock**: Bold readout of remaining time.
  - **Progress Bar**: Smooth progress track indicating completion.
  - **Pomodoro Cycle Dots**: Visual indicator of rounds completed in the current cycle.
  - **Quick Phase Switcher**: One-click switching between **Focus (25m)**, **Short Break (5m)**, and **Long Break (15m)**.
  - **Quick Time Adjusters**: `-5m`, `-1m`, `+1m`, `+5m` buttons.
  - **Customizable Preferences**:
    - Focus duration (1–120 minutes)
    - Short break duration (1–60 minutes)
    - Long break duration (1–90 minutes)
    - Rounds per cycle (1–12 rounds)
    - Auto-start breaks toggle
    - Auto-start focus sessions toggle
    - Desktop notifications toggle
    - Sound chime toggle

- **Desktop Notifications & Sound**:
  - Sends native `omarchy-notification-send` toasts with glyphs when sessions or breaks end.
  - Plays clean audio alert chime on completion.

- **Keyboard Navigation & Hotkeys**:
  - `Space`: Start / Pause
  - `R`: Reset current timer
  - `S`: Skip to next phase
  - `1`: Switch to Focus mode
  - `2`: Switch to Short Break mode
  - `3`: Switch to Long Break mode
  - `+` / `=`: Add 1 minute
  - `-`: Subtract 1 minute
  - `Esc`: Close popup

- **CLI & IPC Integration**:
  - Included `omarchy-pomodoro` CLI script for controlling the timer from terminals or Hyprland keybindings.

---

## 📦 Installation

### Option 1: Using Omarchy CLI (Git)

```bash
omarchy plugin add https://github.com/<your-username>/omarchy-pomodoro.git --enable
```

### Option 2: Local Development / Manual Installation

Clone or copy the folder to your Omarchy plugins directory:

```bash
mkdir -p ~/.config/omarchy/plugins
cp -r /path/to/omarchy-pomodoro ~/.config/omarchy/plugins/omarchy-pomodoro
omarchy-shell shell rescanPlugins
omarchy plugin enable omarchy-pomodoro --section center
```

---

## ⌨️ Hyprland Keybindings (Optional)

You can bind hotkeys to control the timer in `~/.config/hypr/bindings.conf`:

```ini
# Toggle Pomodoro popup panel
bind = SUPER, P, exec, ~/.config/omarchy/plugins/omarchy-pomodoro/bin/omarchy-pomodoro toggle

# Start/Pause Pomodoro timer
bind = SUPER SHIFT, P, exec, ~/.config/omarchy/plugins/omarchy-pomodoro/bin/omarchy-pomodoro play-pause
```

---

## 🛠️ CLI Commands

```bash
omarchy-pomodoro toggle       # Open or close the panel
omarchy-pomodoro start        # Start timer
omarchy-pomodoro pause        # Pause timer
omarchy-pomodoro play-pause   # Toggle start/pause
omarchy-pomodoro reset        # Reset timer
omarchy-pomodoro skip         # Skip to next phase
omarchy-pomodoro focus        # Switch to Focus mode
omarchy-pomodoro short-break  # Switch to Short Break
omarchy-pomodoro long-break   # Switch to Long Break
omarchy-pomodoro +1m          # Add 1 minute
omarchy-pomodoro -1m          # Subtract 1 minute
```

You can also send direct IPC calls through `omarchy-shell`:

```bash
omarchy-shell omarchy-pomodoro toggle
omarchy-shell omarchy-pomodoro toggleRunning
omarchy-shell omarchy-pomodoro reset
```

---

## ⚙️ Configuration Schema

In `~/.config/omarchy/shell.json`, you can customize the bar widget settings:

```json
{
  "id": "omarchy-pomodoro",
  "workMinutes": 25,
  "shortBreakMinutes": 5,
  "longBreakMinutes": 15,
  "longBreakInterval": 4,
  "autoStartBreaks": false,
  "autoStartWork": false,
  "notifyEnabled": true,
  "soundEnabled": true,
  "showTimerInBar": true,
  "showIconInBar": true
}
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
