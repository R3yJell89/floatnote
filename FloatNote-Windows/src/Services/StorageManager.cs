using System;
using System.Collections.Generic;
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
    public List<ChecklistItem> Checklist { get; set; } = new();
    public string NotesText { get; set; } = string.Empty;

    private StorageManager()
    {
        // Store in %APPDATA%\FloatNote
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
                Checklist = JsonSerializer.Deserialize<List<ChecklistItem>>(json) ?? new();
            }

            if (File.Exists(_notesFile))
            {
                NotesText = File.ReadAllText(_notesFile);
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
