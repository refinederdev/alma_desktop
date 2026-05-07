import 'dart:io';
import 'dart:convert';

import 'package:alma_desktop/core/config/app_config.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.checkError,
  });

  final String currentVersion;
  final String latestVersion;
  final String? downloadUrl;
  final String releaseNotes;
  final String? checkError;

  bool get hasUpdate =>
      checkError == null &&
      AppUpdateService
          ._normalizeVersion(latestVersion)
          .compareTo(AppUpdateService._normalizeVersion(currentVersion)) >
      0;
}

class AppUpdateService {
  AppUpdateService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

  final Dio _dio;

  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<UpdateInfo> checkForUpdate() async {
    final currentVersion = await getCurrentVersion();
    Object? manifestError;
    try {
      final manifest = await _fetchServerManifest();
      return _buildUpdateInfoFromManifest(
        currentVersion: currentVersion,
        manifest: manifest,
      );
    } catch (error) {
      manifestError = error;
      try {
        final files = await _fetchServerFilesFromDirectory();
        return _buildUpdateInfoFromDirectoryFiles(
          currentVersion: currentVersion,
          files: files,
        );
      } catch (directoryError) {
        final combinedError =
            'manifest=${_describeError(manifestError)}; '
            'directory=${_describeError(directoryError)}';
        return _safeNoUpdate(currentVersion, checkError: combinedError);
      }
    }
  }

  Future<String> downloadInstaller({
    required String url,
    required void Function(int received, int total) onProgress,
  }) async {
    final fileName = _extractFileNameFromUrl(url);
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
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    }
    throw const FormatException('Invalid updates manifest format.');
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
      checkError: null,
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
    final value = _sanitizeLink(href).toLowerCase();
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
    final match = RegExp(
      r'(?:^|[^0-9])v?(\d+\.\d+\.\d+(?:\.\d+)?)',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1);
  }

  String _toAbsoluteServerUrl(String href) {
    if (href.startsWith('http')) return href;
    final cleanHref = href.startsWith('/') ? href.substring(1) : href;
    return '${AppConfig.appUpdatesBaseUrl}/$cleanHref';
  }

  UpdateInfo _safeNoUpdate(String currentVersion, {String? checkError}) {
    return UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: currentVersion,
      downloadUrl: null,
      releaseNotes: '',
      checkError: checkError,
    );
  }

  String _extractFileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.pathSegments.isEmpty) return '';
    return uri.pathSegments.last;
  }

  String _sanitizeLink(String href) {
    final uri = Uri.tryParse(href);
    if (uri == null) return href;
    final sanitized = uri.replace(query: null, fragment: null);
    return sanitized.toString();
  }

  String _describeError(Object? error) {
    if (error == null) return 'unknown';
    if (error is DioException) {
      final code = error.response?.statusCode;
      final message = error.message?.trim();
      if (code != null && message != null && message.isNotEmpty) {
        return 'http:$code $message';
      }
      if (code != null) return 'http:$code';
      if (message != null && message.isNotEmpty) return message;
    }
    return error.toString();
  }
}
