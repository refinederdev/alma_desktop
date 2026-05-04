import 'dart:convert';

import 'package:alma_desktop/core/services/local_storage_service/local_storage_service.dart';
import 'package:alma_desktop/features/auth/data/models/user_model.dart';
import 'package:alma_desktop/features/global/domain/entities/check_auth.dart';

abstract class GlobalLocalDataSource {
  Future<CheckAuth?> getCheckAuth();
}

class GlobalLocalDataSourceImpl extends GlobalLocalDataSource {
  final LocalStorageService localStorageService;

  GlobalLocalDataSourceImpl({required this.localStorageService});

  @override
  Future<CheckAuth?> getCheckAuth() async {
    final accessToken = localStorageService.getString('accessToken');
    final UserModel? user;
    if (localStorageService.getString('user') != null) {
      user = UserModel.fromJson(
        jsonDecode(localStorageService.getString('user') ?? '{}')
            as Map<String, dynamic>,
      );
    } else {
      user = null;
    }

    return CheckAuth(accessToken: accessToken, user: user);
  }
}
