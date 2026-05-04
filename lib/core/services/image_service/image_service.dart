import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  Future<File?> pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Pick image from camera
  Future<File?> pickFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Let the user choose the source (camera or gallery)
  Future<File?> pickImage({required bool fromCamera}) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  /// Calculate file size and return it in a string format (MB, KB)
  String getFileSize(File file) {
    final int bytes = file.lengthSync();
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$bytes B';
    }
  }
}
