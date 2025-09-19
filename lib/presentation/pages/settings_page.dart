import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc_exports.dart';
import '../../core/constants/ui_constants.dart';

/// Settings page for configuring tuning parameters
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetToStandardTuning(context),
            tooltip: 'Reset to Standard Tuning',
          ),
        ],
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: UIConstants.ledVeryOff,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SettingsBloc>().add(const LoadSettingsEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SettingsLoaded || state is SettingsSaved) {
            final settings = state is SettingsLoaded 
                ? state.settings 
                : (state as SettingsSaved).settings;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A4 Frequency Section
                  _buildA4FrequencySection(context, settings.a4Frequency),
                  const SizedBox(height: 24),

                  // Guitar Strings Section
                  _buildGuitarStringsSection(context, settings.strings),
                  const SizedBox(height: 24),

                  // Tuning Tolerance Section
                  _buildToleranceSection(context, settings.toleranceCents),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildA4FrequencySection(BuildContext context, double a4Frequency) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A4 Reference Frequency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Standard concert pitch (usually 440 Hz)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: a4Frequency,
                    min: 430.0,
                    max: 450.0,
                    divisions: 200,
                    activeColor: UIConstants.primaryColor,
                    onChanged: (value) => _updateA4Frequency(context, value),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Text(
                    '${a4Frequency.toStringAsFixed(1)} Hz',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuitarStringsSection(BuildContext context, List<dynamic> strings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guitar String Tuning',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap frequency values to edit individual strings',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            ...strings.map((string) => _buildStringRow(context, string)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStringRow(BuildContext context, dynamic string) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // String number and name
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${string.stringNumber}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: UIConstants.primaryColor,
                  ),
                ),
                Text(
                  string.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Note name
          SizedBox(
            width: 40,
            child: Text(
              string.targetNote.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Frequency (editable)
          Expanded(
            child: GestureDetector(
              onTap: () => _editStringFrequency(context, string),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: UIConstants.surfaceColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  '${string.targetNote.frequency.toStringAsFixed(2)} Hz',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToleranceSection(BuildContext context, double toleranceCents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tuning Tolerance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How close to perfect pitch before showing "In Tune"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: toleranceCents,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    activeColor: UIConstants.primaryColor,
                    onChanged: (value) => _updateTolerance(context, value),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 80,
                  child: Text(
                    '±${toleranceCents.toStringAsFixed(1)} ¢',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateA4Frequency(BuildContext context, double frequency) {
    context.read<SettingsBloc>().add(UpdateA4FrequencyEvent(frequency));
  }

  void _updateTolerance(BuildContext context, double tolerance) {
    context.read<SettingsBloc>().add(UpdateToleranceEvent(tolerance));
  }

  void _editStringFrequency(BuildContext context, dynamic string) {
    final controller = TextEditingController(
      text: string.targetNote.frequency.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${string.name} (String ${string.stringNumber})'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Frequency (Hz)',
            suffixText: 'Hz',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final frequency = double.tryParse(controller.text);
              if (frequency != null && frequency > 0) {
                context.read<SettingsBloc>().add(
                  UpdateStringFrequencyEvent(string.stringNumber, frequency),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _resetToStandardTuning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Standard Tuning'),
        content: const Text(
          'This will reset all guitar strings to standard tuning (E-A-D-G-B-E). '
          'Your A4 frequency and tolerance settings will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<SettingsBloc>().add(const ResetToStandardTuningEvent());
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
