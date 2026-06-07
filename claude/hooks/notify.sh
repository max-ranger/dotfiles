#!/bin/bash
# Cross-platform notification dispatcher (Notification + PermissionRequest hooks).
# Windows: pop a desktop toast via notify-toast.ps1.
# macOS / Linux: no-op — the user relies on the PushNotification tool (Claude iOS app).
# The hook JSON on stdin is forwarded so the toast can use the message/cwd.

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    PS_SCRIPT="$HOME/.claude/hooks/notify-toast.ps1"
    # Convert the MSYS path (/c/Users/...) to a native Windows path for -File.
    command -v cygpath >/dev/null 2>&1 && PS_SCRIPT=$(cygpath -w "$PS_SCRIPT")
    exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$PS_SCRIPT"
    ;;
  *)
    exit 0
    ;;
esac
