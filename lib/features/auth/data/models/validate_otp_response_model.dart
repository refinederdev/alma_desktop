import 'package:alma_desktop/features/auth/domain/entities/validate_otp_response.dart';

class ValidateOtpResponseModel extends ValidateOtpResponse {
  const ValidateOtpResponseModel({required super.resetToken});

  factory ValidateOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return ValidateOtpResponseModel(resetToken: json['reset_token'] as String);
  }

  Map<String, dynamic> toJson() => {'reset_token': resetToken};
}
