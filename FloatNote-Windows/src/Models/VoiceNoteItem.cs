using System;
using System.IO;

namespace FloatNote.Models;

public class VoiceNoteItem
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string FilePath { get; set; } = string.Empty;
    public string FileName => Path.GetFileName(FilePath);
    public string Transcript { get; set; } = string.Empty;
    public string TimeFormatted { get; set; } = DateTime.Now.ToString("HH:mm:ss");
}
