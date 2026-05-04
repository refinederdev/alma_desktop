import 'dart:convert';

import 'package:alma_desktop/core/services/local_storage_service/local_storage_service.dart';
import 'package:alma_desktop/features/auth/data/models/user_model.dart';
import 'package:alma_desktop/features/auth/domain/entities/user.dart';

abstract class AuthLocalDataSource {
  Future<void> saveAccessToken(String accessToken);
  Future<String?> getAccessToken();
  Future<void> saveUser(User user);
  Future<User?> getUser();
}

class AuthLocalDataSourceImpl extends AuthLocalDataSource {
  final LocalStorageService localStorageService;

  AuthLocalDataSourceImpl({required this.localStorageService});

  @override
  Future<void> saveAccessToken(String accessToken) async {
    await localStorageService.setString('accessToken', accessToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return localStorageService.getString('accessToken');
  }

  @override
  Future<void> saveUser(User user) async {
    await localStorageService.setString(
      'user',
      jsonEncode((user as UserModel).toJson()),
    );
  }

  @override
  Future<User?> getUser() async {
    final user = localStorageService.getString('user');
    return user != null ? UserModel.fromJson(jsonDecode(user)) as User : null;
  }
}
