#ifndef AUDIO_PROCESSOR_H
#define AUDIO_PROCESSOR_H

#include <vector>
#include <memory>
#include <atomic>
#include <thread>
#include <mutex>
#include <condition_variable>

// FFI-compatible structures
struct AudioConfigFFI {
    int32_t sampleRate;
    int32_t bufferSize;
    double minAmplitude;
};

struct TuningResultFFI {
    double detectedFrequency;
    double centsOffset;
    double amplitude;
    int32_t isInTune;
    int64_t timestampMs;
    int32_t hasValidNote;
};

struct NoteInfoFFI {
    int32_t noteIndex;
    int32_t octave;
    double targetFrequency;
};

struct GuitarStringFFI {
    int32_t stringNumber;
    double targetFrequency;
    int32_t noteIndex;
    int32_t octave;
};

struct TuningSettingsFFI {
    double a4Frequency;
    double toleranceCents;
    double minAmplitude;
    int32_t numberOfStrings;
};

// Audio processing class
class AudioProcessor {
public:
    AudioProcessor();
    ~AudioProcessor();

    // Initialization and cleanup
    int initialize(const AudioConfigFFI* config);
    void cleanup();

    // Audio capture control
    int startCapture();
    int stopCapture();
    bool isRunning() const;

    // Settings management
    int updateTuningSettings(const TuningSettingsFFI* settings, const GuitarStringFFI* strings);

    // Result retrieval
    int getLatestResult(TuningResultFFI* result);

private:
    // Audio processing thread
    void audioProcessingLoop();

    // FFT and frequency analysis
    void processAudioBuffer(const std::vector<float>& buffer);
    double detectFundamentalFrequency(const std::vector<float>& fftMagnitudes);
    double calculateCentsOffset(double detectedFreq, double targetFreq);
    int findClosestNote(double frequency);

    // Configuration
    AudioConfigFFI m_config;
    TuningSettingsFFI m_tuningSettings;
    std::vector<GuitarStringFFI> m_guitarStrings;

    // Threading
    std::atomic<bool> m_isRunning;
    std::unique_ptr<std::thread> m_processingThread;
    std::mutex m_resultMutex;
    std::condition_variable m_dataReady;

    // Results
    TuningResultFFI m_latestResult;
    std::atomic<bool> m_hasNewResult;

    // Audio processing
    std::vector<float> m_audioBuffer;
    std::vector<float> m_fftInput;
    std::vector<float> m_fftOutput;

    // Constants
    static constexpr double CENTS_PER_SEMITONE = 100.0;
    static constexpr double SEMITONES_PER_OCTAVE = 12.0;
    static constexpr double NOTE_A4_INDEX = 9; // A is the 9th note (0-indexed)

    // Note names for debugging
    static const char* NOTE_NAMES[12];
};

// C interface for FFI
extern "C" {
    int audioInit(AudioConfigFFI* config);
    int audioStart();
    int audioStop();
    void audioCleanup();
    int getLatestResult(TuningResultFFI* result);
    int setTuningSettings(TuningSettingsFFI* settings, GuitarStringFFI* strings);
    int isAudioRunning();
}

#endif // AUDIO_PROCESSOR_H
