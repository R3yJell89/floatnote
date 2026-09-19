using FloatNote.Models;

namespace FloatNote.Services;

/// <summary>
/// Localization helper — mirrors macOS L10n enum from UIComponents.swift.
/// Reads AppLanguage from StorageManager.Instance.Preferences at call time.
/// </summary>
public static class L10n
{
    private static bool IsEN => StorageManager.Instance.Preferences.AppLanguage == AppLanguage.EN;

    // Tab names
    public static string Tab_Checklist => IsEN ? "Checklist" : "Чеклист";
    public static string Tab_Notes     => IsEN ? "Notes"     : "Заметки";
    public static string Tab_Audio     => IsEN ? "Audio"     : "Аудио";
    public static string Tab_Sketch    => IsEN ? "Sketch"    : "Скетч";

    // Checklist input
    public static string Placeholder_NewTask =>
        IsEN ? "New task… (e.g. Cut intro 01:00:15:00)"
             : "Новая задача… (например: Срезать интро 01:00:15:00)";

    // Buttons
    public static string Btn_AddTask   => IsEN ? "Add task (Enter)"  : "Добавить задачу (Enter)";
    public static string Btn_Dictate   => IsEN ? "🎙 Dictation"      : "🎙 Диктовка";
    public static string Btn_Save      => IsEN ? "Save"              : "Сохранить";
    public static string Btn_Defaults  => IsEN ? "Defaults"          : "По умолчанию";

    // Settings headings
    public static string Settings_Title        => IsEN ? "FloatNote Settings" : "Настройки FloatNote";
    public static string Settings_Language     => IsEN ? "Language"           : "Языковые настройки";
    public static string Settings_Dictation    => IsEN ? "Dictation Language" : "Язык диктовки";
    public static string Settings_NLE          => IsEN ? "Video Editor (NLE)" : "Основной видеоредактор (NLE)";
    public static string Settings_Window       => IsEN ? "Window Behavior"    : "Поведение окна";
    public static string Settings_Hotkeys      => IsEN ? "Global Hotkeys"     : "Глобальные горячие клавиши";
    public static string Settings_AutoMarkers  =>
        IsEN ? "Auto-create marker in DaVinci when adding a task"
             : "Автосоздание маркера в DaVinci при добавлении задачи";
    public static string Settings_AlwaysOnTop  =>
        IsEN ? "Always on Top (pin window over all windows)"
             : "Закреплять окно поверх всех окон (Always on Top)";

    // Tooltips
    public static string Tip_Pin        => IsEN ? "Pin (Always on Top)" : "Закрепить (Always on Top)";
    public static string Tip_Timer      => IsEN ? "Edit Timer & Pomodoro" : "Таймер монтажа & Помодоро";
    public static string Tip_Clipboard  => IsEN ? "Clipboard History"    : "История буфера";
    public static string Tip_SafeAreas  => IsEN ? "Safe Areas 9:16 (Esc to close)" : "Безопасные зоны 9:16 (Esc для закрытия)";
    public static string Tip_Reference  => IsEN ? "Reference HUD"        : "Референс HUD";
    public static string Tip_Settings   => IsEN ? "Settings"             : "Настройки";
    public static string Tip_Minimize   => IsEN ? "Minimize"             : "Свернуть";
    public static string Tip_Close      => IsEN ? "Close"                : "Закрыть";
    public static string Tip_Timecode   => IsEN ? "Jump to timecode on timeline"  : "Перейти к таймкоду на таймлайне";
    public static string Tip_Marker     => IsEN ? "Add marker to DaVinci timeline" : "Поставить маркер на таймлайн DaVinci";
    public static string Tip_Delete     => IsEN ? "Delete task"          : "Удалить задачу";
}
