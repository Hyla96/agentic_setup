#!/bin/bash
NOTIFIER="/opt/homebrew/bin/terminal-notifier"

focused=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)

if [ "$focused" != "ghostty" ]; then
  "$NOTIFIER" -message "Claude needs your attention" -title "Claude Code" -sound pop
  exit 0
fi

if [ -n "$TMUX" ]; then
  pane_active=$(tmux display-message -t "$TMUX_PANE" -p '#{window_active}#{pane_active}' 2>/dev/null)
if [ "$pane_active" != "11" ]; then
    "$NOTIFIER" -message "Claude needs your attention" -title "Claude Code" -sound pop
  fi
fi
