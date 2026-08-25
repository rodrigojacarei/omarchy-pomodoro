import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "omarchy-pomodoro"
  ipcTarget: "omarchy-pomodoro"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var timerHost: hostWidget || root
  readonly property var barIdentity: hostWidget || root

  readonly property color contentForeground: bar ? bar.foreground : Color.foreground
  readonly property color accentColor: Color.accent
  readonly property string contentFontFamily: bar ? bar.fontFamily : Style.font.family

  property bool showSettings: false

  // Detect current bar section from host bar layout
  readonly property string currentSection: {
    if (!bar || !bar.layoutConfig) return "center"
    var layout = bar.layoutConfig
    var sections = ["left", "center", "right"]
    for (var s = 0; s < sections.length; s++) {
      var list = layout[sections[s]] || []
      for (var i = 0; i < list.length; i++) {
        var entry = list[i]
        var id = (typeof entry === "string") ? entry : (entry ? entry.id : "")
        if (id === root.moduleName) return sections[s]
      }
    }
    return "center"
  }

  function moveToSection(sec) {
    if (root.bar && root.bar.shell && typeof root.bar.shell.moveBarWidget === "function") {
      root.bar.shell.moveBarWidget(root.moduleName, JSON.stringify({ section: sec }))
    } else {
      Quickshell.execDetached(["omarchy-shell", "shell", "moveBarWidget", root.moduleName, JSON.stringify({ section: sec })])
    }
  }

  function open() {
    root.controller.show()
  }

  function close() {
    showSettings = false
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function persist(newSettings) {
    var entry = { id: root.moduleName }
    for (var k in root.settings) if (k !== "id") entry[k] = root.settings[k]
    for (var key in newSettings) entry[key] = newSettings[key]

    root.settings = entry
    if (root.hostWidget && "settings" in root.hostWidget) root.hostWidget.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function") {
      root.bar.shell.updateEntryInline(root.moduleName, entry)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onActivateRequested: {
        if (timerHost && timerHost.togglePlayPause) timerHost.togglePlayPause()
      }
      onMoveRequested: function(dx, dy) {
        if (dy !== 0 && panelScroll.interactive) {
          panelScroll.contentY = Math.max(0, Math.min(panelScroll.contentHeight - panelScroll.height, panelScroll.contentY + dy * Style.space(50)))
        }
      }

      onTextKey: function(t) {
        if (t === "r" || t === "R") {
          if (timerHost && timerHost.reset) timerHost.reset()
        } else if (t === "s" || t === "S") {
          if (timerHost && timerHost.skipPhase) timerHost.skipPhase()
        } else if (t === "1") {
          if (timerHost && timerHost.setPhase) timerHost.setPhase(Model.PHASE_WORK, false)
        } else if (t === "2") {
          if (timerHost && timerHost.setPhase) timerHost.setPhase(Model.PHASE_SHORT_BREAK, false)
        } else if (t === "3") {
          if (timerHost && timerHost.setPhase) timerHost.setPhase(Model.PHASE_LONG_BREAK, false)
        } else if (t === "+" || t === "=") {
          if (timerHost && timerHost.adjustTime) timerHost.adjustTime(60)
        } else if (t === "-" || t === "_") {
          if (timerHost && timerHost.adjustTime) timerHost.adjustTime(-60)
        }
      }

      Flickable {
        id: panelScroll
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height

        Column {
          id: mainColumn
          width: panelScroll.width
          spacing: Style.space(14)

          // ---------------------------------------------------- Hero Header
          Item {
            id: heroItem
            width: parent.width
            implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight, heroToggle.implicitHeight)

            Text {
              id: heroIcon
              text: timerHost ? timerHost.iconString : "󰔛"
              color: timerHost && timerHost.isRunning ? root.accentColor : root.contentForeground
              font.family: root.contentFontFamily
              font.pixelSize: Style.font.display
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              id: heroLabels
              anchors.left: heroIcon.right
              anchors.leftMargin: Style.space(12)
              anchors.right: heroToggle.left
              anchors.rightMargin: Style.space(12)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                text: timerHost ? timerHost.phaseName : "Focus Session"
                color: root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                property int sessionNum: (timerHost ? (timerHost.completedSessions % (timerHost.longBreakInterval || 4)) : 0) + 1
                property int totalCycle: timerHost ? (timerHost.longBreakInterval || 4) : 4
                property string stateStr: timerHost ? (timerHost.isRunning ? "RUNNING" : (timerHost.isPaused ? "PAUSED" : "READY")) : "READY"
                text: stateStr + "  •  ROUND " + sessionNum + "/" + totalCycle
                color: timerHost && timerHost.isRunning ? root.accentColor : Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.1
                elide: Text.ElideRight
                width: parent.width
              }
            }

            // Quick play/pause switch on hero
            ToggleSwitch {
              id: heroToggle
              checked: timerHost ? timerHost.isRunning : false
              foreground: root.contentForeground
              accent: root.accentColor
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              onToggled: {
                if (timerHost && timerHost.togglePlayPause) timerHost.togglePlayPause()
              }

              PanelToolTip {
                visible: heroToggle.containsMouse
                text: timerHost && timerHost.isRunning ? "Pause timer (Space)" : "Start timer (Space)"
                fontFamily: root.contentFontFamily
              }
            }
          }

          // ------------------------------------------ Timer Large Display & Bar
          BorderSurface {
            id: timerCard
            width: parent.width
            implicitHeight: timerContent.implicitHeight + Style.space(20)
            radius: Style.cornerRadius
            color: Style.normalFillFor(root.contentForeground, root.accentColor)
            borderSpec: Border.controlSpec("normal", root.contentForeground, root.accentColor)

            Column {
              id: timerContent
              anchors.centerIn: parent
              width: parent.width - Style.space(24)
              spacing: Style.space(10)

              // Big countdown display
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: timerHost ? timerHost.timeString : "25:00"
                color: timerHost && timerHost.isRunning ? root.accentColor : root.contentForeground
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.display * 1.5
                font.bold: true
              }

              // Linear Progress Bar
              Item {
                width: parent.width
                height: Style.space(6)

                // Background track
                Rectangle {
                  anchors.fill: parent
                  radius: height / 2
                  color: Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.15)
                }

                // Foreground progress
                Rectangle {
                  height: parent.height
                  width: Math.max(height, Math.round(parent.width * (timerHost ? timerHost.progress : 0)))
                  radius: height / 2
                  color: root.accentColor

                  Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                  }
                }
              }

              // Pomodoro Session Cycle Dots
              Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Style.space(8)

                Repeater {
                  model: timerHost ? (timerHost.longBreakInterval || 4) : 4

                  Rectangle {
                    required property int index
                    readonly property int currentRound: timerHost ? (timerHost.completedSessions % (timerHost.longBreakInterval || 4)) : 0
                    readonly property bool isDone: index < currentRound
                    readonly property bool isCurrent: index === currentRound

                    width: isCurrent ? Style.space(18) : Style.space(8)
                    height: Style.space(8)
                    radius: Style.space(4)
                    color: isDone || (isCurrent && timerHost && timerHost.isRunning)
                      ? root.accentColor
                      : Qt.rgba(root.contentForeground.r, root.contentForeground.g, root.contentForeground.b, 0.25)

                    Behavior on width {
                      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                      ColorAnimation { duration: 150 }
                    }
                  }
                }
              }
            }
          }

          // ---------------------------------------------------- Mode Switcher
          Row {
            id: modeRow
            width: parent.width
            spacing: Style.space(6)
            readonly property int itemWidth: Math.floor((width - spacing * 2) / 3)

            Button {
              id: modeWorkBtn
              width: modeRow.itemWidth
              text: "Focus"
              iconText: "󰔛"
              selected: timerHost ? timerHost.phase === Model.PHASE_WORK : true
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.bodySmall
              onClicked: {
                if (timerHost && timerHost.setPhase) timerHost.setPhase(Model.PHASE_WORK, false)
              }
            }

            Button {
              id: modeShortBtn
              width: modeRow.itemWidth
              text: "Short"
              iconText: "󰚢"
              selected: timerHost ? timerHost.phase === Model.PHASE_SHORT_BREAK : false
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.bodySmall
              onClicked: {
                if (timerHost && timerHost.setPhase) timerHost.setPhase(Model.PHASE_SHORT_BREAK, false)
              }
            }

            Button {
              width: modeRow.width - modeWorkBtn.width - modeShortBtn.width - modeRow.spacing * 2
              text: "Long"
              iconText: "󰒲"
              selected: timerHost ? timerHost.phase === Model.PHASE_LONG_BREAK : false
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.bodySmall
              onClicked: {
                if (timerHost && timerHost.setPhase) timerHost.setPhase(Model.PHASE_LONG_BREAK, false)
              }
            }
          }

          // ------------------------------------------------- Primary Controls
          Row {
            id: controlsRow
            width: parent.width
            spacing: Style.space(8)

            // Start / Pause Main Button
            Button {
              id: startPauseBtn
              width: controlsRow.width - resetBtn.width - skipBtn.width - controlsRow.spacing * 2
              text: timerHost && timerHost.isRunning ? "Pause" : "Start"
              iconText: timerHost && timerHost.isRunning ? "󰏤" : "󰐊"
              active: timerHost ? timerHost.isRunning : false
              selected: timerHost ? timerHost.isRunning : false
              bordered: true
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.body
              onClicked: {
                if (timerHost && timerHost.togglePlayPause) timerHost.togglePlayPause()
              }
            }

            // Reset Button
            Button {
              id: resetBtn
              width: Style.space(46)
              iconText: "󰑖"
              tooltipText: "Reset timer (R)"
              bordered: true
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.body
              iconSize: Style.font.body
              onClicked: {
                if (timerHost && timerHost.reset) timerHost.reset()
              }
            }

            // Skip Button
            Button {
              id: skipBtn
              width: Style.space(46)
              iconText: "󰒭"
              tooltipText: "Skip to next phase (S)"
              bordered: true
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.body
              iconSize: Style.font.body
              onClicked: {
                if (timerHost && timerHost.skipPhase) timerHost.skipPhase()
              }
            }
          }

          // ------------------------------------------------ Quick Adjustments
          Row {
            id: adjustRow
            width: parent.width
            spacing: Style.space(6)
            readonly property int itemWidth: Math.floor((width - spacing * 3) / 4)

            Button {
              id: adj1
              width: adjustRow.itemWidth
              text: "-5m"
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.caption
              onClicked: if (timerHost && timerHost.adjustTime) timerHost.adjustTime(-300)
            }

            Button {
              id: adj2
              width: adjustRow.itemWidth
              text: "-1m"
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.caption
              onClicked: if (timerHost && timerHost.adjustTime) timerHost.adjustTime(-60)
            }

            Button {
              id: adj3
              width: adjustRow.itemWidth
              text: "+1m"
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.caption
              onClicked: if (timerHost && timerHost.adjustTime) timerHost.adjustTime(60)
            }

            Button {
              width: adjustRow.width - adj1.width - adj2.width - adj3.width - adjustRow.spacing * 3
              text: "+5m"
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              fontSize: Style.font.caption
              onClicked: if (timerHost && timerHost.adjustTime) timerHost.adjustTime(300)
            }
          }

          // ------------------------------------------- Settings Expander Header
          PanelSeparator {
            foreground: root.contentForeground
          }

          Item {
            width: parent.width
            implicitHeight: Math.max(settingsHeader.implicitHeight, settingsToggleBtn.implicitHeight)

            PanelSectionHeader {
              id: settingsHeader
              text: "SETTINGS & PREFERENCES"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            PanelActionButton {
              id: settingsToggleBtn
              iconText: root.showSettings ? "󰅃" : "󰅀"
              tooltipText: root.showSettings ? "Hide settings" : "Show settings"
              foreground: root.contentForeground
              fontFamily: root.contentFontFamily
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              onClicked: root.showSettings = !root.showSettings
            }
          }

          // --------------------------------------------- Collapsible Settings
          Column {
            width: parent.width
            spacing: Style.space(12)
            visible: root.showSettings

            // Bar Placement Selector
            Column {
              width: parent.width
              spacing: Style.space(6)

              Text {
                text: "BAR SECTION PLACEMENT"
                color: Qt.darker(root.contentForeground, 1.4)
                font.family: root.contentFontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.1
              }

              Row {
                id: placementRow
                width: parent.width
                spacing: Style.space(6)
                readonly property int secW: Math.floor((width - spacing * 2) / 3)

                Button {
                  id: secLeftBtn
                  width: placementRow.secW
                  text: "Left"
                  iconText: "󰮞"
                  selected: root.currentSection === "left"
                  foreground: root.contentForeground
                  accent: root.accentColor
                  fontFamily: root.contentFontFamily
                  fontSize: Style.font.bodySmall
                  onClicked: root.moveToSection("left")
                }

                Button {
                  id: secCenterBtn
                  width: placementRow.secW
                  text: "Center"
                  iconText: "󰮝"
                  selected: root.currentSection === "center"
                  foreground: root.contentForeground
                  accent: root.accentColor
                  fontFamily: root.contentFontFamily
                  fontSize: Style.font.bodySmall
                  onClicked: root.moveToSection("center")
                }

                Button {
                  width: placementRow.width - secLeftBtn.width - secCenterBtn.width - placementRow.spacing * 2
                  text: "Right"
                  iconText: "󰮟"
                  selected: root.currentSection === "right"
                  foreground: root.contentForeground
                  accent: root.accentColor
                  fontFamily: root.contentFontFamily
                  fontSize: Style.font.bodySmall
                  onClicked: root.moveToSection("right")
                }
              }
            }

            // Duration controls
            Row {
              id: durationRow
              width: parent.width
              spacing: Style.space(8)
              readonly property int fieldW: Math.floor((width - spacing * 2) / 3)

              NumberField {
                width: durationRow.fieldW
                fieldWidth: width
                label: "Focus (min)"
                value: timerHost ? timerHost.workMinutes : 25
                from: 1
                to: 120
                fontFamily: root.contentFontFamily
                foreground: root.contentForeground
                accent: root.accentColor
                onModified: function(v) {
                  root.persist({ workMinutes: v })
                }
              }

              NumberField {
                width: durationRow.fieldW
                fieldWidth: width
                label: "Short (min)"
                value: timerHost ? timerHost.shortBreakMinutes : 5
                from: 1
                to: 60
                fontFamily: root.contentFontFamily
                foreground: root.contentForeground
                accent: root.accentColor
                onModified: function(v) {
                  root.persist({ shortBreakMinutes: v })
                }
              }

              NumberField {
                width: durationRow.fieldW
                fieldWidth: width
                label: "Long (min)"
                value: timerHost ? timerHost.longBreakMinutes : 15
                from: 1
                to: 90
                fontFamily: root.contentFontFamily
                foreground: root.contentForeground
                accent: root.accentColor
                onModified: function(v) {
                  root.persist({ longBreakMinutes: v })
                }
              }
            }

            Row {
              id: cycleRow
              width: parent.width
              spacing: Style.space(8)

              NumberField {
                id: roundsField
                width: Math.floor((cycleRow.width - cycleRow.spacing) / 3)
                fieldWidth: width
                label: "Rounds/Cycle"
                value: timerHost ? timerHost.longBreakInterval : 4
                from: 1
                to: 12
                fontFamily: root.contentFontFamily
                foreground: root.contentForeground
                accent: root.accentColor
                onModified: function(v) {
                  root.persist({ longBreakInterval: v })
                }
              }

              Button {
                width: cycleRow.width - roundsField.width - cycleRow.spacing
                anchors.bottom: parent.bottom
                text: "Reset Cycle Count"
                iconText: "󰑖"
                foreground: root.contentForeground
                accent: root.accentColor
                fontFamily: root.contentFontFamily
                fontSize: Style.font.bodySmall
                onClicked: {
                  if (timerHost && timerHost.resetSessionsCount) timerHost.resetSessionsCount()
                }
              }
            }

            // Display Toggles
            Toggle {
              width: parent.width
              label: "Show timer in bar"
              description: "Display countdown time digits directly on the bar"
              checked: timerHost ? timerHost.showTimerInBar : true
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              onClicked: {
                root.persist({ showTimerInBar: !checked })
              }
            }

            Toggle {
              width: parent.width
              label: "Show icon in bar"
              description: "Display phase icon glyph on the bar"
              checked: timerHost ? timerHost.showIconInBar : true
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              onClicked: {
                root.persist({ showIconInBar: !checked })
              }
            }

            Toggle {
              width: parent.width
              label: "Hide on bar when idle"
              description: "Only show widget on status bar when timer is running/paused"
              checked: timerHost ? timerHost.showOnlyWhenRunning : false
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              onClicked: {
                root.persist({ showOnlyWhenRunning: !checked })
              }
            }

            // Behavior Toggles
            Toggle {
              width: parent.width
              label: "Auto-start breaks"
              description: "Automatically start timer when a break begins"
              checked: timerHost ? timerHost.autoStartBreaks : false
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              onClicked: {
                root.persist({ autoStartBreaks: !checked })
              }
            }

            Toggle {
              width: parent.width
              label: "Auto-start focus sessions"
              description: "Automatically start work timer after break ends"
              checked: timerHost ? timerHost.autoStartWork : false
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              onClicked: {
                root.persist({ autoStartWork: !checked })
              }
            }

            Toggle {
              width: parent.width
              label: "Desktop notifications"
              description: "Send Omarchy notification when phase completes"
              checked: timerHost ? timerHost.notifyEnabled : true
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              onClicked: {
                root.persist({ notifyEnabled: !checked })
              }
            }

            Toggle {
              width: parent.width
              label: "Sound chime"
              description: "Play audio alert when timer reaches zero"
              checked: timerHost ? timerHost.soundEnabled : true
              foreground: root.contentForeground
              accent: root.accentColor
              fontFamily: root.contentFontFamily
              onClicked: {
                root.persist({ soundEnabled: !checked })
              }
            }
          }
        }
      }

      ScrollBar {
        id: scrollBar
        anchors.left: panelScroll.right
        anchors.leftMargin: Style.space(4)
        anchors.top: panelScroll.top
        anchors.bottom: panelScroll.bottom
        orientation: Qt.Vertical
        policy: panelScroll.interactive ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
        width: Style.space(4)
        padding: 0
        size: panelScroll.height / Math.max(panelScroll.height, panelScroll.contentHeight)
        position: panelScroll.contentY / Math.max(1, panelScroll.contentHeight)

        onPositionChanged: {
          if (scrollBar.pressed) {
            panelScroll.contentY = position * panelScroll.contentHeight
          }
        }

        contentItem: Rectangle {
          implicitWidth: Style.space(4)
          radius: width / 2
          color: root.accentColor
          opacity: scrollBar.pressed ? 0.95 : (scrollBar.hovered ? 0.8 : (panelScroll.moving || panelScroll.flicking ? 0.65 : 0.35))

          Behavior on opacity {
            NumberAnimation { duration: 150 }
          }
        }
      }
    }
  }
}
