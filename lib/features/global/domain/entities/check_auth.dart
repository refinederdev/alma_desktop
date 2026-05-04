import 'package:alma_desktop/features/auth/domain/entities/user.dart';
import 'package:equatable/equatable.dart';

class CheckAuth extends Equatable {
  final String? accessToken;
  final User? user;

  const CheckAuth({this.accessToken, this.user});

  @override
  List<Object?> get props => [accessToken, user];
}
