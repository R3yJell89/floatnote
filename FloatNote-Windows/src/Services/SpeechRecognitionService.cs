using System;
using System.Diagnostics;
using System.IO;
using System.Threading.Tasks;

namespace FloatNote.Services;

public static class SpeechRecognitionService
{
    /// <summary>
    /// Transcribes a WAV file using Windows Speech Recognition (System.Speech).
    /// </summary>
    /// <param name="wavFilePath">Path to the WAV file.</param>
    /// <param name="locale">BCP-47 locale, e.g. "ru-RU" or "en-US". Defaults to "ru-RU".</param>
    public static async Task<string> TranscribeWavAsync(string wavFilePath, string locale = "ru-RU")
    {
        return await Task.Run(() =>
        {
            try
            {
                // Use System.Speech PowerShell interop — lightweight, no extra DLLs required
                string safePath = wavFilePath.Replace("'", "''");
                string script = $@"
Add-Type -AssemblyName System.Speech
$culture = [System.Globalization.CultureInfo]::GetCultureInfo('{locale}')
$recognizer = New-Object System.Speech.Recognition.SpeechRecognitionEngine $culture
$grammar = New-Object System.Speech.Recognition.DictationGrammar
$recognizer.LoadGrammar($grammar)
$recognizer.SetInputToWaveFile('{safePath}')
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

                    if (!string.IsNullOrEmpty(output)) return output;
                }
            }
            catch (Exception ex)
            {
                Debug.WriteLine($"Speech recognition error: {ex.Message}");
            }

            // Fallback label depends on locale
            return locale.StartsWith("en") ? "(Voice note — no text recognized)" : "(Голосовая заметка без распознанного текста)";
        });
    }
}
