using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;

namespace FloatNote.Models;

public class ChecklistItem : INotifyPropertyChanged
{
    private string _id = Guid.NewGuid().ToString();
    private string _title = string.Empty;
    private bool _isCompleted = false;
    private string? _timecode;
    private double _createdAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

    [JsonPropertyName("id")]
    public string Id
    {
        get => _id;
        set { _id = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("title")]
    public string Title
    {
        get => _title;
        set { _title = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("isCompleted")]
    public bool IsCompleted
    {
        get => _isCompleted;
        set { _isCompleted = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("timecode")]
    public string? Timecode
    {
        get => _timecode;
        set { _timecode = value; OnPropertyChanged(); }
    }

    [JsonPropertyName("createdAt")]
    public double CreatedAt
    {
        get => _createdAt;
        set { _createdAt = value; OnPropertyChanged(); }
    }

    public event PropertyChangedEventHandler? PropertyChanged;
    protected void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }

    private static readonly Regex TimecodeRegex = new Regex(@"\b(\d{2}:\d{2}:\d{2}(?::\d{2})?)\b", RegexOptions.Compiled);

    public static (string CleanTitle, string? ExtractedTimecode) ParseInput(string input)
    {
        var match = TimecodeRegex.Match(input);
        if (match.Success)
        {
            string tc = match.Value;
            string clean = input.Replace($"[{tc}]", "").Replace(tc, "").Trim();
            return (clean, tc);
        }
        return (input.Trim(), null);
    }
}
