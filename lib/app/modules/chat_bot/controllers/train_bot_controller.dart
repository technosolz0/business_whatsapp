import 'dart:core';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:file_saver/file_saver.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/Utilities/utilities.dart';
import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:business_whatsapp/app/modules/chat_bot/services/chat_bot_service.dart';
import 'package:business_whatsapp/app/modules/chat_bot/models/service_block.dart';
import 'package:business_whatsapp/app/modules/chat_bot/models/faq_block.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TrainBotController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatBotService _chatBotService = Get.find<ChatBotService>();

  // Section 3: Products, Services & Pricing state
  final servicesList = <ServiceBlock>[].obs;
  final uploadedCatalog = <String, dynamic>{}.obs;
  var isProductsExpanded = false.obs;
  var isUploadingCatalog = false.obs;

  // Section 4: Policies & Operations state
  final shippingPolicyController = TextEditingController();
  final returnPolicyController = TextEditingController();
  final guaranteesController = TextEditingController();
  final selectedPaymentMethods = <String>[].obs;
  var isPoliciesExpanded = false.obs;

  // Section 5: The "Day 1" FAQ state
  final faqList = <FAQBlock>[].obs;
  var isFaqExpanded = false.obs;

  // Form Text Controllers
  final businessNameController = TextEditingController();
  final primaryLocationTopController = TextEditingController();
  final elevatorPitchController = TextEditingController();
  final primaryLocationAddressController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final buySignalsController = TextEditingController();

  // Character counter for elevator pitch
  var elevatorPitchCharCount = 0.obs;

  // Operating Hours state
  var operatingHours = 'Edit Your 7-Day Schedule'.obs;

  // Schedule map to hold the custom schedule
  var customSchedule = <String, Map<String, dynamic>>{}.obs;

  // Timezone setting
  var botTimezone = 'PST (Pacific Standard Time)'.obs;

  // UI state for expansion
  var isIdentityExpanded = true.obs;
  var isLeadExpanded = false.obs;

  // Lead qualification selection state
  var botGoal = 'Book a consultation'.obs;

  // Saved profile markdown file IDs
  var profileFileIds = <String>[].obs;

  // Loading and saving states
  var isLoading = false.obs;
  var isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    initDefaultSchedule();
    loadBotSettings();
  }

  @override
  void onClose() {
    businessNameController.dispose();
    primaryLocationTopController.dispose();
    elevatorPitchController.dispose();
    primaryLocationAddressController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    buySignalsController.dispose();
    for (var s in servicesList) {
      s.dispose();
    }
    shippingPolicyController.dispose();
    returnPolicyController.dispose();
    guaranteesController.dispose();
    for (var f in faqList) {
      f.dispose();
    }
    super.onClose();
  }

  void initDefaultSchedule() {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    for (var day in days) {
      customSchedule[day] = {
        'enabled': day != 'Saturday' && day != 'Sunday',
        'startTime': '09:00 AM',
        'endTime': '05:00 PM',
      };
    }
  }

  Future<void> loadBotSettings() async {
    try {
      isLoading.value = true;
      final doc = await _firestore.collection('bot_settings').doc(clientID).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          businessNameController.text = data['businessName'] ?? '';
          primaryLocationTopController.text = data['primaryLocationTop'] ?? '';
          elevatorPitchController.text = data['elevatorPitch'] ?? '';
          elevatorPitchCharCount.value = elevatorPitchController.text.length;
          primaryLocationAddressController.text = data['primaryLocationAddress'] ?? '';
          phoneNumberController.text = data['phoneNumber'] ?? '';
          emailController.text = data['email'] ?? '';
          operatingHours.value = data['operatingHours'] ?? 'Edit Your 7-Day Schedule';
          botGoal.value = data['botGoal'] ?? 'Book a consultation';
          buySignalsController.text = data['buySignals'] ?? '';
          botTimezone.value = data['timezone'] ?? 'PST (Pacific Standard Time)';
          
          final savedIdsRaw = data['fileIds'] ?? data['profileFileIds'];
          if (savedIdsRaw != null) {
            final List<dynamic> savedIds = savedIdsRaw;
            profileFileIds.assignAll(savedIds.map((id) => id.toString()).toList());
          } else {
            profileFileIds.clear();
          }
          
          if (data['customSchedule'] != null) {
            final Map<String, dynamic> savedSchedule = data['customSchedule'];
            savedSchedule.forEach((key, value) {
              if (value is Map) {
                customSchedule[key] = Map<String, dynamic>.from(value);
              }
            });
          }

          if (data['services'] != null) {
            final List<dynamic> savedServices = data['services'];
            servicesList.clear();
            for (var s in savedServices) {
              if (s is Map) {
                servicesList.add(ServiceBlock(
                  name: s['name'] ?? '',
                  price: s['price'] ?? '',
                  desc: s['description'] ?? '',
                ));
              }
            }
          }
          if (servicesList.isEmpty) {
            servicesList.add(ServiceBlock());
          }

          if (data['catalog'] != null) {
            uploadedCatalog.assignAll(Map<String, dynamic>.from(data['catalog']));
          } else {
            uploadedCatalog.clear();
          }

          shippingPolicyController.text = data['shippingPolicy'] ?? '';
          returnPolicyController.text = data['returnPolicy'] ?? '';
          guaranteesController.text = data['guarantees'] ?? '';
          
          if (data['paymentMethods'] != null) {
            final List<dynamic> savedMethods = data['paymentMethods'];
            selectedPaymentMethods.assignAll(savedMethods.map((m) => m.toString()).toList());
          } else {
            selectedPaymentMethods.clear();
          }

          if (data['faqs'] != null) {
            final List<dynamic> savedFaqs = data['faqs'];
            faqList.clear();
            for (var f in savedFaqs) {
              if (f is Map) {
                faqList.add(FAQBlock(
                  question: f['question'] ?? '',
                  answer: f['answer'] ?? '',
                ));
              }
            }
          }
          if (faqList.isEmpty) {
            faqList.add(FAQBlock());
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading bot settings: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveBotSettings() async {
    if (isSaving.value) return;

    // Validate Email (if not empty)
    final emailVal = emailController.text.trim();
    if (emailVal.isNotEmpty) {
      final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
      if (!emailRegex.hasMatch(emailVal)) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Please enter a valid email address.',
        );
        return;
      }
    }

    // Validate Phone Number (if not empty)
    final phoneVal = phoneNumberController.text.trim();
    if (phoneVal.isNotEmpty) {
      final phoneRegex = RegExp(r"^\+?[0-9\s\-()]{7,16}$");
      if (!phoneRegex.hasMatch(phoneVal)) {
        Utilities.showSnackbar(
          SnackType.ERROR,
          'Please enter a valid phone number (7 to 16 digits).',
        );
        return;
      }
    }

    try {
      isSaving.value = true;

      // 1. Generate and upload/update markdown profile file
      final mdContent = _generateMarkdownContent();
      final bytes = utf8.encode(mdContent);
      final businessName = businessNameController.text.trim();
      final formattedName = businessName.isEmpty 
          ? "company" 
          : businessName.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      final fileName = '${formattedName}_profile.md';

      final mdFile = dio.MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      );

      if (profileFileIds.isNotEmpty) {
        // Use update API
        final updateResult = await _chatBotService.updateDocument(
          isQnA: false,
          id: profileFileIds.first,
          file: mdFile,
          description: 'Company Profile Markdown',
        );
        if (updateResult['success'] == true) {
          final data = updateResult['data'] as Map<String, dynamic>;
          final newId = data['id']?.toString();
          if (newId != null) {
            profileFileIds.assignAll([newId]);
          } else {
            throw Exception('Update API did not return a file ID.');
          }
        } else {
          throw Exception(updateResult['message'] ?? 'Failed to update markdown file.');
        }
      } else {
        // Use upload API
        final uploadResult = await _chatBotService.uploadDocuments(
          isQnA: false,
          files: [mdFile],
          description: 'Company Profile Markdown',
        );
        if (uploadResult['success'] == true) {
          final data = uploadResult['data'] as Map<String, dynamic>;
          final serverIds = (data['ids'] ?? data['fileIds'] ?? []) as List<dynamic>;
          if (serverIds.isNotEmpty) {
            profileFileIds.assignAll(serverIds.map((id) => id.toString()).toList());
          } else {
            throw Exception('Upload API did not return a file ID.');
          }
        } else {
          throw Exception(uploadResult['message'] ?? 'Failed to upload markdown file.');
        }
      }

      // 2. Save settings and profile IDs to Firestore
      final docRef = _firestore.collection('bot_settings').doc(clientID);

      await docRef.set({
        'businessName': businessNameController.text,
        'primaryLocationTop': primaryLocationTopController.text,
        'elevatorPitch': elevatorPitchController.text,
        'primaryLocationAddress': primaryLocationAddressController.text,
        'phoneNumber': phoneNumberController.text,
        'email': emailController.text,
        'operatingHours': operatingHours.value,
        'customSchedule': customSchedule,
        'timezone': botTimezone.value,
        'botGoal': botGoal.value,
        'buySignals': buySignalsController.text,
        'services': servicesList.map((s) => s.toMap()).toList(),
        'catalog': uploadedCatalog.isNotEmpty ? Map<String, dynamic>.from(uploadedCatalog) : FieldValue.delete(),
        'shippingPolicy': shippingPolicyController.text,
        'returnPolicy': returnPolicyController.text,
        'guarantees': guaranteesController.text,
        'paymentMethods': selectedPaymentMethods.toList(),
        'faqs': faqList.map((f) => f.toMap()).toList(),
        'profileFileIds': profileFileIds.toList(), // We can keep this or keep both for compatibility
        'fileIds': profileFileIds.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Utilities.showSnackbar(
        SnackType.SUCCESS,
        'Bot profile trained and updated successfully!',
      );
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to save bot settings: $e',
      );
    } finally {
      isSaving.value = false;
    }
  }

  String _generateMarkdownContent() {
    final businessName = businessNameController.text.trim().isEmpty 
        ? "-" 
        : businessNameController.text.trim();
        
    final summary = elevatorPitchController.text.trim().isEmpty
        ? "-" 
        : elevatorPitchController.text.trim();
        
    final location = primaryLocationAddressController.text.trim().isEmpty
        ? (primaryLocationTopController.text.trim().isEmpty 
            ? "-" 
            : primaryLocationTopController.text.trim())
        : primaryLocationAddressController.text.trim();

    final buySignals = buySignalsController.text.trim().isEmpty
        ? "-" 
        : buySignalsController.text.trim();

    final sb = StringBuffer();
    sb.writeln('# Company Profile: $businessName');
    sb.writeln();
    sb.writeln('## Core Information');
    sb.writeln('- **Business Name:** $businessName');
    sb.writeln('- **Summary:** $summary');
    sb.writeln('- **Location:** $location');
    sb.writeln('- **Timezone:** ${botTimezone.value}');
    sb.writeln();
    sb.writeln('## Operating Hours');
    
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    bool isDefault = true;
    for (var day in days) {
      final config = customSchedule[day];
      if (config != null) {
        final enabled = config['enabled'] ?? false;
        final start = config['startTime'] ?? '09:00 AM';
        final end = config['endTime'] ?? '05:00 PM';
        if (day == 'Saturday' || day == 'Sunday') {
          if (enabled) isDefault = false;
        } else {
          if (!enabled || start != '09:00 AM' || end != '05:00 PM') isDefault = false;
        }
      }
    }
    
    if (isDefault) {
      sb.writeln('- **Monday to Friday:** 09:00 AM - 05:00 PM');
      sb.writeln('- **Weekends:** Closed');
      sb.writeln('- **Holidays:** Standard national holidays observed.');
    } else {
      for (var day in days) {
        final config = customSchedule[day];
        if (config != null) {
          final enabled = config['enabled'] ?? false;
          final start = config['startTime'] ?? '09:00 AM';
          final end = config['endTime'] ?? '05:00 PM';
          sb.writeln('- **$day:** ${enabled ? "$start - $end" : "Closed"}');
        }
      }
      sb.writeln('- **Holidays:** Standard national holidays observed.');
    }
    sb.writeln();
    sb.writeln('## Lead Qualification Criteria');
    sb.writeln('- A user is a highly qualified lead if they ask about: "$buySignals"');
    sb.writeln();
    sb.writeln('## Services & Pricing');
    sb.writeln('| Service Name | Description | Base Price | Turnaround Time |');
    sb.writeln('| :--- | :--- | :--- | :--- |');
    
    bool hasServices = false;
    for (var service in servicesList) {
      final name = service.nameController.text.trim();
      final desc = service.descController.text.trim();
      final price = service.priceController.text.trim();
      if (name.isNotEmpty || desc.isNotEmpty || price.isNotEmpty) {
        sb.writeln('| ${name.isEmpty ? "-" : name} | ${desc.isEmpty ? "-" : desc} | ${price.isEmpty ? "-" : price} | - |');
        hasServices = true;
      }
    }
    if (!hasServices) {
      sb.writeln('| - | - | - | - |');
    }
    sb.writeln();
    sb.writeln('## Policies & Operations');
    
    final shipping = shippingPolicyController.text.trim();
    sb.writeln('### Shipping & Delivery');
    sb.writeln(shipping.isEmpty ? "-" : shipping);
    sb.writeln();
    
    final returnPolicy = returnPolicyController.text.trim();
    sb.writeln('### Cancellation Policy');
    sb.writeln(returnPolicy.isEmpty ? "-" : returnPolicy);
    sb.writeln();
    
    final guarantees = guaranteesController.text.trim();
    sb.writeln('### Guarantees & Warranties');
    sb.writeln(guarantees.isEmpty ? "-" : guarantees);
    sb.writeln();
    
    sb.writeln('### Payment Terms');
    sb.writeln('We require a 50% advance for project-based work, with the remainder due upon completion. Monthly retainers are billed on the 1st of every month.');
    final methodsStr = selectedPaymentMethods.isEmpty 
        ? "-" 
        : selectedPaymentMethods.join(", ");
    sb.writeln('Accepted methods: $methodsStr.');
    sb.writeln();
    
    final email = emailController.text.trim().isEmpty 
        ? "-" 
        : emailController.text.trim();
    final phone = phoneNumberController.text.trim().isEmpty 
        ? "-" 
        : phoneNumberController.text.trim();
    sb.writeln('### Escalation Contact');
    sb.writeln('If a customer demands a human manager immediately, route them to: $email or $phone.');
    
    bool hasFaq = false;
    for (var faq in faqList) {
      final q = faq.questionController.text.trim();
      final a = faq.answerController.text.trim();
      if (q.isNotEmpty || a.isNotEmpty) {
        if (!hasFaq) {
          sb.writeln();
          sb.writeln('## Frequently Asked Questions');
          hasFaq = true;
        }
        sb.writeln('### ${q.isEmpty ? "Question" : q}');
        sb.writeln(a.isEmpty ? "Answer" : a);
        sb.writeln();
      }
    }
    return sb.toString();
  }

  Future<void> downloadProfileMarkdown() async {
    final businessName = businessNameController.text.trim().isEmpty 
        ? "-" 
        : businessNameController.text.trim();
        
    final content = _generateMarkdownContent();

    try {
      final bytes = utf8.encode(content);
      final formattedName = businessName.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(RegExp(r'\s+'), '_').toLowerCase();
      final fileName = businessName.trim().isEmpty || businessName == "-" 
          ? "company_profile.md" 
          : "${formattedName}_profile.md";
      
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        mimeType: MimeType.text,
      );
      
      Utilities.showSnackbar(
        SnackType.SUCCESS,
        'Profile markdown downloaded successfully!',
      );
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to download markdown: $e',
      );
    }
  }

  void addServiceBlock() {
    servicesList.add(ServiceBlock());
  }

  void removeServiceBlock(int index) {
    if (index >= 0 && index < servicesList.length) {
      servicesList[index].dispose();
      servicesList.removeAt(index);
    }
  }

  Future<void> pickAndUploadCatalog() async {
    if (isUploadingCatalog.value) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        isUploadingCatalog.value = true;
        final file = result.files.first;

        List<dio.MultipartFile> multipartFiles = [];
        if (kIsWeb) {
          if (file.bytes != null) {
            multipartFiles.add(
              dio.MultipartFile.fromBytes(file.bytes!, filename: file.name),
            );
          }
        } else {
          if (file.path != null) {
            multipartFiles.add(
              await dio.MultipartFile.fromFile(file.path!, filename: file.name),
            );
          }
        }

        if (multipartFiles.isEmpty) {
          throw Exception('Could not process selected file.');
        }

        final uploadResult = await _chatBotService.uploadDocuments(
          isQnA: false,
          files: multipartFiles,
          description: 'Pricing Catalog CSV',
        );

        if (uploadResult['success'] == true) {
          final data = uploadResult['data'] as Map<String, dynamic>;
          final serverIds = data['ids'] as List<dynamic>;
          
          if (serverIds.isNotEmpty) {
            uploadedCatalog.assignAll({
              'name': file.name,
              'id': serverIds.first.toString(),
              'uploadedAt': DateTime.now().toIso8601String(),
            });
            Utilities.showSnackbar(
              SnackType.SUCCESS,
              'Pricing catalog uploaded successfully!',
            );
          } else {
            throw Exception('Server did not return a file ID.');
          }
        } else {
          throw Exception(uploadResult['message'] ?? 'Upload failed.');
        }
      }
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to upload catalog: $e',
      );
    } finally {
      isUploadingCatalog.value = false;
    }
  }

  Future<void> deleteCatalog() async {
    final docId = uploadedCatalog['id'];
    if (docId == null) return;

    try {
      isLoading.value = true;
      final result = await _chatBotService.deleteDocument(id: docId.toString());
      if (result['success'] == true) {
        uploadedCatalog.clear();
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          'Pricing catalog deleted successfully!',
        );
      } else {
        throw Exception(result['message'] ?? 'Delete failed.');
      }
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to delete catalog: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void togglePaymentMethod(String method) {
    if (selectedPaymentMethods.contains(method)) {
      selectedPaymentMethods.remove(method);
    } else {
      selectedPaymentMethods.add(method);
    }
  }

  void addFAQBlock() {
    faqList.add(FAQBlock());
  }

  void removeFAQBlock(int index) {
    if (index >= 0 && index < faqList.length) {
      faqList[index].dispose();
      faqList.removeAt(index);
    }
  }

  void showScheduleDialog(BuildContext context) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final tempSchedule = RxMap<String, Map<String, dynamic>>.from(customSchedule);
    final tempTimezone = botTimezone.value.obs;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 680,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Operating Hours",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            "DAY",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            "START TIME",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: Text(
                            "END TIME",
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 60,
                          child: Text(
                            "CLOSED",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: days.map((day) {
                          return Obx(() {
                            final config = tempSchedule[day] ?? {
                              'enabled': true,
                              'startTime': '09:00 AM',
                              'endTime': '05:00 PM',
                            };
                            final isEnabled = config['enabled'] as bool;
                            final isClosed = !isEnabled;
                            
                            final startTimeText = isClosed ? '--:-- --' : (config['startTime'] ?? '09:00 AM');
                            final endTimeText = isClosed ? '--:-- --' : (config['endTime'] ?? '05:00 PM');
                            
                            final dayColor = isClosed 
                                ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                                : (isDark ? Colors.white : const Color(0xFF1E293B));
                                
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      day,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: dayColor,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: InkWell(
                                      onTap: isClosed ? null : () async {
                                        final time = await _pickTime(context, config['startTime'] ?? '09:00 AM');
                                        if (time != null) {
                                          final newConfig = Map<String, dynamic>.from(config);
                                          newConfig['startTime'] = time;
                                          tempSchedule[day] = newConfig;
                                        }
                                      },
                                      child: Container(
                                        height: 40,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: isClosed 
                                              ? (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC))
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isClosed 
                                                ? (isDark ? Colors.white10 : const Color(0xFFE2E8F0))
                                                : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                startTimeText,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: isClosed 
                                                      ? (isDark ? Colors.white24 : const Color(0xFF94A3B8))
                                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: isClosed
                                                  ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
                                                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 4,
                                    child: InkWell(
                                      onTap: isClosed ? null : () async {
                                        final time = await _pickTime(context, config['endTime'] ?? '05:00 PM');
                                        if (time != null) {
                                          final newConfig = Map<String, dynamic>.from(config);
                                          newConfig['endTime'] = time;
                                          tempSchedule[day] = newConfig;
                                        }
                                      },
                                      child: Container(
                                        height: 40,
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: isClosed 
                                              ? (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC))
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isClosed 
                                                ? (isDark ? Colors.white10 : const Color(0xFFE2E8F0))
                                                : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                endTimeText,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: isClosed 
                                                      ? (isDark ? Colors.white24 : const Color(0xFF94A3B8))
                                                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                                ),
                                              ),
                                            ),
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: isClosed
                                                  ? (isDark ? Colors.white12 : const Color(0xFFCBD5E1))
                                                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: InkWell(
                                        onTap: () {
                                          final newConfig = Map<String, dynamic>.from(config);
                                          newConfig['enabled'] = isClosed; // Invert enabled state
                                          tempSchedule[day] = newConfig;
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isClosed 
                                                ? const Color(0xFF1B72E8) 
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isClosed 
                                                  ? const Color(0xFF1B72E8) 
                                                  : (isDark ? Colors.white24 : const Color(0xFF94A3B8)),
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: isClosed
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 14,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          });
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "TIMEZONE",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Obx(() => DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: tempTimezone.value,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'PST (Pacific Standard Time)',
                                child: Text('PST (Pacific Standard Time)'),
                              ),
                              DropdownMenuItem(
                                value: 'IST (Indian Standard Time)',
                                child: Text('IST (Indian Standard Time)'),
                              ),
                              DropdownMenuItem(
                                value: 'EST (Eastern Standard Time)',
                                child: Text('EST (Eastern Standard Time)'),
                              ),
                              DropdownMenuItem(
                                value: 'GMT (Greenwich Mean Time)',
                                child: Text('GMT (Greenwich Mean Time)'),
                              ),
                              DropdownMenuItem(
                                value: 'CET (Central European Time)',
                                child: Text('CET (Central European Time)'),
                              ),
                              DropdownMenuItem(
                                value: 'SGT (Singapore Time)',
                                child: Text('SGT (Singapore Time)'),
                              ),
                              DropdownMenuItem(
                                value: 'AEST (Australian Eastern Standard Time)',
                                child: Text('AEST (Australian Eastern Standard Time)'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                tempTimezone.value = val;
                              }
                            },
                          ),
                        )),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          customSchedule.assignAll(tempSchedule);
                          botTimezone.value = tempTimezone.value;
                          _updateOperatingHoursText();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 140,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B72E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Save",
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  Future<String?> _pickTime(BuildContext context, String currentVal) async {
    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
    try {
      final parts = currentVal.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      final isPm = parts[1].toLowerCase() == 'pm';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      initialTime = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final hourStr = (selectedTime.hourOfPeriod == 0 ? 12 : selectedTime.hourOfPeriod).toString().padLeft(2, '0');
      final minStr = selectedTime.minute.toString().padLeft(2, '0');
      final periodStr = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hourStr:$minStr $periodStr';
    }
    return null;
  }

  void _updateOperatingHoursText() {
    final monConfig = customSchedule['Monday'] ?? {};
    final tueConfig = customSchedule['Tuesday'] ?? {};
    final wedConfig = customSchedule['Wednesday'] ?? {};
    final thuConfig = customSchedule['Thursday'] ?? {};
    final friConfig = customSchedule['Friday'] ?? {};
    final satConfig = customSchedule['Saturday'] ?? {};
    final sunConfig = customSchedule['Sunday'] ?? {};

    final tzParts = botTimezone.value.split(' ');
    final tzAbbrev = tzParts.isNotEmpty ? tzParts[0] : 'PST';

    final isStandardWeek = (monConfig['enabled'] == true) &&
        (tueConfig['enabled'] == true) &&
        (wedConfig['enabled'] == true) &&
        (thuConfig['enabled'] == true) &&
        (friConfig['enabled'] == true) &&
        (satConfig['enabled'] == false) &&
        (sunConfig['enabled'] == false);

    if (isStandardWeek) {
      final start = monConfig['startTime'];
      final end = monConfig['endTime'];
      if (tueConfig['startTime'] == start && tueConfig['endTime'] == end &&
          wedConfig['startTime'] == start && wedConfig['endTime'] == end &&
          thuConfig['startTime'] == start && thuConfig['endTime'] == end &&
          friConfig['startTime'] == start && friConfig['endTime'] == end) {
        operatingHours.value = "Mon - Fri: $start - $end ($tzAbbrev)";
        return;
      }
    }

    bool allDaysEnabled = true;
    bool allDaysSame = true;
    final firstStart = monConfig['startTime'];
    final firstEnd = monConfig['endTime'];

    for (var entry in customSchedule.values) {
      if (entry['enabled'] != true) allDaysEnabled = false;
      if (entry['startTime'] != firstStart || entry['endTime'] != firstEnd) {
        allDaysSame = false;
      }
    }

    if (allDaysEnabled && allDaysSame) {
      operatingHours.value = "Everyday: $firstStart - $firstEnd ($tzAbbrev)";
      return;
    }

    operatingHours.value = "Custom Schedule ($tzAbbrev)";
  }
}
