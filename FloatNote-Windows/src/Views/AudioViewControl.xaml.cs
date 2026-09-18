using System;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.Media;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using FloatNote.Models;
using FloatNote.Services;

namespace FloatNote.Views;

public partial class AudioViewControl : UserControl
{
    private readonly VoiceRecorderService _recorder = VoiceRecorderService.Instance;
    public ObservableCollection<VoiceNoteItem> VoiceNotes { get; } = new();

    public AudioViewControl()
    {
        InitializeComponent();
        VoiceNotesControl.ItemsSource = VoiceNotes;
    }

    private void Play440_Click(object sender, RoutedEventArgs e)
    {
        AudioToneGenerator.ToggleTone(440);
        UpdateToneButtonsUI();
    }

    private void Play1000_Click(object sender, RoutedEventArgs e)
    {
        AudioToneGenerator.ToggleTone(1000);
        UpdateToneButtonsUI();
    }

    private void Play2000_Click(object sender, RoutedEventArgs e)
    {
        AudioToneGenerator.ToggleTone(2000);
        UpdateToneButtonsUI();
    }

    private void StopTone_Click(object sender, RoutedEventArgs e)
    {
        AudioToneGenerator.StopTone();
        UpdateToneButtonsUI();
    }

    private void UpdateToneButtonsUI()
    {
        bool playing = AudioToneGenerator.IsPlaying;
        int? freq = AudioToneGenerator.CurrentPlayingFrequency;

        if (BtnTone440 != null)
            BtnTone440.Background = (playing && freq == 440) ? (System.Windows.Media.Brush)FindResource("AccentGreenBrush") : new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(0x20, 0xFF, 0xFF, 0xFF));

        if (BtnTone1000 != null)
            BtnTone1000.Background = (playing && freq == 1000) ? (System.Windows.Media.Brush)FindResource("AccentGreenBrush") : new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(0x35, 0xFF, 0xFF, 0xFF));

        if (BtnTone2000 != null)
            BtnTone2000.Background = (playing && freq == 2000) ? (System.Windows.Media.Brush)FindResource("AccentGreenBrush") : new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(0x20, 0xFF, 0xFF, 0xFF));
    }

    private void WavBorder_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        string wavPath = AudioToneGenerator.GenerateBeepWav(1000);
        var files = new StringCollection { wavPath };
        var data = new DataObject();
        data.SetFileDropList(files);
        DragDrop.DoDragDrop(this, data, DragDropEffects.Copy);
    }

    private async void RecordBtn_Click(object sender, RoutedEventArgs e)
    {
        if (!_recorder.IsRecording)
        {
            _recorder.StartRecording();
            RecordBtn.Content = "⏹ Остановить";
            StatusText.Text = "Идет запись голоса...";
        }
        else
        {
            StatusText.Text = "Сохранение и распознавание...";
            string? savedFile = _recorder.StopRecording();
            RecordBtn.Content = "🔴 Начать запись";

            if (!string.IsNullOrEmpty(savedFile))
            {
                string transcript = await SpeechRecognitionService.TranscribeWavAsync(savedFile);
                var item = new VoiceNoteItem
                {
                    FilePath = savedFile,
                    Transcript = transcript
                };
                VoiceNotes.Insert(0, item);
                StatusText.Text = "Готово!";
            }
            else
            {
                StatusText.Text = "";
            }
        }
    }

    private void OpenWindowsSoundRecorder_Click(object sender, RoutedEventArgs e)
    {
        VoiceRecorderService.LaunchWindowsSoundRecorder();
    }

    private void PlayVoice_Click(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is VoiceNoteItem item)
        {
            try
            {
                using var player = new SoundPlayer(item.FilePath);
                player.Play();
            }
            catch { }
        }
    }

    private void CopyTranscript_Click(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is VoiceNoteItem item)
        {
            Clipboard.SetText(item.Transcript);
        }
    }
}
