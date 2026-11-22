import 'package:equatable/equatable.dart';

sealed class AppFailure extends Equatable {
  const AppFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'A network request could not be completed.',
  ]);
}

final class DataFormatFailure extends AppFailure {
  const DataFormatFailure([
    super.message = 'The received data could not be read.',
  ]);
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
