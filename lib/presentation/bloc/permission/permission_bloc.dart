import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/request_microphone_permission.dart';
import '../../../domain/repositories/audio_repository.dart';
import 'permission_event.dart';
import 'permission_state.dart';

/// BLoC for managing microphone permissions
class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  final RequestMicrophonePermission _requestPermission;
  final AudioRepository _audioRepository;

  PermissionBloc({
    required RequestMicrophonePermission requestPermission,
    required AudioRepository audioRepository,
  })  : _requestPermission = requestPermission,
        _audioRepository = audioRepository,
        super(const PermissionInitial()) {
    on<CheckPermissionEvent>(_onCheckPermission);
    on<RequestPermissionEvent>(_onRequestPermission);
    on<PermissionResultEvent>(_onPermissionResult);
    on<ResetPermissionEvent>(_onResetPermission);
  }

  Future<void> _onCheckPermission(
    CheckPermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(const PermissionLoading());

    final result = await _audioRepository.checkMicrophonePermission();

    result.fold(
      (failure) => emit(PermissionError(failure.message)),
      (isGranted) {
        if (isGranted) {
          emit(const PermissionGranted());
        } else {
          emit(const PermissionDenied());
        }
      },
    );
  }

  Future<void> _onRequestPermission(
    RequestPermissionEvent event,
    Emitter<PermissionState> emit,
  ) async {
    emit(const PermissionLoading());

    final result = await _requestPermission();

    result.fold(
      (failure) => emit(PermissionError(failure.message)),
      (isGranted) => add(PermissionResultEvent(isGranted)),
    );
  }

  void _onPermissionResult(
    PermissionResultEvent event,
    Emitter<PermissionState> emit,
  ) {
    if (event.isGranted) {
      emit(const PermissionGranted());
    } else {
      emit(const PermissionDenied());
    }
  }

  void _onResetPermission(
    ResetPermissionEvent event,
    Emitter<PermissionState> emit,
  ) {
    emit(const PermissionInitial());
  }
}
