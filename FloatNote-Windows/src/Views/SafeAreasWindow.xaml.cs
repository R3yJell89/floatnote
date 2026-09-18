using System.Windows;
using System.Windows.Input;
using FloatNote.Utils;

namespace FloatNote.Views;

public partial class SafeAreasWindow : Window
{
    private bool _isLocked = false;
    private bool _is916 = true;

    public SafeAreasWindow()
    {
        InitializeComponent();
    }

    private void Lock_Click(object sender, RoutedEventArgs e)
    {
        _isLocked = !_isLocked;
        Win32Helper.SetClickThrough(this, _isLocked);
        LockBtn.Content = _isLocked ? "🔓 Разблокировать" : "🔒 Сквозной клик";
    }

    private void Mode_Click(object sender, RoutedEventArgs e)
    {
        _is916 = !_is916;
        VerticalGuide.Visibility = _is916 ? Visibility.Visible : Visibility.Collapsed;
        HorizontalGuide.Visibility = _is916 ? Visibility.Collapsed : Visibility.Visible;
        ModeBtn.Content = _is916 ? "Режим: 9:16" : "Режим: 16:9";
    }

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        CloseOverlay();
    }

    private void Window_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Escape)
        {
            CloseOverlay();
        }
    }

    private void CloseOverlay()
    {
        if (_isLocked)
        {
            Win32Helper.SetClickThrough(this, false);
            _isLocked = false;
        }
        Hide();
    }
}
