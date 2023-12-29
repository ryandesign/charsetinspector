#!/usr/bin/osascript

# SPDX-FileCopyrightText: © 2023 Ryan Carsten Schmidt <https://github.com/ryandesign>
# SPDX-License-Identifier: MIT

on run argv
	tell application "OpenEmulator" to activate
	do shell script "open -a OpenEmulator " & quoted form of (item 1 of argv)
	tell application "System Events" to key code 51 using {command down, control down}
end run
