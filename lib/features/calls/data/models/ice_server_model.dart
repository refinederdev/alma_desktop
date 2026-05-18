import 'package:alma_desktop/features/calls/domain/entities/ice_server.dart';

class IceServerModel extends IceServer {
  const IceServerModel({
    required super.urls,
    super.username,
    super.credential,
  });

  factory IceServerModel.fromJson(Map<String, dynamic> json) {
    final dynamic urlsRaw = json['urls'];
    List<String> urls;
    if (urlsRaw is List) {
      urls = urlsRaw.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    } else if (urlsRaw is String) {
      urls = [urlsRaw];
    } else {
      urls = const [];
    }
    return IceServerModel(
      urls: urls,
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'urls': urls.length == 1 ? urls.first : urls,
    };
    if (username != null) map['username'] = username;
    if (credential != null) map['credential'] = credential;
    return map;
  }
}
