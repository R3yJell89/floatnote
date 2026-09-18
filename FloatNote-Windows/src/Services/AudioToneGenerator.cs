using System;
using System.IO;
using System.Media;

namespace FloatNote.Services;

public static class AudioToneGenerator
{
    public static string GenerateBeepWav(int frequency = 1000, double durationSeconds = 1.0, double volume = 0.25)
    {
        string tempPath = Path.Combine(Path.GetTempPath(), $"floatnote_beep_{frequency}Hz.wav");
        if (File.Exists(tempPath)) return tempPath;

        int sampleRate = 44100;
        int samples = (int)(sampleRate * durationSeconds);
        short[] waveData = new short[samples];

        double amplitude = 32760 * Math.Clamp(volume, 0.0, 1.0);
        for (int i = 0; i < samples; i++)
        {
            double t = (double)i / sampleRate;
            waveData[i] = (short)(amplitude * Math.Sin(2.0 * Math.PI * frequency * t));
        }

        using var fs = new FileStream(tempPath, FileMode.Create);
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

        return tempPath;
    }

    public static void PlayTone(int frequency = 1000)
    {
        try
        {
            string wavFile = GenerateBeepWav(frequency);
            using var player = new SoundPlayer(wavFile);
            player.Play();
        }
        catch { }
    }
}
