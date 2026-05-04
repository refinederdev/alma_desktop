import 'dart:io';

import 'package:alma_desktop/core/api/api_consumer.dart';
import 'package:alma_desktop/features/auth/data/models/login_response_model.dart';
import 'package:alma_desktop/features/auth/data/models/user_model.dart';
import 'package:alma_desktop/features/auth/data/models/validate_otp_response_model.dart';
import 'package:dio/dio.dart' as dio;

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login({
    required String password,
    String? phone,
    String? email,
  });

  Future<String> forgetPassword({required String phone});

  Future<ValidateOtpResponseModel> validateOtp({
    required String phone,
    required String otp,
  });

  Future<String> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  });

  Future<UserModel> getMe();

  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? language,
    String? avatar,
  });

  Future<String> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });
}

class AuthRemoteDataSourceImpl extends AuthRemoteDataSource {
  final ApiConsumer apiConsumer;

  AuthRemoteDataSourceImpl({required this.apiConsumer});

  @override
  Future<LoginResponseModel> login({
    required String password,
    String? phone,
    String? email,
  }) async {
    final Map<String, dynamic> body = {'password': password};
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    } else if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }

    final response = await apiConsumer.post(
      'auth/login',
      body: body,
    );

    return LoginResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<String> forgetPassword({required String phone}) async {
    final response = await apiConsumer.post(
      'auth/forget-password',
      body: {'phone': phone},
    );

    // في حالة forget password، الاستجابة تحتوي على data: null
    // لذا _processResponse سيرجع responseData الكامل (لأن data هو null)
    // والرسالة موجودة في المستوى العلوي من الاستجابة
    if (response is Map<String, dynamic>) {
      // إذا كانت الرسالة موجودة في المستوى العلوي
      if (response.containsKey('message')) {
        return response['message'] as String;
      }
      // إذا كانت الرسالة موجودة في data (في حالة وجود data)
      if (response.containsKey('data') &&
          response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        if (data.containsKey('message')) {
          return data['message'] as String;
        }
      }
    }
    // إذا كانت الاستجابة null أو لا تحتوي على message، نرجع الرسالة الافتراضية
    return 'تم إرسال رمز التحقق عبر WhatsApp';
  }

  @override
  Future<ValidateOtpResponseModel> validateOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await apiConsumer.post(
      'auth/validate-otp',
      body: {'phone': phone, 'otp': otp},
    );

    return ValidateOtpResponseModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<String> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await apiConsumer.post(
      'auth/reset-password',
      body: {
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    // في حالة reset password، الاستجابة تحتوي على data: null
    // لذا _processResponse سيرجع responseData الكامل (لأن data هو null)
    // والرسالة موجودة في المستوى العلوي من الاستجابة
    if (response is Map<String, dynamic>) {
      // إذا كانت الرسالة موجودة في المستوى العلوي
      if (response.containsKey('message')) {
        return response['message'] as String;
      }
      // إذا كانت الرسالة موجودة في data (في حالة وجود data)
      if (response.containsKey('data') &&
          response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        if (data.containsKey('message')) {
          return data['message'] as String;
        }
      }
    }
    // إذا كانت الاستجابة null أو لا تحتوي على message، نرجع الرسالة الافتراضية
    return 'تم تغيير كلمة المرور بنجاح';
  }

  @override
  Future<UserModel> getMe() async {
    final response = await apiConsumer.get('user/me');
    // DioConsumer already extracts 'data' from the response
    // So response might be the data itself or contain 'data' key
    final data =
        response is Map<String, dynamic> && response.containsKey('data')
        ? response['data'] as Map<String, dynamic>
        : response as Map<String, dynamic>;
    // الاستجابة تأتي في شكل { "user": {...} }
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? language,
    String? avatar,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (language != null) body['language'] = language;

    // إضافة الصورة إذا كانت موجودة
    bool hasAvatar = false;
    if (avatar != null && avatar.isNotEmpty) {
      final file = File(avatar);
      if (await file.exists()) {
        final fileName = file.path.split('/').last;
        body['avatar'] = await dio.MultipartFile.fromFile(
          avatar,
          filename: fileName,
        );
        hasAvatar = true;
      }
    }

    // عند وجود avatar، يجب استخدام POST مع _method: 'PUT' لأن Laravel لا يتعامل مع PUT + FormData بشكل جيد
    final response = hasAvatar
        ? await apiConsumer.post(
            'user/profile',
            body: {...body, '_method': 'PUT'},
            isFormData: true,
          )
        : await apiConsumer.put(
            'user/profile',
            body: body.isNotEmpty ? body : null,
          );

    // الاستجابة تأتي في شكل { "user": {...} }
    final responseData = response as Map<String, dynamic>;
    return UserModel.fromJson(responseData['user'] as Map<String, dynamic>);
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await apiConsumer.put(
      'user/password',
      body: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    if (response is Map<String, dynamic>) {
      if (response.containsKey('message')) {
        return response['message'] as String;
      }
      if (response.containsKey('data') &&
          response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        if (data.containsKey('message')) {
          return data['message'] as String;
        }
      }
    }
    return 'تم تحديث كلمة المرور بنجاح';
  }
}
