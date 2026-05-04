import 'package:equatable/equatable.dart';

class ValidateOtpResponse extends Equatable {
  final String resetToken;

  const ValidateOtpResponse({required this.resetToken});

  @override
  List<Object?> get props => [resetToken];
}
