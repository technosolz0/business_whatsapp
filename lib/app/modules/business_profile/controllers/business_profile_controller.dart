import 'dart:convert';
import 'dart:typed_data';
import 'package:business_whatsapp/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../../Utilities/utilities.dart';
import '../../../Utilities/media_utils.dart';
import '../../../common widgets/common_snackbar.dart';

class BusinessProfileController extends GetxController {
  // Dio instance with logging
  final dio.Dio _dio =
      dio.Dio(
          dio.BaseOptions(
            connectTimeout: Duration(seconds: 30),
            receiveTimeout: Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          PrettyDioLogger(
            requestHeader: true,
            requestBody: true,
            responseBody: true,
            responseHeader: true,
            error: true,
            compact: true,
            maxWidth: 90,
          ),
        );
  // Form key - using UniqueKey to prevent conflicts
  final GlobalKey<FormState> formKey = GlobalKey<FormState>(
    debugLabel: UniqueKey().toString(),
  );

  // Text Controllers
  final aboutController = TextEditingController();
  final descriptionController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();

  // Website controllers list
  final RxList<TextEditingController> websiteControllers =
      <TextEditingController>[].obs;

  // Selected industry
  final RxString selectedIndustry = 'Select industry'.obs;

  // Industry options (Meta vertical values)
  final List<String> industries = [
    'Select industry',
    'UNDEFINED',
    'OTHER',
    'AUTO',
    'BEAUTY',
    'APPAREL',
    'EDU',
    'ENTERTAIN',
    'EVENT_PLAN',
    'FINANCE',
    'GROCERY',
    'GOVT',
    'HOTEL',
    'HEALTH',
    'NONPROFIT',
    'PROF_SERVICES',
    'RETAIL',
    'TRAVEL',
    'RESTAURANT',
    'NOT_A_BIZ',
  ];

  // Profile picture URL
  final RxString profilePictureUrl = ''.obs;

  // Selected profile picture for upload
  final Rxn<Uint8List> selectedProfileImageBytes = Rxn<Uint8List>();
  final RxnString selectedProfileImageName = RxnString();

  // Loading state
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  // Character count observables
  final RxInt aboutCharCount = 0.obs;
  final RxInt descriptionCharCount = 0.obs;
  final RxInt emailCharCount = 0.obs;
  final RxInt addressCharCount = 0.obs;

  void addWebsite() {
    if (websiteControllers.length < 2) {
      websiteControllers.add(TextEditingController());
    }
  }

  void removeWebsite(int index) {
    if (websiteControllers.isNotEmpty) {
      websiteControllers[index].dispose();
      websiteControllers.removeAt(index);
    }
  }

  Future<void> saveChanges() async {
    try {
      isSaving.value = true;
      // debugPrint('🚀 Starting business profile update...');

      // Create FormData for multipart/form-data request
      final formData = dio.FormData.fromMap({
        'about': aboutController.text.trim(),
        'description': descriptionController.text.trim(),
        'email': emailController.text.trim(),
        'address': addressController.text.trim(),
        'vertical': selectedIndustry.value != 'Select industry'
            ? selectedIndustry.value
            : '',
        'websites': jsonEncode(
          websiteControllers
              .map((controller) => controller.text.trim())
              .where((text) => text.isNotEmpty)
              .toList(),
        ), // JSON encode the array as string
        'messaging_product': 'whatsapp',
        'clientId': clientID,
      });

      // Add profile picture if selected
      if (selectedProfileImageBytes.value != null) {
        formData.files.add(
          MapEntry(
            'profile_picture',
            dio.MultipartFile.fromBytes(
              selectedProfileImageBytes.value!,
              filename: selectedProfileImageName.value ?? 'profile_pic.jpg',
            ),
          ),
        );
      }

      // debugPrint('📤 Sending form data: ${formData.fields}');

      final response = await _dio.post(
        'https://bw.serwex.in/updatewhatsappbusinessprofile',
        data: formData,
      );

      // debugPrint('📥 Update response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true) {
          // debugPrint('✅ Profile updated successfully');
          Utilities.showSnackbar(
            SnackType.SUCCESS,
            'Business profile updated successfully!',
          );
        } else {
          // debugPrint('❌ API returned success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to update profile');
        }
      } else {
        // debugPrint('❌ HTTP error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // debugPrint('💥 Error updating business profile: $e');
      // debugPrint('Stack trace: ${StackTrace.current}');

      String errorMessage = 'Failed to update profile';
      if (e is dio.DioException) {
        // debugPrint('🚨 DioException: ${e.type} - ${e.message}');
        switch (e.type) {
          case dio.DioExceptionType.connectionTimeout:
            errorMessage = 'Connection timeout - please check your internet';
            break;
          case dio.DioExceptionType.sendTimeout:
            errorMessage = 'Send timeout - please try again';
            break;
          case dio.DioExceptionType.receiveTimeout:
            errorMessage = 'Receive timeout - please try again';
            break;
          case dio.DioExceptionType.badResponse:
            errorMessage = 'Server error (${e.response?.statusCode})';
            break;
          case dio.DioExceptionType.cancel:
            errorMessage = 'Request cancelled';
            break;
          default:
            errorMessage = 'Network error: ${e.message}';
        }
      }

      Utilities.showSnackbar(SnackType.ERROR, errorMessage);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> changePhoto() async {
    final result = await MediaUtils.pickAndValidateFile(
      mediaType: 'Image',
      maxSizeMB: 5, // Assuming 5MB limit for profile pictures
    );

    if (result.success && result.bytes != null) {
      selectedProfileImageBytes.value = result.bytes;
      selectedProfileImageName.value = result.fileName;
      // Temporarily set a placeholder or keep existing URL until saved,
      // but UI might want to show the selected image bytes.
      // For now, we rely on the UI checking selectedProfileImageBytes first.
      Utilities.showSnackbar(
        SnackType.SUCCESS,
        'Profile picture selected! Click save to apply.',
      );
    } else {
      Utilities.showSnackbar(SnackType.ERROR, result.error ?? 'Upload failed');
    }
  }

  Future<void> fetchBusinessProfile() async {
    try {
      // debugPrint('🚀 Starting business profile fetch...');
      isLoading.value = true;

      final response = await _dio.get(
        'https://bw.serwex.in/getwhatsappbusinessprofile',
        queryParameters: {"clientId": clientID},
      );

      // debugPrint('📥 Fetch response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data['success'] == true && data['data'] != null) {
          final profileData = data['data'][0]; // API returns array
          // debugPrint('📄 Profile data received: $profileData');

          // Populate controllers
          aboutController.text = (profileData['about'] as String?) ?? '';
          descriptionController.text =
              (profileData['description'] as String?) ?? '';
          emailController.text = (profileData['email'] as String?) ?? '';
          addressController.text = (profileData['address'] as String?) ?? '';
          profilePictureUrl.value =
              (profileData['profile_picture_url'] as String?) ?? '';

          // Handle websites
          final websites = profileData['websites'] as List<dynamic>? ?? [];
          websiteControllers.clear();
          for (var website in websites) {
            websiteControllers.add(
              TextEditingController(text: website as String),
            );
          }

          // Handle vertical
          selectedIndustry.value =
              (profileData['vertical'] as String?) ?? 'Select industry';

          // // debugPrint(' Profile data loaded successfully');
          // Utilities.showSnackbar(
          //   SnackType.SUCCESS,
          //   'Profile data loaded successfully',
          // );
        } else {
          // debugPrint(' API returned success=false: ${data['message']}');
          throw Exception(data['message'] ?? 'Failed to load profile data');
        }
      } else {
        // debugPrint(' HTTP error: ${response.statusCode}');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // debugPrint(' Error fetching business profile: $e');
      // debugPrint('Stack trace: ${StackTrace.current}');

      // Fallback to sample data when CORS/API issues occur
      // debugPrint('🔄 Using fallback sample data due to API error');

      final sampleData = {
        "about": "Hey there! I am using WhatsApp.",
        "address":
            "Jio Convention Centre, G Block, Bandra Kurla Complex, Bandra East, Mumbai, Maharashtra 400098",
        "description":
            "The World's Leading Business Networking and Referral Organization",
        "email": "anjitaitsolutions@gmail.com",
        "profile_picture_url":
            "https://pps.whatsapp.net/v/t61.24694-24/584748121_896159049605561_8570992965727467720_n.jpg?ccb=11-4&oh=01_Q5Aa3QF5R2_48EAbuPk5ukV6J5xch-ztMUPxbS3E9lHrAThrwg&oe=694F56AD&_nc_sid=5e03e0&_nc_cat=109",
        "websites": [
          "https://bni-mumbaiwest.in/mumbai-west-exponential/en-IN/index",
        ],
        "vertical": "OTHER",
      };

      // Populate controllers with sample data
      aboutController.text = (sampleData['about'] as String?) ?? '';
      descriptionController.text = (sampleData['description'] as String?) ?? '';
      emailController.text = (sampleData['email'] as String?) ?? '';
      addressController.text = (sampleData['address'] as String?) ?? '';
      profilePictureUrl.value =
          (sampleData['profile_picture_url'] as String?) ?? '';

      // Handle websites
      final websites = sampleData['websites'] as List<dynamic>? ?? [];
      websiteControllers.clear();
      for (var website in websites) {
        websiteControllers.add(TextEditingController(text: website as String));
      }

      // Handle vertical
      selectedIndustry.value =
          (sampleData['vertical'] as String?) ?? 'Select industry';

      // debugPrint('✅ Loaded fallback sample data successfully');

      String errorMessage = 'Loaded sample data (API CORS issue)';
      if (e is dio.DioException) {
        // debugPrint('🚨 DioException: ${e.type} - ${e.message}');
        switch (e.type) {
          case dio.DioExceptionType.connectionTimeout:
            errorMessage = 'Connection timeout - loaded sample data';
            break;
          case dio.DioExceptionType.sendTimeout:
            errorMessage = 'Send timeout - loaded sample data';
            break;
          case dio.DioExceptionType.receiveTimeout:
            errorMessage = 'Receive timeout - loaded sample data';
            break;
          case dio.DioExceptionType.badResponse:
            errorMessage = 'Server error - loaded sample data';
            break;
          case dio.DioExceptionType.cancel:
            errorMessage = 'Request cancelled - loaded sample data';
            break;
          default:
            errorMessage = 'Network error - loaded sample data (${e.message})';
        }
      }

      Utilities.showSnackbar(SnackType.INFO, errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();

    // Add listeners for character count updates
    aboutController.addListener(() {
      aboutCharCount.value = aboutController.text.length;
    });
    descriptionController.addListener(() {
      descriptionCharCount.value = descriptionController.text.length;
    });
    emailController.addListener(() {
      emailCharCount.value = emailController.text.length;
    });
    addressController.addListener(() {
      addressCharCount.value = addressController.text.length;
    });

    fetchBusinessProfile();
  }

  @override
  void onClose() {
    aboutController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    addressController.dispose();
    for (var controller in websiteControllers) {
      controller.dispose();
    }
    super.onClose();
  }
}
