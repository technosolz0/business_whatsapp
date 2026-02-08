import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class UploadResult {
  final String id; // saved file id
  final String url; // url to download
  final String fileName; // saved file name in storage

  UploadResult({required this.id, required this.url, required this.fileName});
}

Future<UploadResult> uploadFileToFirebase({
  required Uint8List fileBytes,
  required String fileName,
  required String folder,
  required String mimeType,
}) async {
  try {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = FirebaseStorage.instance.ref('$folder/$id/$fileName');

    await ref.putData(fileBytes, SettableMetadata(contentType: mimeType));

    final url = await ref.getDownloadURL();

    return UploadResult(id: id, url: url, fileName: fileName);
  } catch (e) {
    //print("UPLOAD ERROR: $e");
    rethrow;
  }
}
