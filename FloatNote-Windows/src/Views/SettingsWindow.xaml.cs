using System.Windows;
using FloatNote.Services;
using FloatNote.Utils;

namespace FloatNote.Views;

public partial class SettingsWindow : Window
{
    private readonly StorageManager _storage = StorageManager.Instance;

    public SettingsWindow()
    {
        InitializeComponent();
        Loaded += SettingsWindow_Loaded;
    }

    private void SettingsWindow_Loaded(object sender, RoutedEventArgs e)
    {
        Win32Helper.ApplyPowerToysTheme(this, useAcrylic: true);

        RadioDVR.IsChecked = _storage.Preferences.TargetNLE == "DaVinci Resolve";
        RadioPR.IsChecked = _storage.Preferences.TargetNLE == "Adobe Premiere Pro";
        CheckAutoMarkers.IsChecked = _storage.Preferences.AutoCreateMarkers;
        CheckAlwaysOnTop.IsChecked = _storage.Preferences.IsPinned;
    }

    private void Save_Click(object sender, RoutedEventArgs e)
    {
        _storage.Preferences.TargetNLE = RadioDVR.IsChecked == true ? "DaVinci Resolve" : "Adobe Premiere Pro";
        _storage.Preferences.AutoCreateMarkers = CheckAutoMarkers.IsChecked == true;
        _storage.Preferences.IsPinned = CheckAlwaysOnTop.IsChecked == true;
        _storage.SavePreferences();
        Close();
    }

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }
}
