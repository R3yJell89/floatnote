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

    public MainWindow()
    {
        InitializeComponent();
        Loaded += MainWindow_Loaded;
    }

    private void MainWindow_Loaded(object sender, RoutedEventArgs e)
    {
        // 1. Apply Windows 11 PowerToys Acrylic / Mica blur
        Win32Helper.ApplyPowerToysTheme(this, useAcrylic: true);

        // 2. Load preferences & window dimensions
        Width = _storage.Preferences.WindowWidth > 0 ? _storage.Preferences.WindowWidth : 380;
        Height = _storage.Preferences.WindowHeight > 0 ? _storage.Preferences.WindowHeight : 480;
        Topmost = _storage.Preferences.IsPinned;

        // 3. Load initial checklist and notes
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
        if (e.ButtonState == MouseButtonState.Pressed)
        {
            DragMove();
        }
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
        _storage.SaveAll();
        Application.Current.Shutdown();
    }

    private void OpenSettings_Click(object sender, RoutedEventArgs e)
    {
        var settingsWin = new SettingsWindow();
        settingsWin.Owner = this;
        settingsWin.ShowDialog();
    }

    private void Tab_Checked(object sender, RoutedEventArgs e)
    {
        if (sender is RadioButton rb)
        {
            bool isChecklist = rb == TabChecklist;
            bool isNotes = rb == TabNotes;

            if (ChecklistScrollViewer != null) ChecklistScrollViewer.Visibility = isChecklist ? Visibility.Visible : Visibility.Collapsed;
            if (NotesTextBox != null) NotesTextBox.Visibility = isNotes ? Visibility.Visible : Visibility.Collapsed;
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

        // Reverse marker creation on DaVinci Resolve
        if (!string.IsNullOrEmpty(timecode) && _storage.Preferences.AutoCreateMarkers)
        {
            NLEBridgeWindows.AddMarkerToNLE(timecode, cleanTitle, _storage.Preferences.TargetNLE);
        }
    }

    private void NewTaskInput_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter)
        {
            AddTask();
        }
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
