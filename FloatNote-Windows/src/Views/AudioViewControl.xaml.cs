using System.Collections.Specialized;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using FloatNote.Services;

namespace FloatNote.Views;

public partial class AudioViewControl : UserControl
{
    public AudioViewControl()
    {
        InitializeComponent();
    }

    private void Play440_Click(object sender, RoutedEventArgs e)
    {
        AudioToneGenerator.PlayTone(440);
    }

    private void Play1000_Click(object sender, RoutedEventArgs e)
    {
        AudioToneGenerator.PlayTone(1000);
    }

    private void Play2000_Click(object sender, RoutedEventArgs e)
    {
        AudioToneGenerator.PlayTone(2000);
    }

    private void StopTone_Click(object sender, RoutedEventArgs e)
    {
        AudioToneGenerator.StopTone();
    }

    private void WavBorder_PreviewMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        string wavPath = AudioToneGenerator.GenerateBeepWav(1000);
        var files = new StringCollection { wavPath };
        var data = new DataObject();
        data.SetFileDropList(files);
        DragDrop.DoDragDrop(this, data, DragDropEffects.Copy);
    }
}
