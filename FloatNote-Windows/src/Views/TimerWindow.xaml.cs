using System;
using System.Windows;
using System.Windows.Input;
using System.Windows.Threading;
using FloatNote.Utils;

namespace FloatNote.Views;

public partial class TimerWindow : Window
{
    private readonly DispatcherTimer _timer = new();
    private int _secondsRemaining = 25 * 60;
    private bool _isRunning = false;
    private bool _isPomodoro = true;

    public TimerWindow()
    {
        InitializeComponent();
        Loaded += (s, e) => Win32Helper.ApplyPowerToysTheme(this, useAcrylic: true);

        _timer.Interval = TimeSpan.FromSeconds(1);
        _timer.Tick += Timer_Tick;
    }

    private void Timer_Tick(object? sender, EventArgs e)
    {
        if (_isPomodoro)
        {
            if (_secondsRemaining > 0)
            {
                _secondsRemaining--;
                UpdateDigits();
            }
            else
            {
                _timer.Stop();
                _isRunning = false;
                PlayPauseButton.Content = "▶";
                System.Media.SystemSounds.Beep.Play();
            }
        }
        else
        {
            _secondsRemaining++;
            UpdateDigits();
        }
    }

    private void UpdateDigits()
    {
        int m = _secondsRemaining / 60;
        int s = _secondsRemaining % 60;
        TimerDigits.Text = $"{m:D2}:{s:D2}";
    }

    private void PlayPause_Click(object sender, RoutedEventArgs e)
    {
        _isRunning = !_isRunning;
        if (_isRunning) _timer.Start(); else _timer.Stop();
        PlayPauseButton.Content = _isRunning ? "⏸" : "▶";
    }

    private void Reset_Click(object sender, RoutedEventArgs e)
    {
        _timer.Stop();
        _isRunning = false;
        PlayPauseButton.Content = "▶";
        _secondsRemaining = _isPomodoro ? 25 * 60 : 0;
        UpdateDigits();
    }

    private void Mode_Click(object sender, RoutedEventArgs e)
    {
        _isPomodoro = !_isPomodoro;
        ModeButton.Content = _isPomodoro ? "Pomodoro" : "Секундомер";
        Reset_Click(sender, e);
    }

    private void Border_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed) DragMove();
    }

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        Hide();
    }
}
