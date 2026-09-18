using System;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Ink;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace FloatNote.Views;

public partial class SketchViewControl : UserControl
{
    public SketchViewControl()
    {
        InitializeComponent();
    }

    private void ToolPen_Click(object sender, RoutedEventArgs e)
    {
        SketchInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
    }

    private void ToolArrow_Click(object sender, RoutedEventArgs e)
    {
        SketchInkCanvas.EditingMode = InkCanvasEditingMode.Ink;
    }

    private void ToolRect_Click(object sender, RoutedEventArgs e)
    {
        SketchInkCanvas.EditingMode = InkCanvasEditingMode.Select;
    }

    private void ColorRed_Click(object sender, RoutedEventArgs e)
    {
        SketchInkCanvas.DefaultDrawingAttributes.Color = Color.FromRgb(255, 59, 48);
    }

    private void ColorGreen_Click(object sender, RoutedEventArgs e)
    {
        SketchInkCanvas.DefaultDrawingAttributes.Color = Color.FromRgb(46, 208, 110);
    }

    private void ColorCyan_Click(object sender, RoutedEventArgs e)
    {
        SketchInkCanvas.DefaultDrawingAttributes.Color = Color.FromRgb(0, 255, 255);
    }

    private void Clear_Click(object sender, RoutedEventArgs e)
    {
        SketchInkCanvas.Strokes.Clear();
    }

    private void SavePng_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            int w = (int)SketchInkCanvas.ActualWidth;
            int h = (int)SketchInkCanvas.ActualHeight;
            if (w <= 0 || h <= 0) return;

            var rtb = new RenderTargetBitmap(w, h, 96, 96, PixelFormats.Pbgra32);
            rtb.Render(SketchInkCanvas);

            var encoder = new PngBitmapEncoder();
            encoder.Frames.Add(BitmapFrame.Create(rtb));

            string folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyPictures), "FloatNote_Sketches");
            Directory.CreateDirectory(folder);
            string file = Path.Combine(folder, $"sketch_{DateTime.Now:yyyyMMdd_HHmmss}.png");

            using var fs = File.Create(file);
            encoder.Save(fs);
            MessageBox.Show($"Эскиз сохранен в:\n{file}", "FloatNote", MessageBoxButton.OK, MessageBoxImage.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Ошибка сохранения: {ex.Message}");
        }
    }
}
