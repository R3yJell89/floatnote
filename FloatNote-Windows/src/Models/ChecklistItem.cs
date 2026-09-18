using System;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;

namespace FloatNote.Models;

public class ChecklistItem
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("isCompleted")]
    public bool IsCompleted { get; set; } = false;

    [JsonPropertyName("timecode")]
    public string? Timecode { get; set; }

    [JsonPropertyName("createdAt")]
    public double CreatedAt { get; set; } = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

    // Auto-detect HH:MM:SS:FF or HH:MM:SS format
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
