import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';

import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:business_whatsapp/app/modules/chat_bot/services/chat_bot_service.dart';
import 'package:business_whatsapp/app/data/models/question_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_saver/file_saver.dart';

class BotQuestionController extends GetxController {
  final _service = Get.find<ChatBotService>();

  final RxList<QuestionModel> questions = RxList<QuestionModel>([]);
  var isLoading = false.obs;
  var isDeleting = false.obs;

  // Controllers for the expanded response area
  final responseTextController = TextEditingController();
  var selectedResponseFiles = <PlatformFile>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Start listening to real data
    _service.getBotQuestionsStream().listen((data) {
      questions.assignAll(data);
    });
  }

  void loadMockQuestions() {
    // No longer needed
  }

  void toggleExpansion(int index) {
    final q = questions[index];

    // Requirement: open only one card at a time
    if (!q.isExpanded.value) {
      for (var question in questions) {
        question.isExpanded.value = false;
      }
      q.isExpanded.value = true;
    } else {
      q.isExpanded.value = false;
    }

    // Clear response data when opening/closing
    if (q.isExpanded.value) {
      responseTextController.clear();
      selectedResponseFiles.clear();

      // If already answered, populate for editing
      if (q.status == 'answered') {
        if (q.answerText != null) {
          responseTextController.text = q.answerText!;
        }
        if (q.attachments.isNotEmpty) {
          // Requirement: show only one file if multiple uploaded
          final firstFile = q.attachments.first;
          selectedResponseFiles.add(
            PlatformFile(
              name: firstFile['name'] ?? 'file',
              size: (firstFile['size'] is int)
                  ? firstFile['size']
                  : int.tryParse(firstFile['size']?.toString() ?? '0') ?? 0,
            ),
          );
        }
      }
    }
  }

  void confirmDeleteQuestion(int index) {
    Get.defaultDialog(
      title: "Delete Question",
      middleText:
          "Are you sure you want to delete this question? This action cannot be undone.",
      textConfirm: "Delete",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        Get.back();
        deleteQuestion(index);
      },
    );
  }

  Future<void> deleteQuestion(int index) async {
    if (isDeleting.value) return;
    final q = questions[index];
    try {
      isDeleting.value = true;
      isLoading.value = true;

      // 1. Delete associated files from the file store if they exist
      if (q.attachments.isNotEmpty) {
        for (var file in q.attachments) {
          final fileId = file['id']?.toString();
          if (fileId != null) {
            try {
              await _service.deleteDocument(id: fileId);
            } catch (e) {
              debugPrint("Failed to delete file $fileId from store: $e");
            }
          }
        }
      }

      // 2. Delete from Firestore
      await _service.deleteQuestion(questionId: q.id);

      Utilities.showSnackbar(
        SnackType.SUCCESS,
        'Question deleted successfully',
      );

      update();
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to delete question: $e');
    } finally {
      isDeleting.value = false;
      isLoading.value = false;
    }
  }

  Future<void> pickResponseFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Requirement: restriction to add only one file
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'xls', 'xlsx'],
    );

    if (result != null) {
      selectedResponseFiles.assignAll(result.files);
    }
  }

  void downloadResponseFile(int index, int qIndex) async {
    final q = questions[qIndex];
    if (index < 0 || index >= q.attachments.length) {
      Utilities.showSnackbar(SnackType.ERROR, 'File not found');

      return;
    }

    final file = q.attachments[index];
    final fileName = file['name']?.toString() ?? 'file.txt';
    final url = file['url']?.toString();
    final id = file['id']?.toString();

    // Special case for response.txt / response.md - generate local download from answer text
    if ((fileName == 'response.txt' || fileName == 'response.md') && q.answerText != null) {
      try {
        final Uint8List bytes;
        if (fileName == 'response.md') {
          final mdContentBuilder = StringBuffer();
          bool isFirstBlock = true;
          for (int i = 0; i < questions.length; i++) {
            final currentQ = questions[i];
            final qText = currentQ.question;
            String? aText;
            if (currentQ.id == q.id) {
              aText = q.answerText?.trim();
            } else {
              if (currentQ.status == 'answered' && currentQ.answerText != null && currentQ.answerText!.trim().isNotEmpty) {
                aText = currentQ.answerText!.trim();
              }
            }
            if (aText != null && aText.isNotEmpty && aText != '-') {
              if (!isFirstBlock) {
                mdContentBuilder.writeln();
              }
              mdContentBuilder.writeln("**Q: $qText**");
              mdContentBuilder.writeln("**A:** $aText");
              isFirstBlock = false;
            }
          }
          bytes = Uint8List.fromList(utf8.encode(mdContentBuilder.toString()));
        } else {
          bytes = Uint8List.fromList(utf8.encode(q.answerText!));
        }

        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          mimeType: MimeType.text,
        );
        return;
      } catch (e) {
        debugPrint("Error saving local $fileName: $e");
        // Fallback to normal download if local fails
      }
    }

    try {
      if (url != null && url.isNotEmpty) {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Utilities.showSnackbar(
            SnackType.ERROR,
            'Could not open download link',
          );
        }
      } else if (id != null && id.isNotEmpty) {
        // Constructing the download URL from the ID if no direct URL is stored
        final downloadUrl =
            "https://getdocumentfromfilesearchstore-d3b4t36f7q-uc.a.run.app?clientId=$clientID&id=$id";
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          Utilities.showSnackbar(
            SnackType.ERROR,
            'Download not available for this file',
          );
        }
      } else {
        Utilities.showSnackbar(
          SnackType.INFO,
          'File ID missing. Cannot download.',
        );
      }
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to download: $e');
    }
  }

  void removeResponseFile(int index, int qIndex) {
    final file = selectedResponseFiles[index];
    final q = questions[qIndex];

    // Check if this is an "existing" file from an already answered question
    bool isExistingFile = false;
    if (kIsWeb) {
      isExistingFile = file.bytes == null;
    } else {
      isExistingFile = file.bytes == null && file.path == null;
    }

    if (isExistingFile && q.status == 'answered') {
      // Requirement: show confirmation and delete from API + Firestore
      Get.defaultDialog(
        title: "Delete Attachment",
        middleText:
            "Delete this file from the server and reset question status to pending?",
        textConfirm: "Delete",
        textCancel: "Cancel",
        confirmTextColor: Colors.white,
        buttonColor: Colors.redAccent,
        onConfirm: () async {
          Get.back();
          await _deleteExistingResponseFile(file, q);
          selectedResponseFiles.removeAt(index);
        },
      );
    } else {
      selectedResponseFiles.removeAt(index);
    }
  }

  Future<void> _deleteExistingResponseFile(
    PlatformFile file,
    QuestionModel q,
  ) async {
    try {
      isDeleting.value = true;
      isLoading.value = true;

      // 1. Find the file metadata
      final matching = q.attachments.firstWhere(
        (a) => a['name'] == file.name,
        orElse: () => {},
      );

      final fileId = matching['id']?.toString();

      // 2. Delete from API
      if (fileId != null) {
        await _service.deleteDocument(id: fileId);
      }

      // 3. Update Firestore: remove answer and set status to pending
      await _service.updateQuestion(
        questionId: q.id,
        data: {
          'answer': FieldValue.delete(),
          'status': 'pending',
          'whenAnswered': FieldValue.delete(),
        },
      );

      // 4. Update local state
      q.status = 'pending';
      q.attachments.clear();
      q.attachmentNames.clear();

      Utilities.showSnackbar(
        SnackType.SUCCESS,
        'Attachment deleted and status reset to pending',
      );

      update();
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to delete file: $e');
    } finally {
      isDeleting.value = false;
      isLoading.value = false;
    }
  }

  Future<void> submitResponse(int index) async {
    if (isLoading.value) return;
    final responseText = responseTextController.text.trim();
    if (responseText.isEmpty && selectedResponseFiles.isEmpty) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Please provide a response or an attachment',
      );

      return;
    }

    // Requirement: Show popup if both text and file are provided
    if (responseText.isNotEmpty && selectedResponseFiles.isNotEmpty) {
      Get.defaultDialog(
        title: "Selection Conflict",
        middleText: "Please upload either a file OR enter text, not both.",
        textConfirm: "OK",
        buttonColor: AppColors.primary,
        confirmTextColor: Colors.white,
        onConfirm: () => Get.back(),
      );
      return;
    }

    try {
      debugPrint("Submitting response for index $index");
      isLoading.value = true;
      final q = questions[index];
      List<dio.MultipartFile> multipartFiles = [];
      List<Map<String, dynamic>> existingFiles = [];
      Uint8List? textBytes;
      String? newFileId;

      debugPrint(
        "Selected files: ${selectedResponseFiles.length}, text length: ${responseText.length}",
      );

      // 1. Prepare files for upload
      if (selectedResponseFiles.isNotEmpty) {
        for (var file in selectedResponseFiles) {
          bool isExistingFile = false;
          if (kIsWeb) {
            isExistingFile = file.bytes == null;
          } else {
            isExistingFile = file.bytes == null && file.path == null;
          }

          if (isExistingFile) {
            // This is an existing file from previous upload (already in Firestore)
            final matching = q.attachments.firstWhere(
              (a) => a['name'] == file.name,
              orElse: () => {},
            );
            if (matching.isNotEmpty) {
              existingFiles.add(matching);
            }
            continue;
          }

          if (kIsWeb) {
            if (file.bytes != null) {
              multipartFiles.add(
                dio.MultipartFile.fromBytes(file.bytes!, filename: file.name),
              );
            }
          } else {
            if (file.path != null) {
              multipartFiles.add(
                await dio.MultipartFile.fromFile(
                  file.path!,
                  filename: file.name,
                ),
              );
            } else if (file.bytes != null) {
              multipartFiles.add(
                dio.MultipartFile.fromBytes(file.bytes!, filename: file.name),
              );
            }
          }
        }
      } else if (responseText.isNotEmpty) {
        // Requirement: if admin enters text, convert it to an md file (containing all Q&As) and upload
        final mdContentBuilder = StringBuffer();
        bool isFirstBlock = true;
        for (int i = 0; i < questions.length; i++) {
          final currentQ = questions[i];
          final qText = currentQ.question;
          String? aText;
          if (i == index) {
            aText = responseText;
          } else {
            if (currentQ.status == 'answered' && currentQ.answerText != null && currentQ.answerText!.trim().isNotEmpty) {
              aText = currentQ.answerText!.trim();
            }
          }
          if (aText != null && aText.isNotEmpty && aText != '-') {
            if (!isFirstBlock) {
              mdContentBuilder.writeln();
            }
            mdContentBuilder.writeln("**Q: $qText**");
            mdContentBuilder.writeln("**A:** $aText");
            isFirstBlock = false;
          }
        }
        final mdContent = mdContentBuilder.toString();
        textBytes = Uint8List.fromList(utf8.encode(mdContent));

        final mdFile = dio.MultipartFile.fromBytes(
          textBytes,
          filename: 'response.md',
        );

        final existingMdAttachment = q.attachments.firstWhere(
          (a) => a['name'] == 'response.md',
          orElse: () => {},
        );
        final String? existingFileId = existingMdAttachment.isNotEmpty
            ? existingMdAttachment['id']?.toString()
            : null;

        if (existingFileId != null) {
          debugPrint("Updating existing response.md with ID: $existingFileId");
          final updateResult = await _service.updateDocument(
            isQnA: true,
            id: existingFileId,
            file: mdFile,
            description: "Response to: ${q.question}",
          );
          if (updateResult['success'] == true) {
            final data = updateResult['data'] as Map<String, dynamic>;
            newFileId = (data['id'] ?? existingFileId).toString();
          } else {
            throw Exception(updateResult['message'] ?? 'Failed to update response.md');
          }
        } else {
          debugPrint("Uploading response.md for the first time");
          final uploadResult = await _service.uploadDocuments(
            isQnA: true,
            files: [mdFile],
            description: "Response to: ${q.question}",
          );
          if (uploadResult['success'] == true) {
            final data = uploadResult['data'] as Map<String, dynamic>;
            final serverIds = (data['ids'] ?? data['fileIds'] ?? []) as List<dynamic>;
            if (serverIds.isNotEmpty) {
              newFileId = serverIds.first.toString();
            } else {
              throw Exception('Upload API did not return a file ID.');
            }
          } else {
            throw Exception(uploadResult['message'] ?? 'Failed to upload response.md');
          }
        }
      }

      Map<String, dynamic>? uploadResult;
      if (multipartFiles.isNotEmpty) {
        debugPrint("Uploading ${multipartFiles.length} files...");
        uploadResult = await _service.uploadDocuments(
          isQnA: true,
          files: multipartFiles,
          description: "Response to: ${q.question}",
        );
        debugPrint("Upload result: $uploadResult");
      }

      // 2. Prepare Firestore update data
      List<Map<String, dynamic>> finalFiles = [...existingFiles];
      List<String> finalFileIds = [];

      // Add existing file IDs if any
      for (var f in existingFiles) {
        if (f['id'] != null) finalFileIds.add(f['id'].toString());
      }

      if (newFileId != null) {
        finalFileIds.add(newFileId);
        finalFiles.add({
          'id': newFileId,
          'path': newFileId,
          'name': 'response.md',
          'size': textBytes?.length ?? 0,
          'type': 'md',
        });
      }

      if (uploadResult != null && uploadResult['success'] == true) {
        final data = uploadResult['data'] as Map<String, dynamic>;

        // Handle different possible key names from API (ids vs fileIds, files vs none)
        final serverIds =
            (data['ids'] ?? data['fileIds'] ?? []) as List<dynamic>;
        final serverFiles = (data['files'] ?? []) as List<dynamic>;

        if (serverFiles.isNotEmpty) {
          // If server already returned full file objects, use them
          for (var f in serverFiles) {
            final fileMap = Map<String, dynamic>.from(f as Map);
            // Ensure 'path' exists
            if (fileMap['path'] == null && fileMap['id'] != null) {
              fileMap['path'] = fileMap['id'];
            }
            finalFiles.add(fileMap);
            if (fileMap['id'] != null) {
              finalFileIds.add(fileMap['id'].toString());
            }
          }
        } else if (serverIds.isNotEmpty) {
          // If server only returned IDs, map them to our local sources
          if (selectedResponseFiles.isNotEmpty) {
            int uploadIdx = 0;
            for (var localFile in selectedResponseFiles) {
              bool isNew = false;
              if (kIsWeb) {
                isNew = localFile.bytes != null;
              } else {
                isNew = localFile.path != null || localFile.bytes != null;
              }

              if (isNew && uploadIdx < serverIds.length) {
                final id = serverIds[uploadIdx].toString();
                finalFileIds.add(id);
                finalFiles.add({
                  'id': id,
                  'path': id,
                  'name': localFile.name,
                  'size': localFile.size,
                  'type': localFile.extension ?? localFile.name.split('.').last,
                });
                uploadIdx++;
              }
            }
          }
          /*
          else if (responseText.isNotEmpty && serverIds.isNotEmpty) {
            // Text was converted to a file
            final id = serverIds[0].toString();
            finalFileIds.add(id);
            finalFiles.add({
              'id': id,
              'path': id,
              'name': 'response.md',
              'size': textBytes?.length ?? 0,
              'type': 'md',
            });
          }
          */
        }
      }

      // If we uploaded a text-based file, the type is now 'files'
      final bool hasFiles = finalFiles.isNotEmpty;

      Map<String, dynamic> answerMap = {
        'fileIds': finalFileIds,
        'type': hasFiles ? 'files' : 'text',
      };

      if (!hasFiles && responseText.isNotEmpty) {
        // This case shouldn't normally be hit now that we convert to file,
        // but keeping as fallback for pure text if needed.
        answerMap['text'] = responseText;
      } else {
        answerMap['files'] = finalFiles;
        // Also keep the original text in the map for easy display in UI
        if (responseText.isNotEmpty) {
          answerMap['text'] = responseText;
        }
      }

      Map<String, dynamic> updateData = {
        'answer': answerMap,
        'status': 'answered',
        'whenAnswered': FieldValue.serverTimestamp(),
      };

      // 3. Update in Firestore
      debugPrint("Updating Firestore with data: $updateData");
      await _service.updateQuestion(questionId: q.id, data: updateData);
      debugPrint("Firestore update successful");

      // Close the card
      q.isExpanded.value = false;

      // Clear response data after submission
      responseTextController.clear();
      selectedResponseFiles.clear();

      Utilities.showSnackbar(
        SnackType.SUCCESS,
        responseText.isNotEmpty
            ? 'Response submitted and Markdown uploaded successfully'
            : 'Response submitted successfully',
      );

      // Explicitly trigger a refresh of the UI
      update();
    } catch (e, stack) {
      debugPrint("Error in submitResponse: $e");
      debugPrint(stack.toString());
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to submit: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearAndDownload(int index) async {
    responseTextController.clear();
    selectedResponseFiles.clear();

    final q = questions[index];

    final existingMdAttachment = q.attachments.firstWhere(
      (a) => a['name'] == 'response.md',
      orElse: () => {},
    );
    final String? existingFileId = existingMdAttachment.isNotEmpty
        ? existingMdAttachment['id']?.toString()
        : null;

    try {
      if (existingFileId != null) {
        debugPrint("Deleting response.md from file search store with ID: $existingFileId");
        await _service.deleteDocument(id: existingFileId);
      }

      // Clear/Reset this question in Firestore
      await _service.updateQuestion(
        questionId: q.id,
        data: {
          'answer': FieldValue.delete(),
          'status': 'pending',
          'whenAnswered': FieldValue.delete(),
        },
      );

      // Update the local state
      q.status = 'pending';
      q.answerText = null;
      q.attachments.clear();
      q.attachmentNames.clear();

      // Close the card
      q.isExpanded.value = false;

      Utilities.showSnackbar(
        SnackType.SUCCESS,
        'Response cleared and updated in Firestore',
      );
      update();
    } catch (e) {
      debugPrint("Error clearing response: $e");
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to clear response: $e');
    }
  }
}
