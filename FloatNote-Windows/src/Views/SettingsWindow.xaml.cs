using System.Windows;
using FloatNote.Models;
using FloatNote.Services;
using FloatNote.Utils;

namespace FloatNote.Views;

public partial class SettingsWindow : Window
{
    private readonly StorageManager _storage = StorageManager.Instance;

    public SettingsWindow()
    {
        InitializeComponent();
    }

    // ─── Load: synchronize controls with current Preferences ─────────────────

    private void SettingsWindow_Loaded(object sender, RoutedEventArgs e)
    {
        Win32Helper.ApplyPowerToysTheme(this, useAcrylic: true);

        var prefs = _storage.Preferences;

        // Language
        RadioLangRU.IsChecked = prefs.AppLanguage == AppLanguage.RU;
        RadioLangEN.IsChecked = prefs.AppLanguage == AppLanguage.EN;

        // Dictation
        RadioDictRU.IsChecked = prefs.DictationLanguage == "ru-RU";
        RadioDictEN.IsChecked = prefs.DictationLanguage == "en-US";

        // NLE
        RadioDVR.IsChecked = prefs.TargetNLE == "DaVinci Resolve";
        RadioPR.IsChecked  = prefs.TargetNLE == "Premiere Pro";

        // Auto markers
        CheckAutoMarkers.IsChecked = prefs.AutoCreateMarkers;

        // Always on top
        CheckAlwaysOnTop.IsChecked = prefs.IsPinned;

        // Localize UI
        RefreshLabels();
    }

    private void RefreshLabels()
    {
        SettingsTitleText.Text  = L10n.Settings_Title;
        LangCardTitle.Text      = L10n.Settings_Language;
        LangDictLabel.Text      = L10n.Settings_Dictation;
        NLECardTitle.Text       = L10n.Settings_NLE;
        WindowCardTitle.Text    = L10n.Settings_Window;
        HotkeysCardTitle.Text   = L10n.Settings_Hotkeys;
        AutoMarkersLabel.Text   = L10n.Settings_AutoMarkers;
        AlwaysOnTopLabel.Text   = L10n.Settings_AlwaysOnTop;
        SaveButton.Content      = L10n.Btn_Save;

        bool isEN = _storage.Preferences.AppLanguage == AppLanguage.EN;
        LangInterfaceLabel.Text = isEN ? "Interface language:" : "Язык интерфейса:";
        HkWinLabel.Text         = isEN ? "Show / hide window:" : "Показать / скрыть окно:";
        HkGhostLabel.Text       = isEN ? "Click-through (Ghost Mode):" : "Сквозной клик (Ghost Mode):";
    }

    // ─── Save: write all controls back to Preferences ────────────────────────

    private void Save_Click(object sender, RoutedEventArgs e)
    {
        var prefs = _storage.Preferences;

        // Language
        if (RadioLangRU.IsChecked == true)
            prefs.AppLanguage = AppLanguage.RU;
        else if (RadioLangEN.IsChecked == true)
            prefs.AppLanguage = AppLanguage.EN;

        // Dictation
        if (RadioDictRU.IsChecked == true)
            prefs.DictationLanguage = "ru-RU";
        else if (RadioDictEN.IsChecked == true)
            prefs.DictationLanguage = "en-US";

        // NLE
        if (RadioDVR.IsChecked == true)
            prefs.TargetNLE = "DaVinci Resolve";
        else if (RadioPR.IsChecked == true)
            prefs.TargetNLE = "Premiere Pro";

        // Other
        prefs.AutoCreateMarkers = CheckAutoMarkers.IsChecked == true;
        prefs.IsPinned          = CheckAlwaysOnTop.IsChecked == true;

        _storage.SavePreferences();

        // Apply always-on-top to main window immediately
        if (Owner is Window main)
        {
            main.Topmost = prefs.IsPinned;
            Win32Helper.SetAlwaysOnTop(main, prefs.IsPinned);
        }

        Close();
    }

    private void Close_Click(object sender, RoutedEventArgs e) => Close();
}
