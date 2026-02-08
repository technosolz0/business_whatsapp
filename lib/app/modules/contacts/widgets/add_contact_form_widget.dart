import 'package:business_whatsapp/app/common%20widgets/common_snackbar.dart';
import 'package:business_whatsapp/app/data/services/subscription_service.dart';
import 'package:business_whatsapp/app/data/services/upload_file_firebase.dart';
import 'package:business_whatsapp/app/utilities/utilities.dart';
import 'package:business_whatsapp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../common widgets/custom_button.dart';
import '../../../common widgets/custom_text_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../Utilities/responsive.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/services/contact_service.dart';
import '../controllers/contacts_controller.dart';
import 'tags_input_field.dart';

class AddContactFormWidget extends StatefulWidget {
  const AddContactFormWidget({super.key});

  @override
  State<AddContactFormWidget> createState() => _AddContactFormWidgetState();
}

class _AddContactFormWidgetState extends State<AddContactFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _notesController = TextEditingController();
  final _contactService = ContactsService.instance;
  final ImagePicker _imagePicker = ImagePicker();

  int? _selectedStatus;
  String _countryCode = '+91';
  List<String> _selectedTags = [];

  // New fields
  String? _profilePhotoPath;
  Uint8List? _profilePhotoBytes; // For web platform
  DateTime? _birthdate;
  DateTime? _anniversaryDt;
  DateTime? _workAnniversaryDt;

  // Toggle fields
  bool _isBirthdateActive = true;
  bool _isAnniversaryActive = true;
  bool _isWorkAnniversaryActive = true;

  // Premium status
  bool _isPremiumEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadContactData();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumService.instance.isPremiumEnabled();
    if (mounted) {
      setState(() {
        _isPremiumEnabled = isPremium;
      });
    }
  }

  void _loadContactData() async {
    final controller = Get.find<ContactsController>();
    final contact = controller.contactToEdit.value;

    if (contact != null) {
      // EDIT MODE — load existing values
      _fNameController.text = contact.fName!;
      _lNameController.text = contact.lName!;
      _phoneController.text = contact.phoneNumber;
      _countryCode = contact.countryCode;
      _emailController.text = contact.email ?? '';
      _companyController.text = contact.company ?? '';
      _selectedTags = List.from(contact.tags);
      _notesController.text = contact.notes ?? '';
      _selectedStatus = contact.status;

      // Load new fields
      _profilePhotoPath = contact.profilePhoto;
      _profilePhotoBytes = null; // URL will be used for existing photos
      _birthdate = contact.birthdate;
      _anniversaryDt = contact.anniversaryDt;
      _workAnniversaryDt = contact.workAnniversaryDt;

      // Load toggle fields
      _isBirthdateActive = contact.isBirthdateActive;
      _isAnniversaryActive = contact.isAnniversaryActive;
      _isWorkAnniversaryActive = contact.isWorkAnniversaryActive;
    } else {
      // ADD MODE — reset values
      _fNameController.clear();
      _lNameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _companyController.clear();
      _notesController.clear();

      _selectedTags = [];
      _selectedStatus = null;
      _countryCode = '+91';

      // Reset new fields
      _profilePhotoPath = null;
      _profilePhotoBytes = null;
      _birthdate = null;
      _anniversaryDt = null;
      _workAnniversaryDt = null;

      // Reset toggle fields
      _isBirthdateActive = true;
      _isAnniversaryActive = true;
      _isWorkAnniversaryActive = true;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------- VALIDATION HELPERS ----------------------

  String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "First name is required";
    }
    if (value.trim().length < 2) {
      return "First name must be at least 2 characters";
    }
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Last name is required";
    }
    if (value.trim().length < 2) {
      return "Last name must be at least 2 characters";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Phone number is required";
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
      return "Phone number must be numeric";
    }
    if (value.trim().length < 10 || value.trim().length > 15) {
      return "Phone number must be between 10 and 15 digits";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return "Enter a valid email address";
    }
    return null;
  }

  // ---------------------- IMAGE PICKER ----------------------

  Future<void> _pickProfilePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // For web, read as bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _profilePhotoPath = image.name;
            _profilePhotoBytes = bytes;
          });
        } else {
          // For mobile/desktop, use file path
          setState(() {
            _profilePhotoPath = image.path;
            _profilePhotoBytes = null;
          });
        }
      }
    } catch (e) {
      Utilities.showSnackbar(SnackType.ERROR, "Failed to pick image: $e");
    }
  }

  void _removeProfilePhoto() {
    setState(() {
      _profilePhotoPath = null;
      _profilePhotoBytes = null;
    });
  }

  // ---------------------- DATE PICKERS ----------------------

  Future<void> _selectDate(
    BuildContext context,
    DateTime? currentDate,
    Function(DateTime?) onDateSelected,
    String label,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select $label',
    );

    if (picked != null) {
      onDateSelected(picked);
      setState(() {});
    }
  }

  // ---------------------------------------------------------------

  Future<String?> _uploadProfilePhoto() async {
    if (_profilePhotoPath == null) return null;

    // If it's already a URL (from existing contact), return as is
    if (_profilePhotoPath!.startsWith('http')) {
      return _profilePhotoPath;
    }

    try {
      Uint8List fileBytes;
      String fileName;

      if (kIsWeb) {
        // For web, use the bytes we already have
        if (_profilePhotoBytes == null) return null;
        fileBytes = _profilePhotoBytes!;
        fileName = _profilePhotoPath!;
      } else {
        // For mobile/desktop, read file bytes
        final file = File(_profilePhotoPath!);
        fileBytes = await file.readAsBytes();
        fileName = _profilePhotoPath!.split('/').last;
      }

      // Determine MIME type
      String mimeType = 'image/jpeg';
      if (fileName.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.jpg') ||
          fileName.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      }

      // Upload to Firebase
      final result = await uploadFileToFirebase(
        fileBytes: fileBytes,
        fileName: fileName,
        folder: 'profile_photos/$clientID',
        mimeType: mimeType,
      );

      return result.url;
    } catch (e) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        "Failed to upload profile photo: $e",
      );
      return null;
    }
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    Utilities.showSnackbar(SnackType.INFO, "Saving contact...");

    final controller = Get.find<ContactsController>();
    final now = DateTime.now();
    final tagNames = _selectedTags.map((e) => e.toLowerCase()).toList();

    // Upload profile photo first if there's a new one
    String? profilePhotoUrl;
    if (_profilePhotoPath != null) {
      profilePhotoUrl = await _uploadProfilePhoto();
      if (profilePhotoUrl == null && _profilePhotoPath != null) {
        // Upload failed for a new photo
        Utilities.showSnackbar(
          SnackType.ERROR,
          "Failed to upload profile photo. Please try again.",
        );
        return;
      }
    }

    final isEditing = controller.isEditingContact.value;
    final existing = controller.contactToEdit.value;

    if (isEditing && existing != null) {
      // UPDATE CONTACT
      final updated = existing.copyWith(
        fName: _fNameController.text.trim(),
        lName: _lNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        countryCode: _countryCode,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        tags: [],
        status: _selectedStatus,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        profilePhoto: profilePhotoUrl,
        birthdate: _birthdate,
        anniversaryDt: _anniversaryDt,
        workAnniversaryDt: _workAnniversaryDt,
        birthdateMonth: controller.formatDateMonth(_birthdate),
        anniversaryDateMonth: controller.formatDateMonth(_anniversaryDt),
        workAnniversaryDateMonth: controller.formatDateMonth(
          _workAnniversaryDt,
        ),
        isBirthdateActive: _isBirthdateActive,
        isAnniversaryActive: _isAnniversaryActive,
        isWorkAnniversaryActive: _isWorkAnniversaryActive,
        updatedAt: now,
      );

      await _contactService.updateContactWithTagNames(
        existing.id,
        updated,
        tagNames,
      );

      Utilities.showSnackbar(
        SnackType.SUCCESS,
        "Contact updated successfully!",
      );
      controller.cancelAddContact();
    } else {
      // CREATE NEW CONTACT
      bool isExist = await _contactService.numberExists(
        _countryCode,
        _phoneController.text.trim(),
      );

      if (isExist) {
        Utilities.showSnackbar(SnackType.ERROR, "Phone number already exists.");
        return;
      }

      final contact = ContactModel(
        id: '',
        fName: _fNameController.text.trim(),
        lName: _lNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        countryCode: _countryCode,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        tags: [],
        status: _selectedStatus,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        profilePhoto: profilePhotoUrl,
        birthdate: _birthdate,
        anniversaryDt: _anniversaryDt,
        workAnniversaryDt: _workAnniversaryDt,
        birthdateMonth: controller.formatDateMonth(_birthdate),
        anniversaryDateMonth: controller.formatDateMonth(_anniversaryDt),
        workAnniversaryDateMonth: controller.formatDateMonth(
          _workAnniversaryDt,
        ),
        isBirthdateActive: _isBirthdateActive,
        isAnniversaryActive: _isAnniversaryActive,
        isWorkAnniversaryActive: _isWorkAnniversaryActive,
        lastContacted: null,
        createdAt: now,
        updatedAt: now,
      );

      await _contactService.addContactWithTagNames(contact, tagNames);
      Utilities.showSnackbar(SnackType.SUCCESS, "Contact saved successfully!");
      controller.isAddingContact.value = false;
    }
  }

  // ---------------------- DATE FIELD WIDGET ----------------------

  Widget _buildProfileImage(bool isDark) {
    if (_profilePhotoPath == null) {
      return Icon(
        Icons.person,
        size: 60,
        color: isDark ? AppColors.gray500 : Colors.grey[400],
      );
    }

    // If it's a URL (existing contact photo)
    if (_profilePhotoPath!.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          _profilePhotoPath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 60,
              color: isDark ? AppColors.gray500 : Colors.grey[400],
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircleShimmer(size: 20));
          },
        ),
      );
    }

    // For newly picked image
    if (kIsWeb) {
      // On web, use memory bytes
      if (_profilePhotoBytes != null) {
        return ClipOval(
          child: Image.memory(
            _profilePhotoBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 60,
                color: isDark ? AppColors.gray500 : Colors.grey[400],
              );
            },
          ),
        );
      }
    } else {
      // On mobile/desktop, use file path
      return ClipOval(
        child: Image.file(
          File(_profilePhotoPath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 60,
              color: isDark ? AppColors.gray500 : Colors.grey[400],
            );
          },
        ),
      );
    }

    return Icon(
      Icons.person,
      size: 60,
      color: isDark ? AppColors.gray500 : Colors.grey[400],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback? onClear,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.gray700 : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: isDark ? AppColors.gray400 : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : (label == 'DOB' ? 'DD/MM/YYYY' : 'Select $label'),
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null
                          ? (isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF1a1a1a))
                          : (isDark ? AppColors.gray400 : Colors.grey[600]),
                    ),
                  ),
                ),
                if (date != null)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: isDark ? AppColors.gray400 : Colors.grey[600],
                    ),
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateFieldWithToggle({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback? onClear,
    required bool isActive,
    required Function(bool) onToggleChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1a1a1a),
          ),
        ),
        const SizedBox(height: 8),
        // Date field
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.gray700 : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: isDark ? AppColors.gray400 : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : (label == 'DOB' ? 'DD/MM/YYYY' : 'Select $label'),
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null
                          ? (isDark
                                ? AppColors.textPrimaryDark
                                : const Color(0xFF1a1a1a))
                          : (isDark ? AppColors.gray400 : Colors.grey[600]),
                    ),
                  ),
                ),
                if (date != null)
                  IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: 18,
                      color: isDark ? AppColors.gray400 : Colors.grey[600],
                    ),
                    onPressed: onClear,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
        // Only show toggle if premium is enabled
        if (_isPremiumEnabled) ...[
          const SizedBox(height: 8),
          // Toggle switch below the date field
          Row(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isActive,
                  onChanged: onToggleChanged,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                  inactiveThumbColor: isDark
                      ? AppColors.gray400
                      : Colors.grey[400],
                  inactiveTrackColor: isDark
                      ? AppColors.gray600
                      : Colors.grey[300],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getToggleText(label, isActive),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getToggleText(String label, bool isActive) {
    switch (label) {
      case 'DOB':
        return isActive ? 'Disable birthday wishes' : 'Enable birthday wishes';
      case 'Anniversary':
        return isActive
            ? 'Disable anniversary wishes'
            : 'Enable anniversary wishes';
      case 'Work Anniversary':
        return isActive
            ? 'Disable work anniversary wishes'
            : 'Enable work anniversary wishes';
      default:
        return isActive ? 'Disable $label wishes' : 'Enable $label wishes';
    }
  }

  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ContactsController>();
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 2,
        vertical: 10,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // PROFILE PHOTO
              if (isMobile || isTablet)
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.gray700 : Colors.grey[200],
                          border: Border.all(
                            color: isDark
                                ? AppColors.gray600
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: _buildProfileImage(isDark),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: _pickProfilePhoto,
                            icon: const Icon(Icons.upload, size: 18),
                            label: Text(
                              _profilePhotoPath != null
                                  ? 'Change Photo'
                                  : 'Upload Photo',
                            ),
                          ),
                          if (_profilePhotoPath != null) ...[
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _removeProfilePhoto,
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Remove'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

              if (isMobile || isTablet) const SizedBox(height: 32),

              // NAME + PHONE
              if (isMobile) ...[
                CustomTextField(
                  label: 'First Name',
                  hint: 'e.g. Aarav',
                  controller: _fNameController,
                  required: true,
                  validator: validateFirstName,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Last Name',
                  hint: 'e.g. Sharma',
                  controller: _lNameController,
                  required: true,
                  validator: validateLastName,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Phone Number',
                  hint: '98765 43210',
                  controller: _phoneController,
                  prefixIcon: CountryCodePicker(
                    onChanged: (code) => _countryCode = code.dialCode ?? '+91',
                    initialSelection: 'IN',
                    countryFilter: const ['IN'], // Only show India
                    showCountryOnly: true,
                    showOnlyCountryWhenClosed: true,
                    alignLeft: false,
                  ),
                  keyboardType: TextInputType.phone,
                  required: true,
                  validator: _validatePhone,
                ),
              ] else
                Row(
                  children: [
                    if (!isTablet)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.gray700
                                    : Colors.grey[200],
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.gray600
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: _buildProfileImage(isDark),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              // mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: _pickProfilePhoto,
                                  icon: const Icon(Icons.upload, size: 18),
                                  label: Text(
                                    _profilePhotoPath != null
                                        ? 'Change Photo'
                                        : 'Upload Photo',
                                  ),
                                ),
                                if (_profilePhotoPath != null) ...[
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: _removeProfilePhoto,
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text('Remove'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: CustomTextField(
                        label: 'First Name',
                        hint: 'e.g. Aarav',
                        controller: _fNameController,
                        required: true,
                        validator: validateFirstName,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomTextField(
                        label: 'Last Name',
                        hint: 'e.g. Sharma',
                        controller: _lNameController,
                        required: true,
                        validator: validateLastName,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        label: 'Phone Number',
                        hint: '98765 43210',
                        controller: _phoneController,
                        prefixIcon: CountryCodePicker(
                          onChanged: (code) =>
                              _countryCode = code.dialCode ?? '+91',
                          initialSelection: 'IN',
                          countryFilter: const ['IN'], // Only show India
                          showCountryOnly: true,
                          showOnlyCountryWhenClosed: true,
                          alignLeft: false,
                        ),
                        required: true,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // EMAIL + COMPANY
              if (isMobile) ...[
                CustomTextField(
                  label: 'Email',
                  hint: 'example@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Company',
                  hint: 'Tech Solutions Inc.',
                  controller: _companyController,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Email',
                        hint: 'example@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: CustomTextField(
                        label: 'Company',
                        hint: 'Tech Solutions Inc.',
                        controller: _companyController,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // DATE FIELDS
              if (isMobile) ...[
                _buildDateFieldWithToggle(
                  label: 'DOB',
                  date: _birthdate,
                  onTap: () => _selectDate(
                    context,
                    _birthdate,
                    (date) => _birthdate = date,
                    'DOB',
                  ),
                  onClear: () => setState(() => _birthdate = null),
                  isActive: _isBirthdateActive,
                  onToggleChanged: (value) =>
                      setState(() => _isBirthdateActive = value),
                ),
                const SizedBox(height: 20),
                _buildDateFieldWithToggle(
                  label: 'Anniversary',
                  date: _anniversaryDt,
                  onTap: () => _selectDate(
                    context,
                    _anniversaryDt,
                    (date) => _anniversaryDt = date,
                    'Anniversary',
                  ),
                  onClear: () => setState(() => _anniversaryDt = null),
                  isActive: _isAnniversaryActive,
                  onToggleChanged: (value) =>
                      setState(() => _isAnniversaryActive = value),
                ),
                const SizedBox(height: 20),
                _buildDateFieldWithToggle(
                  label: 'Work Anniversary',
                  date: _workAnniversaryDt,
                  onTap: () => _selectDate(
                    context,
                    _workAnniversaryDt,
                    (date) => _workAnniversaryDt = date,
                    'Work Anniversary',
                  ),
                  onClear: () => setState(() => _workAnniversaryDt = null),
                  isActive: _isWorkAnniversaryActive,
                  onToggleChanged: (value) =>
                      setState(() => _isWorkAnniversaryActive = value),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _buildDateFieldWithToggle(
                        label: 'DOB',
                        date: _birthdate,
                        onTap: () => _selectDate(
                          context,
                          _birthdate,
                          (date) => _birthdate = date,
                          'DOB',
                        ),
                        onClear: () => setState(() => _birthdate = null),
                        isActive: _isBirthdateActive,
                        onToggleChanged: (value) =>
                            setState(() => _isBirthdateActive = value),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildDateFieldWithToggle(
                        label: 'Anniversary',
                        date: _anniversaryDt,
                        onTap: () => _selectDate(
                          context,
                          _anniversaryDt,
                          (date) => _anniversaryDt = date,
                          'Anniversary',
                        ),
                        onClear: () => setState(() => _anniversaryDt = null),
                        isActive: _isAnniversaryActive,
                        onToggleChanged: (value) =>
                            setState(() => _isAnniversaryActive = value),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildDateFieldWithToggle(
                        label: 'Work Anniversary',
                        date: _workAnniversaryDt,
                        onTap: () => _selectDate(
                          context,
                          _workAnniversaryDt,
                          (date) => _workAnniversaryDt = date,
                          'Work Anniversary',
                        ),
                        onClear: () =>
                            setState(() => _workAnniversaryDt = null),
                        isActive: _isWorkAnniversaryActive,
                        onToggleChanged: (value) =>
                            setState(() => _isWorkAnniversaryActive = value),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // TAGS
              TagsInputField(
                label: 'Tags',
                selectedTags: _selectedTags,
                onTagsChanged: (tags) {
                  setState(() => _selectedTags = tags);
                },
              ),

              const SizedBox(height: 20),

              // NOTES
              CustomTextField(
                label: 'Notes',
                hint: 'Add any relevant notes...',
                controller: _notesController,
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              // ACTION BUTTONS
              Obx(() {
                final editing = controller.isEditingContact.value;
                return Row(
                  mainAxisAlignment: isMobile
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start, // Changed from end to start
                  children: [
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: controller.cancelAddContact,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CustomButton(
                      label: editing ? 'Update Contact' : 'Save Contact',
                      icon: editing ? null : Icons.add,
                      onPressed: _handleSave,
                      type: ButtonType.primary,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
