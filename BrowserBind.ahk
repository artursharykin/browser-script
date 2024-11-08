#SingleInstance Force
#Warn

#b:: {
    ;Does window exist?

    if (firefoxWindow := WinExist("ahk_exe firefox.exe")) {
        ;If minimized, maximimze it
        if (WinGetMinMax("ahk_id " firefoxWindow) = -1)
            WinRestore("ahk_id " firefoxWindow)
        
        ;Bring window to front
        WinActivate("ahk_id " firefoxWindow)
        WinShow("ahk_id " firefoxWindow)
    }
    else {
        ;If firefox isn't running, spawn the process
        try {
            Run "firefox.exe"
        }
        catch {
            ;Try common installation paths if not in PATH
            if FileExist("C:\Program Files\Mozilla Firefox\firefox.exe")
                Run "C:\Program Files\Mozilla Firefox\firefox.exe"
            else if FileExist("C:\Program Files (x86)\Mozilla Firefox\firefox.exe")
                Run "C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
            else
                MsgBox "Firefox not found. Is it installed?"
        }
    }
}
