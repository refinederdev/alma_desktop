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
    try {
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

      return _parseApiReleaseResponse(
        response: response,
        currentVersion: currentVersion,
      );
    } on DioException {
      // Fallback for environments where GitHub API is rate-limited/blocked.
      try {
        return _checkForUpdateFromReleasePage(currentVersion: currentVersion);
      } on DioException {
        try {
          return _checkForUpdateFromRawPubspec(currentVersion: currentVersion);
        } catch (_) {
          return _safeNoUpdate(currentVersion);
        }
      } catch (_) {
        try {
          return _checkForUpdateFromRawPubspec(currentVersion: currentVersion);
        } catch (_) {
          return _safeNoUpdate(currentVersion);
        }
      }
    } catch (_) {
      try {
        return _checkForUpdateFromRawPubspec(currentVersion: currentVersion);
      } catch (_) {
        return _safeNoUpdate(currentVersion);
      }
    }
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

  UpdateInfo _parseApiReleaseResponse({
    required Response<dynamic> response,
    required String currentVersion,
  }) {
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

  Future<UpdateInfo> _checkForUpdateFromReleasePage({
    required String currentVersion,
  }) async {
    final releasePageUrl =
        'https://github.com/${AppConfig.githubRepoOwner}/${AppConfig.githubRepoName}/releases/latest';
    final response = await _dio.get<String>(
      releasePageUrl,
      options: Options(
        headers: {'User-Agent': 'alma-desktop-updater'},
        responseType: ResponseType.plain,
      ),
    );

    final html = response.data ?? '';
    final preferredExt = _preferredAssetExtensions();
    String? downloadUrl;

    for (final ext in preferredExt) {
      final escapedExt = RegExp.escape(ext);
      final pattern = RegExp(
        r'href="([^"]*/releases/download/[^"]*' + escapedExt + r')"',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(html);
      if (match == null) continue;
      final raw = (match.group(1) ?? '').trim();
      if (raw.isEmpty) continue;
      downloadUrl = raw.startsWith('http') ? raw : 'https://github.com$raw';
      break;
    }

    String latestVersion = currentVersion;
    if (downloadUrl != null && downloadUrl.isNotEmpty) {
      final versionMatch = RegExp(
        r'v?(\d+\.\d+\.\d+)',
        caseSensitive: false,
      ).firstMatch(downloadUrl);
      if (versionMatch != null) {
        latestVersion = versionMatch.group(1) ?? currentVersion;
      }
    }

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: '',
    );
  }

  Future<UpdateInfo> _checkForUpdateFromRawPubspec({
    required String currentVersion,
  }) async {
    final rawPubspecUrl =
        'https://raw.githubusercontent.com/${AppConfig.githubRepoOwner}/${AppConfig.githubRepoName}/main/pubspec.yaml';
    final response = await _dio.get<String>(
      rawPubspecUrl,
      options: Options(
        headers: {'User-Agent': 'alma-desktop-updater'},
        responseType: ResponseType.plain,
      ),
    );

    final content = response.data ?? '';
    final versionMatch = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+[0-9]+)?\s*$',
      multiLine: true,
    ).firstMatch(content);
    final latestVersion = versionMatch?.group(1) ?? currentVersion;

    String? downloadUrl;
    if (Platform.isWindows) {
      final candidate =
          'https://github.com/${AppConfig.githubRepoOwner}/${AppConfig.githubRepoName}/releases/download/main/alma_desktop_setup_v$latestVersion.exe';
      if (await _isReachableDownload(candidate)) {
        downloadUrl = candidate;
      }
    } else if (Platform.isMacOS) {
      final candidate =
          'https://github.com/${AppConfig.githubRepoOwner}/${AppConfig.githubRepoName}/releases/download/main/alma_desktop-macos-setup-main.zip';
      if (await _isReachableDownload(candidate)) {
        downloadUrl = candidate;
      }
    }

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl,
      releaseNotes: '',
    );
  }

  Future<bool> _isReachableDownload(String url) async {
    try {
      final response = await _dio.head(
        url,
        options: Options(
          headers: {'User-Agent': 'alma-desktop-updater'},
          followRedirects: true,
          validateStatus: (code) => code != null && code >= 200 && code < 400,
        ),
      );
      return (response.statusCode ?? 500) < 400;
    } catch (_) {
      return false;
    }
  }

  UpdateInfo _safeNoUpdate(String currentVersion) {
    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      downloadUrl: null,
      releaseNotes: '',
    );
  }
}
