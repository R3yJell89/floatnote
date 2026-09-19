using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using FloatNote.Models;
using FloatNote.Services;
using FloatNote.Utils;

namespace FloatNote.Views;

public partial class MainWindow : Window
{
    private readonly StorageManager _storage = StorageManager.Instance;
    private TimerWindow? _timerWindow;
    private ClipboardWindow? _clipboardWindow;
    private SafeAreasWindow? _safeAreasWindow;
    private ReferenceWindow? _referenceWindow;

    public MainWindow()
    {
        InitializeComponent();
        Loaded += MainWindow_Loaded;
    }

    private void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        Win32Helper.ApplyPowerToysTheme(this, useAcrylic: true);

        Width  = _storage.Preferences.WindowWidth  > 0 ? _storage.Preferences.WindowWidth  : 380;
        Height = _storage.Preferences.WindowHeight > 0 ? _storage.Preferences.WindowHeight : 480;
        Topmost = _storage.Preferences.IsPinned;

        ChecklistItemsControl.ItemsSource = _storage.Checklist;
        NotesTextBox.Text = _storage.NotesText;

        RefreshUI();
    }

    // ─── Language ────────────────────────────────────────────────────────────

    private void LangRu_Click(object sender, RoutedEventArgs e)
    {
        _storage.Preferences.AppLanguage = AppLanguage.RU;
        _storage.SavePreferences();
        RefreshUI();
    }

    private void LangEn_Click(object sender, RoutedEventArgs e)
    {
        _storage.Preferences.AppLanguage = AppLanguage.EN;
        _storage.SavePreferences();
        RefreshUI();
    }

    /// <summary>Updates all localizable strings in MainWindow without restart.</summary>
    private void RefreshUI()
    {
        bool isEN = _storage.Preferences.AppLanguage == AppLanguage.EN;

        // Tab labels
        TabChecklistText.Text = L10n.Tab_Checklist;
        TabNotesText.Text     = L10n.Tab_Notes;
        TabAudioText.Text     = L10n.Tab_Audio;
        TabSketchText.Text    = L10n.Tab_Sketch;

        // Placeholder
        PlaceholderText.Text = L10n.Placeholder_NewTask;

        // Language badge highlight
        LangRuText.Foreground = isEN
            ? (System.Windows.Media.Brush)FindResource("TextSecondaryBrush")
            : (System.Windows.Media.Brush)FindResource("AccentGreenBrush");
        LangEnText.Foreground = isEN
            ? (System.Windows.Media.Brush)FindResource("AccentGreenBrush")
            : (System.Windows.Media.Brush)FindResource("TextSecondaryBrush");

        // Tooltips
        PinButton.ToolTip        = L10n.Tip_Pin;
        PlaceholderText.Text     = L10n.Placeholder_NewTask;
    }

    // ─── Window Chrome ────────────────────────────────────────────────────────

    private void TitleBar_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed) DragMove();
    }

    private void PinButton_Click(object sender, RoutedEventArgs e)
    {
        _storage.Preferences.IsPinned = !_storage.Preferences.IsPinned;
        Topmost = _storage.Preferences.IsPinned;
        Win32Helper.SetAlwaysOnTop(this, _storage.Preferences.IsPinned);
        _storage.SavePreferences();
    }

    private void Minimize_Click(object sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        _storage.SaveChecklist();
        _storage.SavePreferences();
        Application.Current.Shutdown();
    }

    // ─── Companion windows ────────────────────────────────────────────────────

    private void OpenSettings_Click(object sender, RoutedEventArgs e)
    {
        var settingsWin = new SettingsWindow();
        settingsWin.Owner = this;
        settingsWin.Closed += (_, _) => RefreshUI(); // refresh language after settings saved
        settingsWin.ShowDialog();
    }

    private void ToggleTimer_Click(object sender, RoutedEventArgs e)
    {
        _timerWindow ??= new TimerWindow();
        if (_timerWindow.IsVisible) _timerWindow.Hide(); else _timerWindow.Show();
    }

    private void ToggleClipboard_Click(object sender, RoutedEventArgs e)
    {
        _clipboardWindow ??= new ClipboardWindow();
        if (_clipboardWindow.IsVisible) _clipboardWindow.Hide(); else _clipboardWindow.Show();
    }

    private void ToggleSafeAreas_Click(object sender, RoutedEventArgs e)
    {
        _safeAreasWindow ??= new SafeAreasWindow();
        if (_safeAreasWindow.IsVisible) _safeAreasWindow.Hide(); else _safeAreasWindow.Show();
    }

    private void ToggleReference_Click(object sender, RoutedEventArgs e)
    {
        _referenceWindow ??= new ReferenceWindow();
        if (_referenceWindow.IsVisible) _referenceWindow.Hide(); else _referenceWindow.Show();
    }

    // ─── Tabs ─────────────────────────────────────────────────────────────────

    private void Tab_Checked(object sender, RoutedEventArgs e)
    {
        if (sender is RadioButton rb)
        {
            bool isChecklist = rb == TabChecklist;
            bool isNotes     = rb == TabNotes;
            bool isAudio     = rb == TabAudio;
            bool isSketch    = rb == TabSketch;

            if (ChecklistScrollViewer != null) ChecklistScrollViewer.Visibility = isChecklist ? Visibility.Visible : Visibility.Collapsed;
            if (BottomInputBar      != null) BottomInputBar.Visibility      = isChecklist ? Visibility.Visible : Visibility.Collapsed;
            if (NotesTextBox        != null) NotesTextBox.Visibility        = isNotes     ? Visibility.Visible : Visibility.Collapsed;
            if (AudioControl        != null) AudioControl.Visibility        = isAudio     ? Visibility.Visible : Visibility.Collapsed;
            if (SketchControl       != null) SketchControl.Visibility       = isSketch    ? Visibility.Visible : Visibility.Collapsed;
        }
    }

    // ─── Checklist ────────────────────────────────────────────────────────────

    private void AddTask()
    {
        try
        {
            string text = NewTaskInput.Text.Trim();
            if (string.IsNullOrEmpty(text)) return;

            var (cleanTitle, timecode) = ChecklistItem.ParseInput(text);
            var item = new ChecklistItem { Title = cleanTitle, Timecode = timecode };

            _storage.Checklist.Add(item);
            _storage.SaveChecklist();
            NewTaskInput.Clear();
            NewTaskInput.Focus();

            if (!string.IsNullOrEmpty(timecode) && _storage.Preferences.AutoCreateMarkers)
            {
                try { NLEBridgeWindows.AddMarkerToNLE(timecode, cleanTitle, _storage.Preferences.TargetNLE); }
                catch { }
            }
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"AddTask error: {ex.Message}");
        }
    }

    private void NewTaskInput_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (PlaceholderText != null)
            PlaceholderText.Visibility = string.IsNullOrEmpty(NewTaskInput.Text) ? Visibility.Visible : Visibility.Collapsed;
    }

    private void NewTaskInput_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter) AddTask();
    }

    private void AddTaskButton_Click(object sender, RoutedEventArgs e) => AddTask();

    private void Timecode_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Content is string tc && !string.IsNullOrEmpty(tc))
            NLEBridgeWindows.JumpToTimecode(tc, _storage.Preferences.TargetNLE);
    }

    private void AddMarker_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.DataContext is ChecklistItem item && !string.IsNullOrEmpty(item.Timecode))
            NLEBridgeWindows.AddMarkerToNLE(item.Timecode, item.Title, _storage.Preferences.TargetNLE);
    }

    private void DeleteTask_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.DataContext is ChecklistItem item)
        {
            _storage.Checklist.Remove(item);
            _storage.SaveChecklist();
        }
    }

    private void TaskCheck_Click(object sender, RoutedEventArgs e) => _storage.SaveChecklist();

    private void NotesTextBox_TextChanged(object sender, TextChangedEventArgs e) => _storage.SaveNotes(NotesTextBox.Text);
}
