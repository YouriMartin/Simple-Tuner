import 'package:dartz/dartz.dart';
import '../error/failures.dart';

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require parameters
abstract class UseCaseNoParams<Type> {
  Future<Either<Failure, Type>> call();
}

/// Use case that returns a stream
abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

/// Use case that returns a stream without parameters
abstract class StreamUseCaseNoParams<Type> {
  Stream<Type> call();
}

/// Empty parameters class
class NoParams {}
