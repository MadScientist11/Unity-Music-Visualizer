using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class MusicVisualizer : MonoBehaviour
{
    [SerializeField] private AudioSource _audioSource;
    [SerializeField] private RawImage _image;

    private float[] _samples = new float[512];
    private float[] _sampleBuffer = new float[512];
    private Material _material;
    private static readonly int Samples = Shader.PropertyToID("_Samples");
    private float[] _FreqBands8 = new float[8];
    private float[] _FreqBands64 = new float[64];
    private float _currentDuration = 0;

    private void Start()
    {
        _material = _image.material;
        StartCoroutine(ChartUpdate());
    }
    
    private void Update()
    {
        _currentDuration += Time.deltaTime;
        _audioSource.GetSpectrumData(_sampleBuffer, 0, FFTWindow.BlackmanHarris);


        for (int i = 0; i < _samples.Length; i++)
        {
            _samples[i] = Mathf.Lerp(_samples[i], _sampleBuffer[i],
                EasingFunction.EaseInOutCirc(0,1,_currentDuration));
        }

        UpdateFreqBands64();
    }

   

    private IEnumerator ChartUpdate()
    {
        while (true)
        {
            _currentDuration = 0;
            yield return new WaitForSeconds(1);
        }
    }

    private void UpdateFreqBands8()
    {
        int count = 0;
        for (int i = 0; i < 8; i++)
        {
            float average = 0;
            int sampleCount = (int)Mathf.Pow(2, i) * 2;

            if (i == 7)
            {
                sampleCount += 2;
            }

            for (int j = 0; j < sampleCount; j++)
            {
                average += _samples[count] * (count + 1);
                count++;
            }

            average /= count;
            _FreqBands8[i] = average;
        }

        _material.SetFloatArray(Samples, _FreqBands8);
    }

    void UpdateFreqBands64()
    {
        int count = 0;
        int sampleCount = 1;
        int power = 0;

        for (int i = 0; i < 64; i++)
        {
            float average = 0;

            if (i == 16 || i == 32 || i == 40 || i == 48 || i == 56)
            {
                power++;
                sampleCount = (int)Mathf.Pow(2, power);
                if (power == 3)
                    sampleCount -= 2;
            }

            for (int j = 0; j < sampleCount; j++)
            {
                average += _samples[count] * (count + 1);
                count++;
            }

            average /= count;
            _FreqBands64[i] = average;
        }

        _material.SetFloatArray(Samples, _FreqBands64);
    }
}
