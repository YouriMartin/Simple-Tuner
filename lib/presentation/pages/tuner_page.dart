import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc_exports.dart';
import '../widgets/tuner_led_circle.dart';
import '../widgets/note_display.dart';
import '../../core/constants/ui_constants.dart';
import 'settings_page.dart';

/// Main tuner page with LED circle and note display
class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  @override
  void initState() {
    super.initState();
    // Load settings on page initialization
    context.read<SettingsBloc>().add(const LoadSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Tuner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: BlocListener<PermissionBloc, PermissionState>(
          listener: (context, state) {
            if (state is PermissionDenied || state is PermissionPermanentlyDenied) {
              _showPermissionDialog(context);
            }
          },
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Tuner LED Circle
                      _buildTunerSection(),
                      const SizedBox(height: 32),

                      // Note Display
                      _buildNoteSection(),
                      const SizedBox(height: 32),

                      // Control Buttons
                      _buildControlSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTunerSection() {
    return BlocBuilder<TunerBloc, TunerState>(
      builder: (context, state) {
        double centsOffset = 0.0;
        bool isInTune = false;
        bool hasValidNote = false;
        double amplitude = 0.0;

        if (state is TunerRunning && state.currentResult != null) {
          final result = state.currentResult!;
          centsOffset = result.centsOffset;
          isInTune = result.isInTune;
          hasValidNote = result.detectedNote != null;
          amplitude = result.amplitude;
        }

        return Center(
          child: TunerLedCircle(
            centsOffset: centsOffset,
            isInTune: isInTune,
            hasValidNote: hasValidNote,
            amplitude: amplitude,
          ),
        );
      },
    );
  }

  Widget _buildNoteSection() {
    return BlocBuilder<TunerBloc, TunerState>(
      builder: (context, state) {
        if (state is TunerRunning && state.currentResult != null) {
          final result = state.currentResult!;
          return NoteDisplay(
            detectedNote: result.detectedNote,
            detectedFrequency: result.detectedFrequency,
            centsOffset: result.centsOffset,
            isInTune: result.isInTune,
            hasValidNote: result.detectedNote != null,
          );
        }

        return const NoteDisplay(
          detectedFrequency: 0.0,
          centsOffset: 0.0,
          isInTune: false,
          hasValidNote: false,
        );
      },
    );
  }

  Widget _buildControlSection() {
    return BlocBuilder<TunerBloc, TunerState>(
      builder: (context, state) {
        final isRunning = state is TunerRunning;
        final isLoading = state is TunerLoading;

        return Column(
          children: [
            // Start/Stop button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _toggleTuner(context, isRunning),
                icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                label: Text(isRunning ? 'Stop Tuner' : 'Start Tuner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning 
                      ? UIConstants.ledVeryOff 
                      : UIConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Status text
            _buildStatusText(state),
          ],
        );
      },
    );
  }

  Widget _buildStatusText(TunerState state) {
    String statusText;
    Color statusColor;

    switch (state.runtimeType) {
      case TunerInitial:
        statusText = 'Press Start to begin tuning';
        statusColor = Colors.white70;
        break;
      case TunerLoading:
        statusText = 'Starting tuner...';
        statusColor = UIConstants.ledSlightlyOff;
        break;
      case TunerRunning:
        statusText = 'Tuner active - Play a note';
        statusColor = UIConstants.ledInTune;
        break;
      case TunerStopped:
        statusText = 'Tuner stopped';
        statusColor = Colors.white70;
        break;
      case TunerError:
        statusText = (state as TunerError).message;
        statusColor = UIConstants.ledVeryOff;
        break;
      default:
        statusText = 'Unknown state';
        statusColor = Colors.white70;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _getStatusIcon(state),
          color: statusColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _getStatusIcon(TunerState state) {
    switch (state.runtimeType) {
      case TunerInitial:
        return Icons.music_note_outlined;
      case TunerLoading:
        return Icons.hourglass_empty;
      case TunerRunning:
        return Icons.mic;
      case TunerStopped:
        return Icons.stop;
      case TunerError:
        return Icons.error_outline;
      default:
        return Icons.help_outline;
    }
  }

  void _toggleTuner(BuildContext context, bool isRunning) {
    if (isRunning) {
      context.read<TunerBloc>().add(const StopTuningEvent());
    } else {
      // Check permission first
      context.read<PermissionBloc>().add(const CheckPermissionEvent());

      // Listen to permission state and start tuner if granted
      final permissionState = context.read<PermissionBloc>().state;
      if (permissionState is PermissionGranted) {
        context.read<TunerBloc>().add(const StartTuningEvent());
      } else {
        context.read<PermissionBloc>().add(const RequestPermissionEvent());
      }
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Microphone Permission Required'),
        content: const Text(
          'This app needs microphone access to analyze audio and provide tuning feedback. '
          'Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PermissionBloc>().add(const RequestPermissionEvent());
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
