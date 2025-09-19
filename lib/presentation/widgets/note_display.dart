import 'package:flutter/material.dart';
import '../../domain/entities/note.dart';
import '../../core/constants/ui_constants.dart';

/// Widget for displaying the detected note information
class NoteDisplay extends StatelessWidget {
  final Note? detectedNote;
  final double detectedFrequency;
  final double centsOffset;
  final bool isInTune;
  final bool hasValidNote;

  const NoteDisplay({
    super.key,
    this.detectedNote,
    required this.detectedFrequency,
    required this.centsOffset,
    required this.isInTune,
    required this.hasValidNote,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Note name and octave
            _buildNoteInfo(context),
            const SizedBox(height: 16),

            // Frequency display
            _buildFrequencyInfo(context),
            const SizedBox(height: 16),

            // Cents offset
            _buildCentsInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteInfo(BuildContext context) {
    if (!hasValidNote || detectedNote == null) {
      return Column(
        children: [
          Text(
            '---',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: UIConstants.ledInactive,
              fontSize: 48,
            ),
          ),
          Text(
            'No signal detected',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    final color = isInTune 
        ? UIConstants.ledInTune 
        : (centsOffset.abs() < 20 
            ? UIConstants.ledSlightlyOff 
            : UIConstants.ledVeryOff);

    return Column(
      children: [
        Text(
          detectedNote!.name,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: color,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (detectedNote!.octave > 0)
          Text(
            'Octave ${detectedNote!.octave}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
      ],
    );
  }

  Widget _buildFrequencyInfo(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.graphic_eq,
          color: hasValidNote ? Colors.white70 : UIConstants.ledInactive,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          '${detectedFrequency.toStringAsFixed(2)} Hz',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: hasValidNote ? Colors.white70 : UIConstants.ledInactive,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCentsInfo(BuildContext context) {
    if (!hasValidNote) {
      return Text(
        '0 cents',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: UIConstants.ledInactive,
        ),
      );
    }

    final centsText = centsOffset >= 0 
        ? '+${centsOffset.toStringAsFixed(1)}' 
        : centsOffset.toStringAsFixed(1);

    final color = isInTune 
        ? UIConstants.ledInTune 
        : (centsOffset.abs() < 20 
            ? UIConstants.ledSlightlyOff 
            : UIConstants.ledVeryOff);

    String statusText;
    IconData statusIcon;

    if (isInTune) {
      statusText = 'In Tune';
      statusIcon = Icons.check_circle;
    } else if (centsOffset > 0) {
      statusText = 'Too High';
      statusIcon = Icons.keyboard_arrow_up;
    } else {
      statusText = 'Too Low';
      statusIcon = Icons.keyboard_arrow_down;
    }

    return Column(
      children: [
        Text(
          '$centsText cents',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              statusIcon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
