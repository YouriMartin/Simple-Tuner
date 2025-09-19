import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc_exports.dart';
import '../../core/constants/ui_constants.dart';

/// Page displayed when microphone permission is denied
class PermissionPage extends StatelessWidget {
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.mic_off_rounded,
                size: 120,
                color: UIConstants.ledVeryOff,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Microphone Access Required',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Simple Tuner needs access to your device\'s microphone to analyze '
                'audio and provide accurate tuning feedback.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Features list
              _buildFeaturesList(context),
              const SizedBox(height: 48),

              // Permission buttons
              _buildPermissionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final features = [
      {
        'icon': Icons.music_note,
        'title': 'Real-time Analysis',
        'description': 'Instant frequency detection and tuning feedback',
      },
      {
        'icon': Icons.precision_manufacturing,
        'title': 'High Precision',
        'description': 'Accurate to 0.5 cents for professional tuning',
      },
      {
        'icon': Icons.security,
        'title': 'Privacy Focused',
        'description': 'Audio is processed locally, never stored or transmitted',
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What we use microphone for:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    feature['icon'] as IconData,
                    color: UIConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          feature['description'] as String,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionButtons(BuildContext context) {
    return BlocBuilder<PermissionBloc, PermissionState>(
      builder: (context, state) {
        final isLoading = state is PermissionLoading;

        return Column(
          children: [
            // Grant permission button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading 
                    ? null 
                    : () => context.read<PermissionBloc>().add(const RequestPermissionEvent()),
                icon: isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mic),
                label: Text(isLoading ? 'Requesting...' : 'Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UIConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Exit button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : () => _exitApp(context),
                icon: const Icon(Icons.close),
                label: const Text('Exit App'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white30),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            // Permission state message
            if (state is PermissionError)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: UIConstants.ledVeryOff,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }

  void _exitApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text(
          'Simple Tuner cannot function without microphone permission. '
          'Are you sure you want to exit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    ).then((shouldExit) {
      if (shouldExit == true) {
        // Close the app
        Navigator.of(context).pop();
      }
    });
  }
}
