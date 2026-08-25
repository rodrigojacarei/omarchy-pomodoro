// Omarchy Pomodoro - Pure Model & Helper Functions
.pragma library

var PHASE_WORK = "work";
var PHASE_SHORT_BREAK = "short_break";
var PHASE_LONG_BREAK = "long_break";

var STATE_IDLE = "idle";
var STATE_RUNNING = "running";
var STATE_PAUSED = "paused";

function pad2(n) {
  var num = Math.floor(n);
  return num < 10 ? "0" + num : String(num);
}

function formatTime(totalSeconds) {
  var sec = Math.max(0, Math.floor(totalSeconds || 0));
  var hours = Math.floor(sec / 3600);
  var minutes = Math.floor((sec % 3600) / 60);
  var seconds = sec % 60;

  if (hours > 0) {
    return hours + ":" + pad2(minutes) + ":" + pad2(seconds);
  }
  return pad2(minutes) + ":" + pad2(seconds);
}

function formatMinutes(totalSeconds) {
  var minutes = Math.round((totalSeconds || 0) / 60);
  return minutes + "m";
}

function phaseTitle(phase) {
  switch (phase) {
    case PHASE_SHORT_BREAK:
      return "Short Break";
    case PHASE_LONG_BREAK:
      return "Long Break";
    case PHASE_WORK:
    default:
      return "Focus Session";
  }
}

function phaseShortName(phase) {
  switch (phase) {
    case PHASE_SHORT_BREAK:
      return "Short Break";
    case PHASE_LONG_BREAK:
      return "Long Break";
    case PHASE_WORK:
    default:
      return "Focus";
  }
}

function phaseIcon(phase) {
  switch (phase) {
    case PHASE_SHORT_BREAK:
      return "󰚢"; // Coffee cup
    case PHASE_LONG_BREAK:
      return "󰒲"; // Rest/Sleep
    case PHASE_WORK:
    default:
      return "󰔛"; // Timer
  }
}

function phaseNotificationHeadline(phase) {
  switch (phase) {
    case PHASE_SHORT_BREAK:
      return "Short Break Finished!";
    case PHASE_LONG_BREAK:
      return "Long Break Finished!";
    case PHASE_WORK:
    default:
      return "Focus Session Complete!";
  }
}

function phaseNotificationDescription(nextPhase) {
  switch (nextPhase) {
    case PHASE_SHORT_BREAK:
      return "Time for a quick 5-minute breather.";
    case PHASE_LONG_BREAK:
      return "Great work! Time for a well-deserved long break.";
    case PHASE_WORK:
    default:
      return "Break is over. Ready to dive back in?";
  }
}

function calcProgress(timeLeft, totalSeconds) {
  if (!totalSeconds || totalSeconds <= 0) return 0.0;
  var elapsed = totalSeconds - timeLeft;
  var progress = elapsed / totalSeconds;
  return Math.max(0.0, Math.min(1.0, progress));
}

function nextPhaseInfo(currentPhase, completedWorkSessions, longBreakInterval) {
  var interval = Math.max(1, Math.floor(longBreakInterval || 4));
  var sessions = Math.max(0, Math.floor(completedWorkSessions || 0));
  var nextPhase = PHASE_WORK;
  var nextSessions = sessions;

  if (currentPhase === PHASE_WORK) {
    nextSessions = sessions + 1;
    if (nextSessions % interval === 0) {
      nextPhase = PHASE_LONG_BREAK;
    } else {
      nextPhase = PHASE_SHORT_BREAK;
    }
  } else {
    nextPhase = PHASE_WORK;
  }

  return {
    nextPhase: nextPhase,
    completedSessions: nextSessions
  };
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function parseDuration(val, defaultVal, min, max) {
  var num = parseInt(val, 10);
  if (isNaN(num)) return defaultVal;
  return clamp(num, min || 1, max || 180);
}
