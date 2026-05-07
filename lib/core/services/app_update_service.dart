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

  Future<UpdateInfo> checkForUpdate() async {
    final currentVersion = await getCurrentVersion();
    try {
      final manifest = await _fetchServerManifest();
      return _buildUpdateInfoFromManifest(
        currentVersion: currentVersion,
        manifest: manifest,
      );
    } catch (_) {
      try {
        final files = await _fetchServerFilesFromDirectory();
        return _buildUpdateInfoFromDirectoryFiles(
          currentVersion: currentVersion,
          files: files,
        );
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
    final cleanedInput = input.trim();
    // Ignore SemVer build metadata/prerelease (e.g. 0.1.2+1, 1.0.0-beta.1)
    // so numeric comparison is consistent across installed/app store formats.
    final comparablePart =
        cleanedInput.split('+').first.split('-').first.trim();
    final parts = comparablePart.split('.');
    final normalized = List<int>.generate(3, (index) {
      if (index >= parts.length) return 0;
      return int.tryParse(parts[index].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    });
    return normalized.map((e) => e.toString().padLeft(4, '0')).join('.');
  }

  Future<Map<String, dynamic>> _fetchServerManifest() async {
    final manifestUrl = '${AppConfig.appUpdatesBaseUrl}/latest.json';
    final response = await _dio.get(
      manifestUrl,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'alma-desktop-updater',
        },
      ),
    );
    return (response.data as Map).cast<String, dynamic>();
  }

  UpdateInfo _buildUpdateInfoFromManifest({
    required String currentVersion,
    required Map<String, dynamic> manifest,
  }) {
    final manifestVersion = _stripVersionTag(
      (manifest['version'] ?? '').toString().trim(),
    );
    final latestVersion = manifestVersion.isEmpty ? currentVersion : manifestVersion;

    String? downloadUrl;
    if (Platform.isWindows) {
      downloadUrl = (manifest['windows_url'] ?? '').toString().trim();
    } else if (Platform.isMacOS) {
      downloadUrl =
          ((manifest['macos_url'] ?? manifest['mac_url']) ?? '').toString().trim();
    }

    if (downloadUrl != null && downloadUrl.isNotEmpty && !downloadUrl.startsWith('http')) {
      final normalized = downloadUrl.startsWith('/') ? downloadUrl.substring(1) : downloadUrl;
      downloadUrl = '${AppConfig.appUpdatesBaseUrl}/$normalized';
    }

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      downloadUrl: downloadUrl == null || downloadUrl.isEmpty ? null : downloadUrl,
      releaseNotes: (manifest['notes'] ?? '').toString(),
    );
  }

  Future<List<String>> _fetchServerFilesFromDirectory() async {
    final response = await _dio.get<String>(
      '${AppConfig.appUpdatesBaseUrl}/',
      options: Options(
        headers: {'User-Agent': 'alma-desktop-updater'},
        responseType: ResponseType.plain,
      ),
    );

    final html = response.data ?? '';
    final matches = RegExp(r'href="([^"]+)"', caseSensitive: false).allMatches(html);
    final files = <String>[];
    for (final match in matches) {
      final href = (match.group(1) ?? '').trim();
      if (href.isEmpty || href.startsWith('?') || href.startsWith('#')) continue;
      files.add(href);
    }
    return files;
  }

  UpdateInfo _buildUpdateInfoFromDirectoryFiles({
    required String currentVersion,
    required List<String> files,
  }) {
    final platformFiles = files.where(_isPlatformFile).toList();
    if (platformFiles.isEmpty) return _safeNoUpdate(currentVersion);

    String? bestUrl;
    String bestVersion = currentVersion;
    for (final file in platformFiles) {
      final version = _extractVersionFromText(file);
      if (version == null) continue;
      if (_normalizeVersion(version).compareTo(_normalizeVersion(bestVersion)) <= 0) {
        continue;
      }
      bestVersion = version;
      bestUrl = file;
    }

    if (bestUrl == null) return _safeNoUpdate(currentVersion);

    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: bestVersion,
      downloadUrl: _toAbsoluteServerUrl(bestUrl),
      releaseNotes: '',
    );
  }

  bool _isPlatformFile(String href) {
    final value = href.toLowerCase();
    if (Platform.isWindows) {
      return value.endsWith('.exe');
    }
    if (Platform.isMacOS) {
      if (!(value.endsWith('.zip') || value.endsWith('.dmg') || value.endsWith('.pkg'))) {
        return false;
      }
      return value.contains('mac');
    }
    return false;
  }

  String? _extractVersionFromText(String text) {
    final match = RegExp(r'v(\d+\.\d+\.\d+)', caseSensitive: false).firstMatch(text);
    return match?.group(1);
  }

  String _toAbsoluteServerUrl(String href) {
    if (href.startsWith('http')) return href;
    final cleanHref = href.startsWith('/') ? href.substring(1) : href;
    return '${AppConfig.appUpdatesBaseUrl}/$cleanHref';
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
