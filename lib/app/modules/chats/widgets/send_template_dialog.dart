import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/Utilities/network_utilities.dart';
import 'package:adminpanel/app/Utilities/utilities.dart';
import 'package:adminpanel/app/Utilities/media_utils.dart';
import 'package:adminpanel/app/common%20widgets/common_snackbar.dart';
import 'package:adminpanel/app/data/services/template_firebase_service.dart';
import 'package:adminpanel/app/data/services/broadcast_service.dart';
import 'package:adminpanel/app/modules/chats/controllers/chats_controller.dart';
import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:adminpanel/main.dart';
import 'package:adminpanel/app/data/models/template_params.dart';
import 'package:adminpanel/app/data/models/interactive_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';

class SendTemplateDialog extends StatefulWidget {
  final String chatId;
  final String phoneNumber;

  const SendTemplateDialog({
    super.key,
    required this.chatId,
    required this.phoneNumber,
  });

  @override
  State<SendTemplateDialog> createState() => _SendTemplateDialogState();
}

class _SendTemplateDialogState extends State<SendTemplateDialog> {
  final chatsController = Get.find<ChatsController>();

  bool isLoading = true;
  bool isSending = false;
  List<TemplateParamModel> templates = [];
  TemplateParamModel? selectedTemplate;

  // Controllers
  final Map<String, TextEditingController> paramControllers = {};

  // Interactive Buttons
  List<InteractiveButton> buttons = [];
  final Map<int, TextEditingController> buttonControllers = {};

  // Media State
  Uint8List? selectedFileBytes;
  String? selectedFileName;
  String? mediaId;
  bool isUploadingMedia = false;
  String? fileError;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    for (var c in paramControllers.values) {
      c.dispose();
    }
    for (var c in buttonControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        'https://getapprovedtemplates-d3b4t36f7q-uc.a.run.app',
        queryParameters: {'clientId': clientID},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final apiTemplates = response.data['data'] as List<dynamic>;

        setState(() {
          templates = apiTemplates.map((template) {
            return TemplateParamModel(
              id: template['id'].toString(),
              name: template['name'].toString(),
              language: 'en',
              headerVars: 0,
              bodyVars: 0,
              headerFormat: '',
              templateType: template['category'].toString(),
              category: template['category'].toString(),
              headerText: null,
              headerExamples: [],
              bodyText: '',
              bodyExamples: [],
              buttons: null,
              buttonVars: 0,
            );
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load templates');
      }
    } catch (e) {
      // debugPrint('Error loading templates: $e');
      if (mounted) {
        Utilities.showSnackbar(SnackType.ERROR, 'Failed to load templates');
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _onTemplateSelected(TemplateParamModel basicTemplate) async {
    setState(() {
      selectedTemplate = basicTemplate;
      isLoading = true;
      buttons = [];
      // Reset Media
      selectedFileBytes = null;
      selectedFileName = null;
      mediaId = null;
      fileError = null;
    });

    try {
      final fullTemplate = await TemplateFirestoreService.instance
          .getTemplateById(basicTemplate.id);

      if (fullTemplate != null) {
        setState(() {
          selectedTemplate = fullTemplate.copyWith(
            category: basicTemplate.category,
          );
          _initializeControllers(fullTemplate);
          isLoading = false;
        });
      }
    } catch (e) {
      // debugPrint('Error loading full template details: $e');
      if (mounted) {
        setState(() => isLoading = false);
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Failed to load template details',
        );
      }
    }
  }

  void _initializeControllers(TemplateParamModel template) {
    for (var c in paramControllers.values) {
      c.dispose();
    }
    paramControllers.clear();

    for (var c in buttonControllers.values) {
      c.dispose();
    }
    buttonControllers.clear();

    // Initialize Header Params (Only for TEXT)
    if (template.headerFormat == 'TEXT') {
      for (int i = 1; i <= template.headerVars; i++) {
        paramControllers['header_$i'] = TextEditingController();
      }
    }

    // Initialize Body Params
    for (int i = 1; i <= template.bodyVars; i++) {
      paramControllers['body_$i'] = TextEditingController();
    }

    // Initialize Buttons
    buttons = template.buttons ?? [];
    for (int i = 0; i < buttons.length; i++) {
      final btn = buttons[i];
      if (_needsInput(btn)) {
        String initialValue = "";
        if (btn.example != null && btn.example!.isNotEmpty) {
          initialValue = btn.example!.first;
        }
        buttonControllers[i] = TextEditingController(text: initialValue);
      }
    }
  }

  bool _needsInput(InteractiveButton btn) {
    if (btn.type == 'COPY_CODE') return true;
    if (btn.type == 'URL' && (btn.url?.contains('{{1}}') ?? false)) return true;
    return false;
  }

  String _getInputLabel(InteractiveButton btn) {
    if (btn.type == 'COPY_CODE') return 'Coupon Code';
    if (btn.type == 'URL') return 'Dynamic URL Param';
    if (btn.type == 'QUICK_REPLY') return 'Value';
    return 'Value';
  }

  Future<void> _pickFile() async {
    if (selectedTemplate == null) return;
    String format = selectedTemplate!.headerFormat.toUpperCase();
    String type = "";
    if (format == 'IMAGE') {
      type = "Image";
    } else if (format == 'VIDEO') {
      type = "Video";
    } else if (format == 'DOCUMENT') {
      type = "Document";
    }

    if (type.isEmpty) return;

    final result = await MediaUtils.pickAndValidateFile(
      mediaType: type,
      maxSizeMB: 10,
    );
    if (result.success) {
      setState(() {
        selectedFileBytes = result.bytes;
        selectedFileName = result.fileName;
        fileError = null;
        isUploadingMedia = true;
      });

      // Upload
      final res = await BroadcastService.instance.uploadBroadcastMedia(
        fileBytes: selectedFileBytes!,
        fileName: selectedFileName!,
        mimeType: result.mimeType!,
      );

      if (mounted) {
        setState(() => isUploadingMedia = false);
        if (res['success'] == true) {
          mediaId = res['media_id'];
        } else {
          fileError = "Upload failed: ${res['message'] ?? 'Unknown error'}";
          selectedFileBytes = null;
          selectedFileName = null;
        }
      }
    } else {
      setState(() => fileError = result.error);
    }
  }

  Future<void> _sendTemplate() async {
    if (selectedTemplate == null) return;

    setState(() => isSending = true);

    try {
      // Prepare Body Values
      final bodyValues = <String>[];
      for (int i = 1; i <= selectedTemplate!.bodyVars; i++) {
        bodyValues.add(paramControllers['body_$i']?.text ?? '');
      }

      // Prepare Header Variables
      dynamic headerVariables;
      final format = selectedTemplate!.headerFormat.toUpperCase();

      if (['IMAGE', 'VIDEO', 'DOCUMENT'].contains(format)) {
        if (mediaId == null) {
          throw "Please upload ${format.toLowerCase()} first.";
        }
        // Normalize type to Title Case (IMAGE -> Image)
        String typeStr = format[0] + format.substring(1).toLowerCase();

        headerVariables = {
          'type': typeStr,
          'data': {'mediaId': mediaId, 'fileName': selectedFileName},
        };
      } else {
        // TEXT
        final list = <String>[];
        for (int i = 1; i <= selectedTemplate!.headerVars; i++) {
          list.add(paramControllers['header_$i']?.text ?? '');
        }
        headerVariables = {
          'type': 'TEXT',
          'data': {'text': list},
        };
      }

      // Prepare Button Values
      final buttonVals = <Map<String, String>>[];
      for (int i = 0; i < buttons.length; i++) {
        final btn = buttons[i];
        String payload = "";

        if (btn.type == 'COPY_CODE') {
          payload = buttonControllers[i]?.text ?? "";
        } else if (btn.type == 'URL') {
          if (buttonControllers.containsKey(i)) {
            String val = buttonControllers[i]!.text.trim();
            payload = val.replaceAll(RegExp(r'^\/+'), '');
          }
        } else if (btn.type == 'QUICK_REPLY') {
          payload = btn.text;
        }

        buttonVals.add({"type": btn.type, "payload": payload});
      }

      // API Call
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        'https://sendwhatsapptemplatemessage-d3b4t36f7q-uc.a.run.app',
        data: {
          'clientId': clientID,
          'mobileNo': widget.phoneNumber,
          'template': selectedTemplate!.name,
          'language': selectedTemplate!.language,
          'type': selectedTemplate!.templateType == 'Text & Media'
              ? 'MEDIA'
              : selectedTemplate!.templateType,
          'bodyVariables': bodyValues,
          'headerVariables': headerVariables,
          'buttonVariables': buttonVals,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data['success'] == true) {
        try {
          // Construct resolved body for preview
          String resolvedBody = selectedTemplate!.bodyText;
          for (int i = 1; i <= selectedTemplate!.bodyVars; i++) {
            resolvedBody = resolvedBody.replaceAll(
              '{{$i}}',
              paramControllers['body_$i']?.text ?? '',
            );
          }

          final chatRef = FirebaseFirestore.instance
              .collection('chats')
              .doc(clientID)
              .collection('data')
              .doc(widget.chatId);

          // Extract Message ID
          String? wamid;
          if (data['data'] != null &&
              data['data']['messages'] != null &&
              (data['data']['messages'] as List).isNotEmpty) {
            wamid = data['data']['messages'][0]['id'];
          }

          final timestamp = FieldValue.serverTimestamp();

          final msgData = {
            'content': resolvedBody,
            'timestamp': timestamp,
            'isFromMe': true,
            'senderName': adminName.value ?? 'Admin', // Access RxString value
            'status': 'invocationSucceeded',
            'whatsappMessageId': wamid,
            'messageType': 'template',
            'templateName': selectedTemplate!.name,
            'caption': '',
          };

          // Add Message
          await chatRef.collection('messages').add(msgData);
          // Update Chat
          await chatRef.set({
            'lastMessage': resolvedBody,
            'lastMessageTime': timestamp,
          }, SetOptions(merge: true));
        } catch (e) {
          // debugPrint("Error saving chat msg: $e");
        }

        if (mounted) {
          Navigator.of(context).pop();
          Utilities.showSnackbar(
            SnackType.SUCCESS,
            'Template sent successfully',
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to send template');
      }
    } catch (e) {
      // debugPrint('Error sending template: $e');
      if (mounted) {
        Utilities.showSnackbar(SnackType.ERROR, 'Failed to send: $e');
      }
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerFormat = selectedTemplate?.headerFormat.toUpperCase() ?? '';
    final isMediaHeader = ['IMAGE', 'VIDEO', 'DOCUMENT'].contains(headerFormat);

    return Dialog(
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Send Template Message',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: isDark ? Colors.grey : Colors.black54,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Dropdown
            if (isLoading)
              const Center(child: CircleShimmer(size: 40))
            else
              DropdownButtonFormField<TemplateParamModel>(
                initialValue: templates.any((t) => t.id == selectedTemplate?.id)
                    ? templates.firstWhere((t) => t.id == selectedTemplate?.id)
                    : null,
                decoration: InputDecoration(
                  labelText: 'Select Template',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: templates.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(
                      '${t.name} - ${t.category}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _onTemplateSelected(val);
                },
              ),

            const SizedBox(height: 24),

            // Parameters Content
            if (!isLoading && selectedTemplate != null)
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      if (isMediaHeader) ...[
                        Text(
                          'Header Attachment ($headerFormat)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: isUploadingMedia ? null : _pickFile,
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: isDark
                                  ? Colors.grey[900]
                                  : Colors.grey[100],
                            ),
                            child: Center(
                              child: isUploadingMedia
                                  ? const CircleShimmer(size: 30)
                                  : mediaId != null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 32,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          selectedFileName ?? "File Uploaded",
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_upload,
                                          color: Colors.grey,
                                        ),
                                        Text("Click to Upload $headerFormat"),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        if (fileError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              fileError!,
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ] else if (selectedTemplate!.headerVars > 0) ...[
                        Text(
                          'Header Variables',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(selectedTemplate!.headerVars, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller:
                                  paramControllers['header_${index + 1}'],
                              decoration: InputDecoration(
                                labelText: '{{${index + 1}}}',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey[100],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      if (selectedTemplate!.bodyVars > 0) ...[
                        Text(
                          'Body Variables',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(selectedTemplate!.bodyVars, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: paramControllers['body_${index + 1}'],
                              decoration: InputDecoration(
                                labelText: '{{${index + 1}}}',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey[100],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Interactive Parameters
                      if (buttonControllers.isNotEmpty) ...[
                        Text(
                          'Interactive Parameters',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...buttons.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final btn = entry.value;
                          if (!buttonControllers.containsKey(idx)) {
                            return SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextField(
                              controller: buttonControllers[idx],
                              decoration: InputDecoration(
                                labelText:
                                    '${btn.type} - ${_getInputLabel(btn)}',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.grey[100],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (selectedTemplate == null ||
                        isSending ||
                        isLoading ||
                        isUploadingMedia)
                    ? null
                    : _sendTemplate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSending
                    ? const CircleShimmer(size: 20)
                    : const Text('Send Message'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
