using System.Text.Json.Serialization;

namespace FloatNote.Models;

public class UserPreferences
{
    [JsonPropertyName("isPinned")]
    public bool IsPinned { get; set; } = true;

    [JsonPropertyName("isClickThrough")]
    public bool IsClickThrough { get; set; } = false;

    [JsonPropertyName("opacity")]
    public double Opacity { get; set; } = 1.0;

    [JsonPropertyName("fontSize")]
    public double FontSize { get; set; } = 13.0;

    [JsonPropertyName("selectedTab")]
    public int SelectedTab { get; set; } = 0;

    [JsonPropertyName("targetNLE")]
    public string TargetNLE { get; set; } = "DaVinci Resolve";

    [JsonPropertyName("autoCreateMarkers")]
    public bool AutoCreateMarkers { get; set; } = true;

    [JsonPropertyName("windowWidth")]
    public double WindowWidth { get; set; } = 380;

    [JsonPropertyName("windowHeight")]
    public double WindowHeight { get; set; } = 480;
}
