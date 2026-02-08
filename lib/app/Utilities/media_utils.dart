import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class MediaResult {
  final bool success;
  final String? error;
  final String? fileName;
  final Uint8List? bytes;
  final String? mimeType;

  MediaResult({
    required this.success,
    this.error,
    this.fileName,
    this.bytes,
    this.mimeType,
  });
}

class MediaUtils {
  static Map<String, List<String>> allowedExtensions = {
    "Image": ["jpg", "jpeg", "png"],
    "Video": ["mp4", "3gp"],
    "Document": ["txt", "pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx"],
  };

  // -----------------------------------------------------------
  // 🔥 UNIVERSAL: Pick + Validate + Return file
  // -----------------------------------------------------------
  static Future<MediaResult> pickAndValidateFile({
    required String mediaType,
    int maxSizeMB = 10,
  }) async {
    if (mediaType.isEmpty || !allowedExtensions.containsKey(mediaType)) {
      return MediaResult(success: false, error: "Invalid media type.");
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions[mediaType],
      withData: true,
    );

    if (result == null) {
      return MediaResult(success: false, error: "No file selected.");
    }

    final file = result.files.first;
    final ext = file.extension?.toLowerCase() ?? "";

    // Validate
    final validation = validateFile(
      bytes: file.bytes!,
      extension: ext,
      maxSizeMB: maxSizeMB,
      allowedExtensions: allowedExtensions[mediaType]!,
    );

    if (!validation.success) return validation;

    return MediaResult(
      success: true,
      fileName: file.name,
      bytes: file.bytes,
      mimeType: getMimeFromExtension(ext),
    );
  }

  // -----------------------------------------------------------
  // 🔥 UNIVERSAL: Validate file (bytes + ext + size)
  // -----------------------------------------------------------
  static MediaResult validateFile({
    required Uint8List bytes,
    required String extension,
    required int maxSizeMB,
    required List<String> allowedExtensions,
  }) {
    // size check
    if (bytes.lengthInBytes > maxSizeMB * 1024 * 1024) {
      return MediaResult(
        success: false,
        error: "File must be under $maxSizeMB MB.",
      );
    }

    // extension check
    if (!allowedExtensions.contains(extension.toLowerCase())) {
      return MediaResult(success: false, error: "File format not allowed.");
    }

    return MediaResult(success: true);
  }

  // -----------------------------------------------------------
  // 🔥 UNIVERSAL: MIME Detector
  // -----------------------------------------------------------
  static String getMimeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case "jpg":
      case "jpeg":
        return "image/jpeg";
      case "png":
        return "image/png";
      case "mp4":
        return "video/mp4";
      case "3gp":
        return "video/3gpp";
      case "txt":
        return "text/plain";
      case "pdf":
        return "application/pdf";
      case "doc":
        return "application/msword";
      case "docx":
        return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
      case "ppt":
        return "application/vnd.ms-powerpoint";
      case "pptx":
        return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
      case "xls":
        return "application/vnd.ms-excel";
      case "xlsx":
        return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
      default:
        return "application/octet-stream";
    }
  }
}
