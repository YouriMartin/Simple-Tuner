#include "../include/audio_processor.h"
#include <cmath>
#include <algorithm>
#include <chrono>
#include <cstring>
#include <limits>

// Note names for debugging
const char* AudioProcessor::NOTE_NAMES[12] = {
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
};

// Global instance for C interface
static std::unique_ptr<AudioProcessor> g_audioProcessor;

AudioProcessor::AudioProcessor() : m_isRunning(false), m_hasNewResult(false) {
    // Initialize default configuration
    m_config.sampleRate = 44100;
    m_config.bufferSize = 4096;
    m_config.minAmplitude = 0.001;

    // Initialize default tuning settings
    m_tuningSettings.a4Frequency = 440.0;
    m_tuningSettings.toleranceCents = 5.0;
    m_tuningSettings.minAmplitude = 0.001;
    m_tuningSettings.numberOfStrings = 6;

    // Initialize guitar strings with standard tuning
    m_guitarStrings.resize(6);
    const double standardFreqs[6] = {329.63, 246.94, 196.00, 146.83, 110.00, 82.41};
    const int noteIndices[6] = {4, 11, 7, 2, 9, 4}; // E, B, G, D, A, E
    const int octaves[6] = {4, 3, 3, 3, 2, 2};

    for (int i = 0; i < 6; i++) {
        m_guitarStrings[i].stringNumber = i + 1;
        m_guitarStrings[i].targetFrequency = standardFreqs[i];
        m_guitarStrings[i].noteIndex = noteIndices[i];
        m_guitarStrings[i].octave = octaves[i];
    }

    // Initialize result
    memset(&m_latestResult, 0, sizeof(TuningResultFFI));
}

AudioProcessor::~AudioProcessor() {
    cleanup();
}

int AudioProcessor::initialize(const AudioConfigFFI* config) {
    if (!config) {
        return -1; // Invalid config
    }

    m_config = *config;

    // Initialize audio buffers
    m_audioBuffer.resize(m_config.bufferSize);
    m_fftInput.resize(m_config.bufferSize);
    m_fftOutput.resize(m_config.bufferSize);

    // Determine FFT size as the largest power of two <= bufferSize
    int n = m_config.bufferSize;
    if (n < 2) n = 2;
    int p2 = 1;
    while ((p2 << 1) <= n) p2 <<= 1;
    m_fftSize = p2;

    // Prepare FFT working buffers
    m_fftReal.assign(m_fftSize, 0.0f);
    m_fftImag.assign(m_fftSize, 0.0f);

    // Precompute Hann window
    m_window.resize(m_fftSize);
    if (m_fftSize > 1) {
        for (int i = 0; i < m_fftSize; ++i) {
            m_window[i] = 0.5f * (1.0f - std::cos(2.0 * M_PI * i / (m_fftSize - 1)));
        }
    } else {
        std::fill(m_window.begin(), m_window.end(), 1.0f);
    }

    // Precompute bit-reversal indices
    int bits = 0; while ((1 << bits) < m_fftSize) ++bits;
    m_bitrev.resize(m_fftSize);
    for (int i = 0; i < m_fftSize; ++i) {
        int x = i;
        int r = 0;
        for (int b = 0; b < bits; ++b) {
            r = (r << 1) | (x & 1);
            x >>= 1;
        }
        m_bitrev[i] = r;
    }

    return 0; // Success
}

void AudioProcessor::cleanup() {
    if (m_isRunning) {
        stopCapture();
    }
}

int AudioProcessor::startCapture() {
    if (m_isRunning) {
        return -2; // Already running
    }

    m_isRunning = true;
    m_processingThread = std::make_unique<std::thread>(&AudioProcessor::audioProcessingLoop, this);

    return 0; // Success
}

int AudioProcessor::stopCapture() {
    if (!m_isRunning) {
        return 0; // Already stopped
    }

    m_isRunning = false;
    m_dataReady.notify_all();

    if (m_processingThread && m_processingThread->joinable()) {
        m_processingThread->join();
    }

    return 0; // Success
}

bool AudioProcessor::isRunning() const {
    return m_isRunning;
}

int AudioProcessor::updateTuningSettings(const TuningSettingsFFI* settings, const GuitarStringFFI* strings) {
    if (!settings || !strings) {
        return -1; // Invalid parameters
    }

    std::lock_guard<std::mutex> lock(m_resultMutex);

    m_tuningSettings = *settings;

    // Update guitar strings
    for (int i = 0; i < m_tuningSettings.numberOfStrings && i < 6; i++) {
        m_guitarStrings[i] = strings[i];
    }

    return 0; // Success
}

int AudioProcessor::getLatestResult(TuningResultFFI* result) {
    if (!result) {
        return -1; // Invalid parameter
    }

    std::lock_guard<std::mutex> lock(m_resultMutex);

    if (!m_hasNewResult) {
        return 1; // No new data
    }

    *result = m_latestResult;
    m_hasNewResult = false;

    return 0; // Success
}

void AudioProcessor::audioProcessingLoop() {
    while (m_isRunning) {
        // Simulate audio capture - in real implementation, this would capture from microphone
        // For now, generate mock data for testing

        // Generate mock audio signal (sine wave with some noise)
        const double baseFreq = 82.41; // Low E string
        const double time = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count() / 1000.0;

        for (int i = 0; i < m_config.bufferSize; i++) {
            double t = (time + i / double(m_config.sampleRate));
            // Add slight frequency variation to simulate real playing
            double freq = baseFreq + 2.0 * std::sin(t * 0.5);
            m_audioBuffer[i] = 0.5f * std::sin(2.0 * M_PI * freq * t);
            // Add some noise
            m_audioBuffer[i] += 0.1f * (rand() / float(RAND_MAX) - 0.5f);
        }

        // Process the audio buffer
        processAudioBuffer(m_audioBuffer);

        // Sleep for approximately 16ms (60 FPS)
        std::this_thread::sleep_for(std::chrono::milliseconds(16));
    }
}

void AudioProcessor::processAudioBuffer(const std::vector<float>& buffer) {
    // Use m_fftSize samples for FFT (largest power of two <= buffer size)
    const int N = m_fftSize > 0 ? m_fftSize : (int)std::min<size_t>(buffer.size(), 2048);
    if (N <= 1) return;

    // Apply Hann window and copy to working arrays (real/imag)
    const int copyCount = std::min((int)buffer.size(), N);
    for (int i = 0; i < copyCount; ++i) {
        float w = (i < (int)m_window.size()) ? m_window[i] : 1.0f;
        m_fftReal[i] = buffer[i] * w;
        m_fftImag[i] = 0.0f;
    }
    for (int i = copyCount; i < N; ++i) {
        m_fftReal[i] = 0.0f;
        m_fftImag[i] = 0.0f;
    }

    // Bit-reversal permutation into temp arrays
    std::vector<float> tr(N), ti(N);
    for (int i = 0; i < N; ++i) {
        int j = (i < (int)m_bitrev.size()) ? m_bitrev[i] : i;
        tr[i] = m_fftReal[j];
        ti[i] = m_fftImag[j];
    }
    m_fftReal.swap(tr);
    m_fftImag.swap(ti);

    // Iterative radix-2 Cooley-Tukey FFT
    for (int len = 2; len <= N; len <<= 1) {
        const int half = len >> 1;
        const float ang = float(-2.0 * M_PI / len);
        const float wlen_cos = std::cos(ang);
        const float wlen_sin = std::sin(ang);
        for (int i = 0; i < N; i += len) {
            float w_cos = 1.0f;
            float w_sin = 0.0f;
            for (int j = 0; j < half; ++j) {
                const int u = i + j;
                const int v = u + half;
                // t = w * a[v]
                float t_real = m_fftReal[v] * w_cos - m_fftImag[v] * w_sin;
                float t_imag = m_fftReal[v] * w_sin + m_fftImag[v] * w_cos;
                // a[v] = a[u] - t
                m_fftReal[v] = m_fftReal[u] - t_real;
                m_fftImag[v] = m_fftImag[u] - t_imag;
                // a[u] = a[u] + t
                m_fftReal[u] += t_real;
                m_fftImag[u] += t_imag;
                // w *= wlen
                float next_w_cos = w_cos * wlen_cos - w_sin * wlen_sin;
                float next_w_sin = w_cos * wlen_sin + w_sin * wlen_cos;
                w_cos = next_w_cos;
                w_sin = next_w_sin;
            }
        }
    }

    // Compute magnitude spectrum (first N/2 bins)
    std::vector<float> magnitudes(N / 2);
    for (int k = 0; k < N / 2; ++k) {
        float re = m_fftReal[k];
        float im = m_fftImag[k];
        magnitudes[k] = std::sqrt(re * re + im * im) / (N * 0.5f); // scale
    }

    // Detect fundamental frequency
    double detectedFreq = detectFundamentalFrequency(magnitudes);

    // Calculate RMS amplitude of the time signal (unwindowed estimate)
    double amplitude = 0.0;
    for (float sample : buffer) {
        amplitude += double(sample) * double(sample);
    }
    amplitude = std::sqrt(amplitude / std::max<size_t>(buffer.size(), 1));

    // Update result
    {
        std::lock_guard<std::mutex> lock(m_resultMutex);

        m_latestResult.detectedFrequency = detectedFreq;
        m_latestResult.amplitude = amplitude;
        m_latestResult.timestampMs = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::steady_clock::now().time_since_epoch()).count();

        if (amplitude > m_tuningSettings.minAmplitude && detectedFreq > 0) {
            // Find closest guitar string
            int closestString = 0;
            double minDiff = std::abs(detectedFreq - m_guitarStrings[0].targetFrequency);

            for (int i = 1; i < m_tuningSettings.numberOfStrings; i++) {
                double diff = std::abs(detectedFreq - m_guitarStrings[i].targetFrequency);
                if (diff < minDiff) {
                    minDiff = diff;
                    closestString = i;
                }
            }

            // Calculate cents offset from target
            double targetFreq = m_guitarStrings[closestString].targetFrequency;
            m_latestResult.centsOffset = calculateCentsOffset(detectedFreq, targetFreq);
            m_latestResult.isInTune = std::abs(m_latestResult.centsOffset) <= m_tuningSettings.toleranceCents ? 1 : 0;
            m_latestResult.hasValidNote = 1;
        } else {
            m_latestResult.centsOffset = 0.0;
            m_latestResult.isInTune = 0;
            m_latestResult.hasValidNote = 0;
        }

        m_hasNewResult = true;
    }
}

double AudioProcessor::detectFundamentalFrequency(const std::vector<float>& fftMagnitudes) {
    // Find peak in frequency spectrum
    int peakIndex = 0;
    float peakMagnitude = 0.0f;

    // Search in frequency range appropriate for guitar (80-400 Hz)
    const int N = (m_fftSize > 0) ? m_fftSize : (int)fftMagnitudes.size() * 2;
    int minIndex = static_cast<int>(80.0 * N / m_config.sampleRate);
    int maxIndex = static_cast<int>(400.0 * N / m_config.sampleRate);
    minIndex = std::max(1, minIndex);
    maxIndex = std::min((int)fftMagnitudes.size() - 1, maxIndex);

    for (int i = minIndex; i < maxIndex && i < (int)fftMagnitudes.size(); i++) {
        if (fftMagnitudes[i] > peakMagnitude) {
            peakMagnitude = fftMagnitudes[i];
            peakIndex = i;
        }
    }

    if (peakMagnitude < m_config.minAmplitude) {
        return 0.0; // No significant peak found
    }

    // Convert bin index to frequency
    double frequency = (double)peakIndex * m_config.sampleRate / N;
    return frequency;
}

double AudioProcessor::calculateCentsOffset(double detectedFreq, double targetFreq) {
    if (targetFreq <= 0 || detectedFreq <= 0) {
        return 0.0;
    }

    // Cents = 1200 * log2(f1/f2)
    return 1200.0 * log2(detectedFreq / targetFreq);
}

int AudioProcessor::findClosestNote(double frequency) {
    if (frequency <= 0) {
        return -1;
    }

    // Calculate note based on A4 = 440Hz
    double a4Freq = m_tuningSettings.a4Frequency;
    double semitonesFromA4 = 12.0 * log2(frequency / a4Freq);
    int noteIndex = static_cast<int>(round(semitonesFromA4)) % 12;

    // Ensure positive index
    while (noteIndex < 0) {
        noteIndex += 12;
    }

    return noteIndex;
}

// C interface implementations
extern "C" {
    int audioInit(AudioConfigFFI* config) {
        try {
            g_audioProcessor = std::make_unique<AudioProcessor>();
            return g_audioProcessor->initialize(config);
        } catch (...) {
            return -1;
        }
    }

    int audioStart() {
        if (!g_audioProcessor) {
            return -1;
        }
        return g_audioProcessor->startCapture();
    }

    int audioStop() {
        if (!g_audioProcessor) {
            return -1;
        }
        return g_audioProcessor->stopCapture();
    }

    void audioCleanup() {
        if (g_audioProcessor) {
            g_audioProcessor->cleanup();
            g_audioProcessor.reset();
        }
    }

    int getLatestResult(TuningResultFFI* result) {
        if (!g_audioProcessor) {
            return -1;
        }
        return g_audioProcessor->getLatestResult(result);
    }

    int setTuningSettings(TuningSettingsFFI* settings, GuitarStringFFI* strings) {
        if (!g_audioProcessor) {
            return -1;
        }
        return g_audioProcessor->updateTuningSettings(settings, strings);
    }

    int isAudioRunning() {
        if (!g_audioProcessor) {
            return 0;
        }
        return g_audioProcessor->isRunning() ? 1 : 0;
    }
}
