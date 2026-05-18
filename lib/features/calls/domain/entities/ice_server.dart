import 'package:equatable/equatable.dart';

class IceServer extends Equatable {
  final List<String> urls;
  final String? username;
  final String? credential;

  const IceServer({
    required this.urls,
    this.username,
    this.credential,
  });

  @override
  List<Object?> get props => [urls, username, credential];
}
