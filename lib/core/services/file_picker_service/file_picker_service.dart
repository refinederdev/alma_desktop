import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FilePickerService {
  /// Pick a single file of any type
  Future<File?> pickSingleFile() async {
    final FilePickerResult? result = await FilePicker.pickFiles();

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Pick multiple files of any type
  Future<List<File>?> pickMultipleFiles() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      return result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();
    }
    return null;
  }

  /// Pick files with specific extensions
  Future<File?> pickFileWithExtensions({
    required List<String> allowedExtensions,
  }) async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Pick multiple files with specific extensions
  Future<List<File>?> pickMultipleFilesWithExtensions({
    required List<String> allowedExtensions,
  }) async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: true,
    );

    if (result != null) {
      return result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();
    }
    return null;
  }

  /// Pick image files only
  Future<File?> pickImage() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Pick multiple image files
  Future<List<File>?> pickMultipleImages() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      return result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();
    }
    return null;
  }

  /// Pick video files only
  Future<File?> pickVideo() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Pick multiple video files
  Future<List<File>?> pickMultipleVideos() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null) {
      return result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();
    }
    return null;
  }

  /// Pick audio files only
  Future<File?> pickAudio() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Pick multiple audio files
  Future<List<File>?> pickMultipleAudio() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      return result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();
    }
    return null;
  }

  /// Pick media files (images and videos)
  Future<File?> pickMedia() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.media,
    );

    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Pick multiple media files (images and videos)
  Future<List<File>?> pickMultipleMedia() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.media,
      allowMultiple: true,
    );

    if (result != null) {
      return result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();
    }
    return null;
  }

  /// Calculate file size and return it in a string format (GB, MB, KB, B)
  String getFileSize(File file) {
    final int bytes = file.lengthSync();
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }

  /// Get file name from path
  String getFileName(File file) {
    return file.path.split('/').last;
  }

  /// Get file extension
  String getFileExtension(File file) {
    final fileName = getFileName(file);
    final lastDotIndex = fileName.lastIndexOf('.');
    if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1) {
      return fileName.substring(lastDotIndex + 1).toLowerCase();
    }
    return '';
  }

  /// Check if file is an image
  bool isImageFile(File file) {
    final extension = getFileExtension(file);
    return [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'svg',
    ].contains(extension);
  }

  /// Check if file is a video
  bool isVideoFile(File file) {
    final extension = getFileExtension(file);
    return [
      'mp4',
      'avi',
      'mkv',
      'mov',
      'wmv',
      'flv',
      'webm',
      'm4v',
    ].contains(extension);
  }

  /// Check if file is a document
  bool isDocumentFile(File file) {
    final extension = getFileExtension(file);
    return [
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'odt',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ].contains(extension);
  }

  /// Get appropriate icon name for file type (for Solar Icons)
  String getFileIcon(File file) {
    final extension = getFileExtension(file);

    if (isImageFile(file)) {
      return 'gallery';
    } else if (isVideoFile(file)) {
      return 'videocamera';
    } else if (['pdf'].contains(extension)) {
      return 'documentText';
    } else if (['doc', 'docx', 'txt', 'rtf', 'odt'].contains(extension)) {
      return 'document';
    } else if (['xls', 'xlsx'].contains(extension)) {
      return 'document';
    } else if (['ppt', 'pptx'].contains(extension)) {
      return 'document';
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return 'archive';
    } else if (['mp3', 'wav', 'flac', 'aac', 'ogg'].contains(extension)) {
      return 'musicNote';
    } else {
      return 'document';
    }
  }
}
