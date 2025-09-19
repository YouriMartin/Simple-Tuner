#include "../include/audio_processor.h"
#include <cmath>
#include <algorithm>
#include <chrono>
#include <cstring>

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
    // Copy to FFT input buffer
    std::copy(buffer.begin(), buffer.end(), m_fftInput.begin());

    // Simple FFT implementation (for demo - real implementation would use FFTW or similar)
    // This is a placeholder for proper FFT implementation
    std::vector<float> magnitudes(m_config.bufferSize / 2);

    // Calculate magnitude spectrum (simplified)
    for (int k = 0; k < m_config.bufferSize / 2; k++) {
        double real = 0.0, imag = 0.0;
        for (int n = 0; n < m_config.bufferSize; n++) {
            double angle = -2.0 * M_PI * k * n / m_config.bufferSize;
            real += m_fftInput[n] * cos(angle);
            imag += m_fftInput[n] * sin(angle);
        }
        magnitudes[k] = sqrt(real * real + imag * imag);
    }

    // Detect fundamental frequency
    double detectedFreq = detectFundamentalFrequency(magnitudes);

    // Calculate amplitude
    double amplitude = 0.0;
    for (float sample : buffer) {
        amplitude += sample * sample;
    }
    amplitude = sqrt(amplitude / buffer.size());

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
    int minIndex = static_cast<int>(80.0 * m_config.bufferSize / m_config.sampleRate);
    int maxIndex = static_cast<int>(400.0 * m_config.bufferSize / m_config.sampleRate);

    for (int i = minIndex; i < maxIndex && i < fftMagnitudes.size(); i++) {
        if (fftMagnitudes[i] > peakMagnitude) {
            peakMagnitude = fftMagnitudes[i];
            peakIndex = i;
        }
    }

    if (peakMagnitude < m_config.minAmplitude) {
        return 0.0; // No significant peak found
    }

    // Convert bin index to frequency
    double frequency = (double)peakIndex * m_config.sampleRate / m_config.bufferSize;
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
