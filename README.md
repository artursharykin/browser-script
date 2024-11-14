# browser-script
I found myself a little frustrated holding ALT+TAB any going through all my running apps to get to Firefox when working on a lot of stuff, so I made this script to make my life easier. One of the benefits this scripts has over the "Shortcut Key" option in a Windows Shortcut properties is this script checks if you're already running the process & pulls it up.

## Compatibility
The AutoHotKey script is NOT compatible with AutoHotKey v1.x.x, its only compatible with AutoHotKey v2.

The Powershell script should run without additional packages, but it might need to be ran in Administrator mode the first time.

## How to Use

### Auto Hot Key
Download the script and run it, in order to bring up the browser, press **WIN KEY + B** in order to start or switch to the Firefox browser.

If you use Google Chrome (or any other browser), just search and replace all mentions of Mozilla & Firefox.exe to Google & Google Chrome.

### Powershell
Download the script and the linked vbs file, currently, Chrome & Edge versions need to be manually designed by searching and replacing all mentions of Firefox with Chrome/Edge.
The script and vbs file should be stored in the same directory.

## To have it run on Start up
The PowerShell version script automatically does this, but might not properly startup based on what default "Open with" configuration you have for .ps1 extensions.
1. Press WIN KEY + R
2. In run command window, type shell:startup
3. Move the file into the newly opened "Programs\Startup" explorer window

