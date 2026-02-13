import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adminpanel/main.dart';
import 'package:adminpanel/app/common%20widgets/custom_text_field.dart';
import 'package:adminpanel/app/common%20widgets/common_filled_button.dart';
import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:adminpanel/app/Utilities/network_utilities.dart';
import 'package:adminpanel/app/Utilities/utilities.dart';
import 'package:adminpanel/app/common%20widgets/common_snackbar.dart';

class ExportToZohoDialog extends StatefulWidget {
  final String chatId;

  const ExportToZohoDialog({super.key, required this.chatId});

  @override
  State<ExportToZohoDialog> createState() => _ExportToZohoDialogState();
}

class _ExportToZohoDialogState extends State<ExportToZohoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  bool _isLoading = true;
  bool _isSaving = false;
  String _initialCountryCallingCode = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _companyNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _descriptionController = TextEditingController();

    _fetchContactDetails();
  }

  Future<void> _fetchContactDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('contacts')
          .doc(clientID)
          .collection('data')
          .doc(widget.chatId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;

        // Handle names (First/Last)
        String fullName = data['name'] ?? '';
        String firstName = data['fName'] ?? '';
        String lastName = data['lName'] ?? '';
        phone = data['phoneNumber'] ?? '';
        String countryCallingCode = data['countryCallingCode'] ?? '';

        _initialCountryCallingCode = countryCallingCode;

        String phoneWithCountryCode = countryCallingCode + phone;
        if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
          List<String> parts = fullName.trim().split(' ');
          if (parts.length > 1) {
            firstName = parts.first;
            lastName = parts.sublist(1).join(' ');
          } else {
            firstName = fullName;
          }
        }

        _firstNameController.text = firstName;
        _lastNameController.text = lastName;
        _companyNameController.text = data['company'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = phoneWithCountryCode;
        _descriptionController.text = data['notes'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching contact details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveToZoho() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final dio = NetworkUtilities.getDioClient();

      final response = await dio.post(
        'https://addrecordtoleadsmodule-d3b4t36f7q-uc.a.run.app',
        data: {
          'clientId': clientID,
          'recordData': {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'company': _companyNameController.text.trim(),
            'email': _emailController.text.trim(),
            'countryCallingCode': _initialCountryCallingCode,
            'phoneNumber': phone,
            'description': _descriptionController.text.trim(),
          },
        },
      );
      debugPrint(response.data.toString());

      if (response.statusCode == 200) {
        final collectionRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(clientID)
            .collection('data');

        collectionRef.doc(widget.chatId).update({
          'leadRecordId': response.data['data']['id'] ?? '',
          'isLeadGenerated': true,
        });

        Get.back();
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          "Contact exported to Zoho successfully",
        );
      } else {
        Utilities.showSnackbar(
          SnackType.ERROR,
          "Failed to export: ${response.data['message'] ?? 'Unknown error'}",
        );
      }
    } catch (e) {
      debugPrint('Error saving to Zoho: $e');
      Utilities.showSnackbar(
        SnackType.ERROR,
        "An error occurred while saving: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.cardDark : Colors.white;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Contact Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1a1a1a),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.close),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'First Name',
                            hint: 'Ayman',
                            controller: _firstNameController,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: CustomTextField(
                            label: 'Last Name',
                            hint: 'Shaikh',
                            required: true,
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Last Name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Company Name',
                      hint: 'Anjita IT Solutions',
                      controller: _companyNameController,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Email',
                            hint: 'info@example.com',
                            controller: _emailController,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: CustomTextField(
                            readOnly: true,
                            label: 'Phone Number',
                            hint: '+918964523657',
                            required: true,
                            controller: _phoneController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Phone Number is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Description',
                      hint: 'Enter Here',
                      maxLines: 3,
                      controller: _descriptionController,
                    ),
                    const SizedBox(height: 32),

                    // Button
                    
                    CommonFilledButton(
                      onPressed: _isSaving ? null : _saveToZoho,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save to Zoho'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
