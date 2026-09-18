using System;
using System.Diagnostics;
using System.IO;
using System.Text.RegularExpressions;
using System.Windows;
using FloatNote.Utils;

namespace FloatNote.Services;

public static class NLEBridgeWindows
{
    private static readonly Regex BracketTimecodeRegex = new Regex(@"\[\d{2}:\d{2}:\d{2}(?::\d{2})?\]", RegexOptions.Compiled);
    private static readonly Regex PlainTimecodeRegex = new Regex(@"\b\d{2}:\d{2}:\d{2}(?::\d{2})?\b", RegexOptions.Compiled);

    public static string CleanMarkerTitle(string text)
    {
        string cleaned = BracketTimecodeRegex.Replace(text, "");
        cleaned = PlainTimecodeRegex.Replace(cleaned, "");
        cleaned = cleaned.Trim();
        return string.IsNullOrWhiteSpace(cleaned) ? "Правка" : cleaned;
    }

    public static void JumpToTimecode(string timecode, string targetNLE = "DaVinci Resolve")
    {
        Clipboard.SetText(timecode);

        if (targetNLE == "DaVinci Resolve")
        {
            RunDaVinciPythonScript($"jump_to_timecode('{timecode}')");
        }
        else if (targetNLE == "Adobe Premiere Pro")
        {
            // Focus Premiere Pro window via Win32 FindWindow / SetForegroundWindow
            FocusProcess("Adobe Premiere Pro");
        }
    }

    public static void AddMarkerToNLE(string timecode, string taskTitle, string targetNLE = "DaVinci Resolve")
    {
        if (targetNLE != "DaVinci Resolve") return;

        string cleanTitle = CleanMarkerTitle(taskTitle);
        string escapedTitle = cleanTitle.Replace("'", "\\'");
        string escapedNote = taskTitle.Replace("'", "\\'");

        string script = $@"
import DaVinciResolveScript as dvr
resolve = dvr.scriptapp('Resolve')
if resolve:
    pm = resolve.GetProjectManager()
    proj = pm.GetCurrentProject() if pm else None
    tl = proj.GetCurrentTimeline() if proj else None
    if tl:
        fps = float(tl.GetSetting('timelineFrameRate') or 24.0)
        # Parse timecode to frames
        parts = '{timecode}'.split(':')
        if len(parts) >= 3:
            h = int(parts[0])
            m = int(parts[1])
            s = int(parts[2])
            f = int(parts[3]) if len(parts) > 3 else 0
            frame = int((h * 3600 + m * 60 + s) * fps + f)
            tl.AddMarker(frame, 'Cyan', '{escapedTitle}', '{escapedNote}', 1)
";
        RunDaVinciPythonScript(script);
    }

    private static void RunDaVinciPythonScript(string pythonCode)
    {
        try
        {
            string tempFile = Path.Combine(Path.GetTempPath(), $"floatnote_dvr_{Guid.NewGuid():N}.py");
            File.WriteAllText(tempFile, pythonCode);

            var psi = new ProcessStartInfo
            {
                FileName = "python",
                Arguments = $"\"{tempFile}\"",
                CreateNoWindow = true,
                UseShellExecute = false
            };
            Process.Start(psi);
        }
        catch (Exception ex)
        {
            Debug.WriteLine($"DaVinci Bridge error: {ex.Message}");
        }
    }

    private static void FocusProcess(string processName)
    {
        var procs = Process.GetProcessesByName(processName);
        if (procs.Length > 0)
        {
            IntPtr hwnd = procs[0].MainWindowHandle;
            if (hwnd != IntPtr.Zero)
            {
                Win32Helper.SetWindowPos(hwnd, IntPtr.Zero, 0, 0, 0, 0, Win32Helper.SWP_NOMOVE | Win32Helper.SWP_NOSIZE | Win32Helper.SWP_SHOWWINDOW);
            }
        }
    }
}
