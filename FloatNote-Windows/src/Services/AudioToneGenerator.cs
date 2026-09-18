using System;
using System.IO;
using System.Media;

namespace FloatNote.Services;

public static class AudioToneGenerator
{
    private static SoundPlayer? _activePlayer;

    public static string GenerateBeepWav(int frequency = 1000, double durationSeconds = 1.0, double volume = 0.25)
    {
        // Put in public/documents folder so NLEs have permanent file access
        string folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "FloatNote_Audio");
        Directory.CreateDirectory(folder);
        string filePath = Path.Combine(folder, $"FloatNote_BEEP_{frequency}Hz.wav");

        if (File.Exists(filePath)) return filePath;

        int sampleRate = 44100;
        int samples = (int)(sampleRate * durationSeconds);
        short[] waveData = new short[samples];

        double amplitude = 32760 * Math.Clamp(volume, 0.0, 1.0);
        for (int i = 0; i < samples; i++)
        {
            double t = (double)i / sampleRate;
            waveData[i] = (short)(amplitude * Math.Sin(2.0 * Math.PI * frequency * t));
        }

        using var fs = new FileStream(filePath, FileMode.Create);
        using var bw = new BinaryWriter(fs);

        // RIFF Header
        bw.Write(new char[4] { 'R', 'I', 'F', 'F' });
        bw.Write(36 + samples * 2);
        bw.Write(new char[4] { 'W', 'A', 'V', 'E' });

        // fmt chunk
        bw.Write(new char[4] { 'f', 'm', 't', ' ' });
        bw.Write(16); // subchunk size
        bw.Write((short)1); // PCM
        bw.Write((short)1); // mono
        bw.Write(sampleRate);
        bw.Write(sampleRate * 2); // byte rate
        bw.Write((short)2); // block align
        bw.Write((short)16); // bits per sample

        // data chunk
        bw.Write(new char[4] { 'd', 'a', 't', 'a' });
        bw.Write(samples * 2);
        for (int i = 0; i < samples; i++)
        {
            bw.Write(waveData[i]);
        }

        return filePath;
    }

    public static bool IsPlaying => _activePlayer != null;
    public static int? CurrentPlayingFrequency { get; private set; }

    public static bool ToggleTone(int frequency = 1000)
    {
        if (IsPlaying && CurrentPlayingFrequency == frequency)
        {
            StopTone();
            return false; // Stopped
        }
        else
        {
            PlayTone(frequency);
            return true; // Started playing
        }
    }

    public static void PlayTone(int frequency = 1000)
    {
        try
        {
            StopTone();
            string wavFile = GenerateBeepWav(frequency);
            _activePlayer = new SoundPlayer(wavFile);
            CurrentPlayingFrequency = frequency;
            _activePlayer.Play();
        }
        catch { }
    }

    public static void StopTone()
    {
        try
        {
            _activePlayer?.Stop();
            _activePlayer?.Dispose();
            _activePlayer = null;
            CurrentPlayingFrequency = null;
        }
        catch { }
    }
}
