using System.Text.Json.Serialization;

namespace FloatNote.Models;

public enum AppLanguage
{
    RU,
    EN
}

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

    [JsonPropertyName("appLanguage")]
    [JsonConverter(typeof(JsonStringEnumConverter))]
    public AppLanguage AppLanguage { get; set; } = AppLanguage.RU;

    [JsonPropertyName("dictationLanguage")]
    public string DictationLanguage { get; set; } = "ru-RU";
}
