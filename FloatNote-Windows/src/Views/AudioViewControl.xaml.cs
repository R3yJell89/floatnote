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

    private void Play440_Click(object sender, RoutedEventArgs e) => AudioToneGenerator.PlayTone(440);
    private void Play1000_Click(object sender, RoutedEventArgs e) => AudioToneGenerator.PlayTone(1000);
    private void Play2000_Click(object sender, RoutedEventArgs e) => AudioToneGenerator.PlayTone(2000);
    private void StopTone_Click(object sender, RoutedEventArgs e) => AudioToneGenerator.StopTone();

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
