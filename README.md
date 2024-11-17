# browser-script
Ever since I picked up VIM and realized how efficient it felt, I looked at ways to optimize my Windows usage, I disliked having to hold Alt+Tab to get to my Firefox window, or even worse- having to move my hand to the mouse and selecting Firefox on the taskbar, so I made this script: compatible with Chrome, Firefox, and Edge, with their default or custom install locations. One of the benefits this scripts has over the "Shortcut Key" option in a Windows Shortcut properties is this script checks if you're already running the process & pulls it up to the foreground.

## Compatibility
In order to change what browser the script uses, change the BrowserType variable at the beginning of the script to your favourite browser.

The AutoHotKey script is NOT compatible with AutoHotKey v1.x.x, its only compatible with AutoHotKey v2.

The Powershell script should run without additional packages, but it might need to be ran in Administrator mode the first time or ask you to accept the use of packages with this script.

## How to Use

### Auto Hot Key
Download the script and run it, in order to bring up the browser, press **Win+B** in order to start or switch to your browser.

### Powershell
Download the script and run it.

## To have it run on Start up
Currently working on a .bat wrapper for this to ensure it starts up properly.

