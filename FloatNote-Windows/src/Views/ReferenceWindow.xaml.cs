using System;
using System.IO;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media.Imaging;
using FloatNote.Utils;

namespace FloatNote.Views;

public partial class ReferenceWindow : Window
{
    private bool _isLocked = false;

    public ReferenceWindow()
    {
        InitializeComponent();
        Loaded += (s, e) => Win32Helper.ApplyPowerToysTheme(this, useAcrylic: true);
    }

    private void OpacitySlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        Opacity = e.NewValue;
    }

    private void Lock_Click(object sender, RoutedEventArgs e)
    {
        _isLocked = !_isLocked;
        Win32Helper.SetClickThrough(this, _isLocked);
        LockBtn.Content = _isLocked ? "🔓" : "🔒";
    }

    private void Window_DragOver(object sender, DragEventArgs e)
    {
        if (e.Data.GetDataPresent(DataFormats.FileDrop))
        {
            e.Effects = DragDropEffects.Copy;
        }
    }

    private void Window_Drop(object sender, DragEventArgs e)
    {
        if (e.Data.GetDataPresent(DataFormats.FileDrop))
        {
            string[] files = (string[])e.Data.GetData(DataFormats.FileDrop);
            if (files.Length > 0 && File.Exists(files[0]))
            {
                LoadImage(files[0]);
            }
        }
    }

    public void LoadImage(string filePath)
    {
        try
        {
            var bitmap = new BitmapImage(new Uri(filePath));
            ReferenceImage.Source = bitmap;
            PlaceholderPanel.Visibility = Visibility.Collapsed;
        }
        catch { }
    }

    private void Border_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ButtonState == MouseButtonState.Pressed && !_isLocked)
        {
            DragMove();
        }
    }

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        Hide();
    }
}
