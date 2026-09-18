using System.Windows;
using System.Windows.Controls;
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

    private void DragWav_Click(object sender, RoutedEventArgs e)
    {
        string wavPath = AudioToneGenerator.GenerateBeepWav(1000);
        var data = new DataObject(DataFormats.FileDrop, new string[] { wavPath });
        DragDrop.DoDragDrop(this, data, DragDropEffects.Copy);
    }
}
