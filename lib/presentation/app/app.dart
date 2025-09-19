import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc_exports.dart';
import '../theme/app_theme.dart';
import '../pages/tuner_page.dart';
import '../pages/permission_page.dart';
import '../../core/dependency_injection/injection_container.dart' as di;

/// Main application widget
class SimpleTunerApp extends StatelessWidget {
  const SimpleTunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TunerBloc>(
          create: (_) => di.sl<TunerBloc>(),
        ),
        BlocProvider<PermissionBloc>(
          create: (_) => di.sl<PermissionBloc>()
            ..add(const CheckPermissionEvent()),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => di.sl<SettingsBloc>()
            ..add(const LoadSettingsEvent()),
        ),
      ],
      child: MaterialApp(
        title: 'Simple Tuner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppWrapper(),
      ),
    );
  }
}

/// Wrapper that handles navigation based on permission state
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PermissionBloc, PermissionState>(
      builder: (context, permissionState) {
        // Show permission page if permission is denied or permanently denied
        if (permissionState is PermissionDenied || 
            permissionState is PermissionPermanentlyDenied) {
          return const PermissionPage();
        }

        // Show loading while checking permission
        if (permissionState is PermissionLoading || 
            permissionState is PermissionInitial) {
          return const _LoadingScreen();
        }

        // Show main tuner page if permission is granted or for errors
        return const TunerPage();
      },
    );
  }
}

/// Loading screen shown during app initialization
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              size: 80,
              color: Colors.white70,
            ),
            SizedBox(height: 24),
            Text(
              'Simple Tuner',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
