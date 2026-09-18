using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;

namespace FloatNote.Services;

public static class SpeechRecognitionService
{
    // Transcribes audio on Windows using Windows.Media.SpeechRecognition via lightweight PowerShell Windows Runtime interop
    public static async Task<string> TranscribeWavAsync(string wavFilePath)
    {
        return await Task.Run(() =>
        {
            try
            {
                string script = $@"
Add-Type -AssemblyName System.Speech
$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine
$grammar = New-Object System.Speech.Recognition.DictationGrammar
$recognizer.LoadGrammar($grammar)
$recognizer.SetInputToWaveFile('{wavFilePath.Replace("'", "''")}')
$result = $recognizer.Recognize([TimeSpan]::FromSeconds(30))
if ($result) {{
    Write-Output $result.Text
}} else {{
    Write-Output ''
}}
";
                var psi = new ProcessStartInfo
                {
                    FileName = "powershell.exe",
                    Arguments = $"-NoProfile -ExecutionPolicy Bypass -Command \"{script.Replace("\r\n", " ")}\"",
                    RedirectStandardOutput = true,
                    CreateNoWindow = true,
                    UseShellExecute = false
                };

                using var process = Process.Start(psi);
                if (process != null)
                {
                    string output = process.StandardOutput.ReadToEnd().Trim();
                    process.WaitForExit();
                    return string.IsNullOrEmpty(output) ? "(Голосовая заметка без распознанного текста)" : output;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Speech recognition error: {ex.Message}");
            }

            return "(Аудиозапись сохранена)";
        });
    }
}
