import 'package:alma_desktop/features/auth/data/models/user_model.dart';
import 'package:alma_desktop/features/auth/domain/entities/login_response.dart';

class LoginResponseModel extends LoginResponse {
  const LoginResponseModel({required super.accessToken, required super.user});

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // DioConsumer already extracts 'data' from the response
    // So json might be the data itself or contain 'data' key
    final data = json.containsKey('data')
        ? json['data'] as Map<String, dynamic>
        : json;

    return LoginResponseModel(
      accessToken: data['token'] as String,
      user: UserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {'token': accessToken, 'user': (user as UserModel).toJson()},
    };
  }
}
