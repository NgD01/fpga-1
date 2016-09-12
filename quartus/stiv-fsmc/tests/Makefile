# This makefile assumes a particular setup which reloads Mecrisp via a ",m"
# command in Vim. It'll only work on MacOS with the proper configuration,
# and while Mecrisp is connected and running in the front iTerm2 window.

run:
	osascript -e 'tell application "iTerm"' \
	-e 'write current session of current window text "include dev.fs"' \
	-e 'end tell'
