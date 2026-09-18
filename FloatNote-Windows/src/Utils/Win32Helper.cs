using System;
using System.Runtime.InteropServices;
using System.Windows;
using System.Windows.Interop;

namespace FloatNote.Utils;

public static class Win32Helper
{
    public const int WS_EX_TOPMOST = 0x00000008;
    public const int WS_EX_TRANSPARENT = 0x00000020;
    public const int WS_EX_LAYERED = 0x00080000;
    public const int WS_EX_NOACTIVATE = 0x08000000;
    public const int GWL_EXSTYLE = -20;

    public static readonly IntPtr HWND_TOPMOST = new IntPtr(-1);
    public static readonly IntPtr HWND_NOTOPMOST = new IntPtr(-2);

    public const uint SWP_NOSIZE = 0x0001;
    public const uint SWP_NOMOVE = 0x0002;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_SHOWWINDOW = 0x0040;

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowLong(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    // Windows 11 DWM Backdrop Effects (Mica & Acrylic)
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    public const int DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
    public const int DWMWA_SYSTEMBACKDROP_TYPE = 38;
    public const int DWMWA_CORNER_PREFERENCE = 33;

    public enum DWM_SYSTEMBACKDROP_TYPE
    {
        Auto = 0,
        None = 1,
        MainWindow = 2, // Mica
        TransientWindow = 3, // Acrylic
        TabbedWindow = 4 // Mica Alt
    }

    public static void ApplyPowerToysTheme(Window window, bool useAcrylic = true)
    {
        var helper = new WindowInteropHelper(window);
        IntPtr hwnd = helper.EnsureHandle();

        // 1. Enable Immersive Dark Mode
        int darkMode = 1;
        DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, ref darkMode, sizeof(int));

        // 2. Windows 11 Rounded Corners (DWMWCP_ROUND = 2)
        int cornerPref = 2;
        DwmSetWindowAttribute(hwnd, DWMWA_CORNER_PREFERENCE, ref cornerPref, sizeof(int));

        // 3. System Backdrop (Acrylic or Mica)
        int backdrop = useAcrylic ? (int)DWM_SYSTEMBACKDROP_TYPE.TransientWindow : (int)DWM_SYSTEMBACKDROP_TYPE.MainWindow;
        DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE, ref backdrop, sizeof(int));
    }

    public static void SetClickThrough(Window window, bool enable)
    {
        var helper = new WindowInteropHelper(window);
        IntPtr hwnd = helper.Handle;
        int currentStyle = GetWindowLong(hwnd, GWL_EXSTYLE);

        if (enable)
        {
            SetWindowLong(hwnd, GWL_EXSTYLE, currentStyle | WS_EX_TRANSPARENT | WS_EX_LAYERED);
        }
        else
        {
            SetWindowLong(hwnd, GWL_EXSTYLE, currentStyle & ~WS_EX_TRANSPARENT);
        }
    }

    public static void SetAlwaysOnTop(Window window, bool topMost)
    {
        var helper = new WindowInteropHelper(window);
        IntPtr hwnd = helper.Handle;
        SetWindowPos(hwnd, topMost ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);
    }
}
