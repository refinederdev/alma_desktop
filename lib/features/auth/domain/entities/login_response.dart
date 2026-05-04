import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:equatable/equatable.dart';

class LoginResponse extends Equatable {
  final String accessToken;
  final User user;

  const LoginResponse({required this.accessToken, required this.user});

  @override
  List<Object?> get props => [accessToken, user];
}
