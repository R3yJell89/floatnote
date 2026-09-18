using System;
using System.Linq;
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

        Width = _storage.Preferences.WindowWidth > 0 ? _storage.Preferences.WindowWidth : 380;
        Height = _storage.Preferences.WindowHeight > 0 ? _storage.Preferences.WindowHeight : 480;
        Topmost = _storage.Preferences.IsPinned;

        RefreshChecklist();
        NotesTextBox.Text = _storage.NotesText;
    }

    private void RefreshChecklist()
    {
        ChecklistItemsControl.ItemsSource = null;
        ChecklistItemsControl.ItemsSource = _storage.Checklist;
    }

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

    private void Minimize_Click(object sender, RoutedEventArgs e)
    {
        WindowState = WindowState.Minimized;
    }

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        _storage.SaveChecklist();
        _storage.SavePreferences();
        Application.Current.Shutdown();
    }

    private void OpenSettings_Click(object sender, RoutedEventArgs e)
    {
        var settingsWin = new SettingsWindow();
        settingsWin.Owner = this;
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

    private void Tab_Checked(object sender, RoutedEventArgs e)
    {
        if (sender is RadioButton rb)
        {
            bool isChecklist = rb == TabChecklist;
            bool isNotes = rb == TabNotes;
            bool isAudio = rb == TabAudio;
            bool isSketch = rb == TabSketch;

            if (ChecklistScrollViewer != null) ChecklistScrollViewer.Visibility = isChecklist ? Visibility.Visible : Visibility.Collapsed;
            if (BottomInputBar != null) BottomInputBar.Visibility = isChecklist ? Visibility.Visible : Visibility.Collapsed;
            if (NotesTextBox != null) NotesTextBox.Visibility = isNotes ? Visibility.Visible : Visibility.Collapsed;
            if (AudioControl != null) AudioControl.Visibility = isAudio ? Visibility.Visible : Visibility.Collapsed;
            if (SketchControl != null) SketchControl.Visibility = isSketch ? Visibility.Visible : Visibility.Collapsed;
        }
    }

    private void AddTask()
    {
        string text = NewTaskInput.Text.Trim();
        if (string.IsNullOrEmpty(text)) return;

        var (cleanTitle, timecode) = ChecklistItem.ParseInput(text);
        var item = new ChecklistItem
        {
            Title = cleanTitle,
            Timecode = timecode
        };

        _storage.Checklist.Add(item);
        _storage.SaveChecklist();
        RefreshChecklist();
        NewTaskInput.Clear();

        if (!string.IsNullOrEmpty(timecode) && _storage.Preferences.AutoCreateMarkers)
        {
            NLEBridgeWindows.AddMarkerToNLE(timecode, cleanTitle, _storage.Preferences.TargetNLE);
        }
    }

    private void NewTaskInput_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter) AddTask();
    }

    private void AddTaskButton_Click(object sender, RoutedEventArgs e)
    {
        AddTask();
    }

    private void Timecode_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.Content is string tc && !string.IsNullOrEmpty(tc))
        {
            NLEBridgeWindows.JumpToTimecode(tc, _storage.Preferences.TargetNLE);
        }
    }

    private void AddMarker_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button btn && btn.DataContext is ChecklistItem item && !string.IsNullOrEmpty(item.Timecode))
        {
            NLEBridgeWindows.AddMarkerToNLE(item.Timecode, item.Title, _storage.Preferences.TargetNLE);
        }
    }

    private void TaskCheck_Changed(object sender, RoutedEventArgs e)
    {
        _storage.SaveChecklist();
    }

    private void NotesTextBox_TextChanged(object sender, TextChangedEventArgs e)
    {
        _storage.SaveNotes(NotesTextBox.Text);
    }
}
