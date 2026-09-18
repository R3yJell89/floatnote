using System.Collections.ObjectModel;
using System.Windows;
using System.Windows.Input;
using FloatNote.Utils;

namespace FloatNote.Views;

public partial class ClipboardWindow : Window
{
    public ObservableCollection<string> History { get; } = new();

    public ClipboardWindow()
    {
        InitializeComponent();
        Loaded += (s, e) => {
            Win32Helper.ApplyPowerToysTheme(this, useAcrylic: true);
            ClipboardItemsControl.ItemsSource = History;
        };
    }

    public void AddClip(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return;
        if (History.Contains(text)) History.Remove(text);
        History.Insert(0, text);
        if (History.Count > 50) History.RemoveAt(History.Count - 1);
    }

    private void CopyItem_Click(object sender, RoutedEventArgs e)
    {
        if (sender is FrameworkElement fe && fe.DataContext is string str)
        {
            Clipboard.SetText(str);
        }
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
