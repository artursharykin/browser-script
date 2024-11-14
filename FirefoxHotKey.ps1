# FORCE POWERSHELL TO RUN THESE
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0)

# Add required Windows API types
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Drawing;
using System.Threading;

public static class WinAPI {
    public const int WH_KEYBOARD_LL = 13;
    public const int WM_KEYDOWN = 0x0100;
    public const int DESKTOP_SWITCHDESKTOP = 0x100;
    public const int SW_SHOW = 5;
    public const int SW_RESTORE = 9;
    public const int SW_MAXIMIZE = 3;
    
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    
    [DllImport("user32.dll")]
    public static extern bool SetThreadDesktop(IntPtr hDesktop);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetThreadDesktop(uint dwThreadId);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr OpenInputDesktop(int flags, bool inherit, int desiredAccess);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr ProcessId);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    public delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
}

public class KeyboardHook : IDisposable {
    private IntPtr hookID = IntPtr.Zero;
    private WinAPI.LowLevelKeyboardProc proc;
    private bool winKeyPressed = false;
    private NotifyIcon trayIcon;
    private Thread desktopThread;
    private bool isRunning = true;

    public KeyboardHook() {
        proc = HookCallback;
        // Start a thread to periodically check desktop focus
        desktopThread = new Thread(new ThreadStart(DesktopFocusThread));
        desktopThread.IsBackground = true;
        desktopThread.Start();

        using (var curProcess = System.Diagnostics.Process.GetCurrentProcess())
        using (var curModule = curProcess.MainModule) {
            hookID = WinAPI.SetWindowsHookEx(WinAPI.WH_KEYBOARD_LL, proc,
                WinAPI.GetModuleHandle(curModule.ModuleName), 0);
        }

        InitializeTrayIcon();
        
        // Register for application exit
        Application.ApplicationExit += new EventHandler(OnApplicationExit);
    }

    private void OnApplicationExit(object sender, EventArgs e) {
        Dispose();
    }

    private void DesktopFocusThread() {
        while (isRunning) {
            try {
                IntPtr desktop = WinAPI.OpenInputDesktop(0, false, WinAPI.DESKTOP_SWITCHDESKTOP);
                if (desktop != IntPtr.Zero) {
                    uint threadId = WinAPI.GetCurrentThreadId();
                    WinAPI.SetThreadDesktop(desktop);
                }
            } catch { }
            Thread.Sleep(1000);
        }
    }

    private void InitializeTrayIcon() {
        trayIcon = new NotifyIcon();
        trayIcon.Text = "Firefox Hotkey (Win+B)";
        
        using (Bitmap bmp = new Bitmap(16, 16))
        using (Graphics g = Graphics.FromImage(bmp)) {
            g.Clear(Color.Transparent);
            g.DrawString("F", new Font("Arial", 10, FontStyle.Bold), Brushes.Orange, -2, -1);
            IntPtr hIcon = bmp.GetHicon();
            trayIcon.Icon = Icon.FromHandle(hIcon);
        }
        
        trayIcon.Visible = true;
        
        ContextMenuStrip menu = new ContextMenuStrip();
        menu.Items.Add("Exit", null, (sender, e) => {
            isRunning = false;
            Application.Exit();
        });
        trayIcon.ContextMenuStrip = menu;
    }

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam) {
        if (nCode >= 0 && wParam == (IntPtr)WinAPI.WM_KEYDOWN) {
            int vkCode = Marshal.ReadInt32(lParam);
            
            // Windows key (VK_LWIN = 0x5B, VK_RWIN = 0x5C)
            if (vkCode == 0x5B || vkCode == 0x5C) {
                winKeyPressed = true;
            }
            // B key (0x42) when Windows key is pressed
            else if (winKeyPressed && vkCode == 0x42) {
                ActivateOrStartFirefox();
                winKeyPressed = false;
            }
            else {
                winKeyPressed = false;
            }
        }
        return WinAPI.CallNextHookEx(hookID, nCode, wParam, lParam);
    }

    private void ActivateOrStartFirefox() {
        var processes = System.Diagnostics.Process.GetProcessesByName("firefox");
        if (processes.Length > 0) {
            foreach (var proc in processes) {
                if (proc.MainWindowHandle != IntPtr.Zero) {
                    ForceWindowToFront(proc.MainWindowHandle);
                    return;
                }
            }
        }

        try {
            System.Diagnostics.Process.Start("firefox.exe");
        } catch {
            string[] paths = {
                @"C:\Program Files\Mozilla Firefox\firefox.exe",
                @"C:\Program Files (x86)\Mozilla Firefox\firefox.exe"
            };
            foreach (string path in paths) {
                if (System.IO.File.Exists(path)) {
                    System.Diagnostics.Process.Start(path);
                    break;
                }
            }
        }
    }

    private void ForceWindowToFront(IntPtr windowHandle) {
        IntPtr currentForeground = WinAPI.GetForegroundWindow();
        uint currentThreadId = WinAPI.GetCurrentThreadId();
        uint foregroundThreadId = WinAPI.GetWindowThreadProcessId(currentForeground, IntPtr.Zero);
        uint windowThreadId = WinAPI.GetWindowThreadProcessId(windowHandle, IntPtr.Zero);

        // Attach threads
        bool attached = false;
        try {
            attached = WinAPI.AttachThreadInput(currentThreadId, foregroundThreadId, true);
            
            // Force window to restore if minimized
            WinAPI.ShowWindow(windowHandle, WinAPI.SW_RESTORE);
            
            // Force window activation
            WinAPI.SetForegroundWindow(windowHandle);
            WinAPI.BringWindowToTop(windowHandle);
            
            // Maximize the window
            WinAPI.ShowWindow(windowHandle, WinAPI.SW_MAXIMIZE);
        }
        finally {
            if (attached) {
                WinAPI.AttachThreadInput(currentThreadId, foregroundThreadId, false);
            }
        }
    }

    public void Dispose() {
        isRunning = false;
        
        if (desktopThread != null && desktopThread.IsAlive) {
            desktopThread.Join(1000); # sleepy time
        }
        
        if (hookID != IntPtr.Zero) {
            WinAPI.UnhookWindowsHookEx(hookID);
            hookID = IntPtr.Zero;
        }
        
        if (trayIcon != null) {
            trayIcon.Visible = false;
            trayIcon.Dispose();
            trayIcon = null;
        }
    }
}

# start program to run
public class Program {
    public static void Main() {
        Application.EnableVisualStyles();
        using (var hook = new KeyboardHook()) {
            Application.Run();
        }
    }
}
"@ -ReferencedAssemblies System.Windows.Forms, System.Drawing, System

# Start the application
[System.Windows.Forms.Application]::EnableVisualStyles()
$hook = New-Object KeyboardHook
[System.Windows.Forms.Application]::Run()
