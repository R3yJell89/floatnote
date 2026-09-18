using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Text.Json;
using FloatNote.Models;

namespace FloatNote.Services;

public class StorageManager
{
    private static readonly Lazy<StorageManager> _instance = new(() => new StorageManager());
    public static StorageManager Instance => _instance.Value;

    public string AppDataPath { get; }
    private readonly string _prefsFile;
    private readonly string _checklistFile;
    private readonly string _notesFile;

    public UserPreferences Preferences { get; set; } = new();
    public ObservableCollection<ChecklistItem> Checklist { get; set; } = new();
    public string NotesText { get; set; } = string.Empty;

    private StorageManager()
    {
        string appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        AppDataPath = Path.Combine(appData, "FloatNote");
        Directory.CreateDirectory(AppDataPath);

        _prefsFile = Path.Combine(AppDataPath, "preferences.json");
        _checklistFile = Path.Combine(AppDataPath, "checklist.json");
        _notesFile = Path.Combine(AppDataPath, "notes.txt");

        LoadAll();
    }

    public void LoadAll()
    {
        try
        {
            if (File.Exists(_prefsFile))
            {
                string json = File.ReadAllText(_prefsFile);
                Preferences = JsonSerializer.Deserialize<UserPreferences>(json) ?? new();
            }

            if (File.Exists(_checklistFile))
            {
                string json = File.ReadAllText(_checklistFile);
                var items = JsonSerializer.Deserialize<ObservableCollection<ChecklistItem>>(json);
                if (items != null) Checklist = items;
            }

            if (Checklist.Count == 0)
            {
                // Default clean production tasks
                Checklist.Add(new ChecklistItem { Title = "Цветокоррекция: выровнять баланс белого", Timecode = "01:00:02:14", IsCompleted = true });
                Checklist.Add(new ChecklistItem { Title = "Добавить перебивку с общим планом", Timecode = "01:00:15:00", IsCompleted = false });
                Checklist.Add(new ChecklistItem { Title = "Титр: имя и должность эксперта", Timecode = "01:00:28:05", IsCompleted = false });
                Checklist.Add(new ChecklistItem { Title = "Сгладить аудиопереход на склейке", Timecode = "01:00:42:18", IsCompleted = false });
                Checklist.Add(new ChecklistItem { Title = "Финальный экспорт: проверить LUFS -14", Timecode = "01:01:05:00", IsCompleted = false });
                SaveChecklist();
            }

            if (File.Exists(_notesFile))
            {
                NotesText = File.ReadAllText(_notesFile);
            }
            else
            {
                NotesText = "🎬 Проект: Коммерческий промо-ролик\n— Хронометраж: 01:15\n— Целевая платформа: YouTube Shorts & Reels (9:16)\n— Мастер-аудио: -14 LUFS интегрально, True Peak -1.0 dBFS\n\nПравки от режиссера:\n1. В интро усилить динамику на первых 3 секундах.\n2. Кадр с продуктом сделать чуть теплее (+200K по балансу белого).\n3. В финале логотип анимацией Fade In на 12 кадров.";
                SaveNotes(NotesText);
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error loading data: {ex.Message}");
        }
    }

    public void SavePreferences()
    {
        try
        {
            string json = JsonSerializer.Serialize(Preferences, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_prefsFile, json);
        }
        catch { }
    }

    public void SaveChecklist()
    {
        try
        {
            string json = JsonSerializer.Serialize(Checklist, new JsonSerializerOptions { WriteIndented = true });
            File.WriteAllText(_checklistFile, json);
        }
        catch { }
    }

    public void SaveNotes(string text)
    {
        try
        {
            NotesText = text;
            File.WriteAllText(_notesFile, text);
        }
        catch { }
    }
}
