using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;

namespace FloatNote.Services;

public class VoiceRecorderService
{
    private static readonly Lazy<VoiceRecorderService> _instance = new(() => new VoiceRecorderService());
    public static VoiceRecorderService Instance => _instance.Value;

    [DllImport("winmm.dll", EntryPoint = "mciSendStringA", ExactSpelling = true, CharSet = CharSet.Ansi, SetLastError = true)]
    private static extern int mciSendString(string lpstrCommand, string? lpstrReturnString, int uReturnLength, int hwndCallback);

    public bool IsRecording { get; private set; } = false;
    private string _currentFilePath = string.Empty;

    public string RecordingsDirectory { get; }

    private VoiceRecorderService()
    {
        string docs = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
        RecordingsDirectory = Path.Combine(docs, "FloatNote_Audio", "VoiceNotes");
        Directory.CreateDirectory(RecordingsDirectory);
    }

    public void StartRecording()
    {
        if (IsRecording) return;

        string fileName = $"Voice_{DateTime.Now:yyyyMMdd_HHmmss}.wav";
        _currentFilePath = Path.Combine(RecordingsDirectory, fileName);

        // Native Windows MCI 16-bit 44.1kHz stereo audio recording (built into Windows, no extra DLLs)
        mciSendString("open new type waveaudio alias voice_rec", null, 0, 0);
        mciSendString("set voice_rec time format ms bitspersample 16 channels 1 samplespersec 44100", null, 0, 0);
        mciSendString("record voice_rec", null, 0, 0);

        IsRecording = true;
    }

    public string? StopRecording()
    {
        if (!IsRecording) return null;

        mciSendString($"save voice_rec \"{_currentFilePath}\"", null, 0, 0);
        mciSendString("close voice_rec", null, 0, 0);

        IsRecording = false;
        return File.Exists(_currentFilePath) ? _currentFilePath : null;
    }

    // Windows native Sound Recorder launcher (ms-soundrecorder protocol)
    public static void LaunchWindowsSoundRecorder()
    {
        try
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "ms-soundrecorder:",
                UseShellExecute = true
            });
        }
        catch
        {
            try
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "explorer.exe",
                    Arguments = "shell:appsFolder\\Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe!App",
                    UseShellExecute = true
                });
            }
            catch { }
        }
    }
}
