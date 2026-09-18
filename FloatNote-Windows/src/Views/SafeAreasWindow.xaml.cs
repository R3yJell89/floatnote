using System.Windows;
using FloatNote.Utils;

namespace FloatNote.Views;

public partial class SafeAreasWindow : Window
{
    private bool _isLocked = false;

    public SafeAreasWindow()
    {
        InitializeComponent();
    }

    private void Lock_Click(object sender, RoutedEventArgs e)
    {
        _isLocked = !_isLocked;
        Win32Helper.SetClickThrough(this, _isLocked);
        LockBtn.Content = _isLocked ? "🔓 Unlocked" : "🔒 Lock Click";
    }

    private void Close_Click(object sender, RoutedEventArgs e)
    {
        Hide();
    }
}
