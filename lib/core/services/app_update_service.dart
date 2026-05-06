import 'dart:io';

import 'package:alma_desktop/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  final String currentVersion;
  final String latestVersion;
  final String? downloadUrl;
  final String releaseNotes;

  bool get hasUpdate =>
      AppUpdateService
          ._normalizeVersion(latestVersion)
          .compareTo(AppUpdateService._normalizeVersion(currentVersion)) >
      0;
}

class AppUpdateService {
  AppUpdateService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  List<String> _preferredAssetExtensions() {
    if (Platform.isWindows) return const ['.exe'];
    if (Platform.isMacOS) return const ['.zip', '.pkg', '.dmg'];
    return const [];
  }

  Future<UpdateInfo> checkForUpdate() async {
    final currentVersion = await getCurrentVersion();
    final response = await _dio.get(
      AppConfig.latestReleaseApi,
      options: Options(
        headers: {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'alma-desktop-updater',
        },
      ),
    );

    final Map<String, dynamic> data =
        (response.data as Map).cast<String, dynamic>();
    final tag = (data['tag_name'] ?? '').toString().trim();
    final latestVersion = _stripVersionTag(tag);
    final notes = (data['body'] ?? '').toString();

    String? downloadUrl;
    final preferredExt = _preferredAssetExtensions();
    final assets = data['assets'];
    if (assets is List) {
      for (final dynamic asset in assets) {
        if (asset is! Map) continue;
        final fileName = (asset['name'] ?? '').toString().toLowerCase();
        if (preferredExt.isEmpty) break;
        if (!preferredExt.any((ext) => fileName.endsWith(ext))) continue;
        final url = (asset['browser_download_url'] ?? '').toString();
        if (url.isEmpty) continue;
        downloadUrl = url;
        break;
      }
    }

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion.isEmpty ? currentVersion : latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: notes,
    );
  }

  Future<String> downloadInstaller({
    required String url,
    required void Function(int received, int total) onProgress,
  }) async {
    final fileName = url.split('/').last.isNotEmpty ? url.split('/').last : '';
    final dir = await Directory.systemTemp.createTemp('alma_update_');
    final ext = fileName.contains('.') ? fileName.substring(fileName.lastIndexOf('.')) : '';
    final safeFileName =
        fileName.isNotEmpty ? fileName : 'alma_update_setup$ext';
    final savePath = '${dir.path}${Platform.pathSeparator}$safeFileName';
    await _dio.download(url, savePath, onReceiveProgress: onProgress);
    return savePath;
  }

  Future<void> installAndExit(String installerPath) async {
    if (Platform.isWindows) {
      await Process.start(
        installerPath,
        <String>['/VERYSILENT', '/NORESTART'],
        mode: ProcessStartMode.detached,
      );
      exit(0);
    }

    if (Platform.isMacOS) {
      // We can't safely replace a running .app automatically; for now we open
      // the downloaded file so user can install manually.
      await Process.start(
        'open',
        <String>[installerPath],
        mode: ProcessStartMode.detached,
      );
      return;
    }

    throw UnsupportedError('Platform not supported for app updates.');
  }

  static String _stripVersionTag(String input) {
    if (input.startsWith('v') || input.startsWith('V')) {
      return input.substring(1);
    }
    return input;
  }

  static String _normalizeVersion(String input) {
    final parts = input.split('.');
    final normalized = List<int>.generate(3, (index) {
      if (index >= parts.length) return 0;
      return int.tryParse(parts[index].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    });
    return normalized.map((e) => e.toString().padLeft(4, '0')).join('.');
  }
}
