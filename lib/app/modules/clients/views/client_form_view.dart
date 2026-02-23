import 'package:business_whatsapp/app/modules/add_client/controllers/add_client_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import '../../../common widgets/common_filled_button.dart';
import '../../../common widgets/custom_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utilities/responsive.dart';

class ClientFormView extends StatefulWidget {
  const ClientFormView({super.key});

  @override
  State<ClientFormView> createState() => _ClientFormViewState();
}

class _ClientFormViewState extends State<ClientFormView> {
  // Generate a unique key for this specific view instance
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Assign our local unique key to the controller so it validates THIS form
    // We fetch the controller here. Since we use Get.lazyPut, we might get the shared instance.
    // By overwriting formKey, 'saveClient' will validate the form currently engaged by the user.
    if (Get.isRegistered<AddClientController>()) {
      Get.find<AddClientController>().formKey = _formKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // If somehow controller isn't ready or we need to access it safely
    final controller = Get.find<AddClientController>();

    // Safety: ensure current view's key is the active one
    controller.formKey = _formKey;

    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.isEditMode.value) {
            return const Center(child: CircleShimmer(size: 40));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, controller),
                const SizedBox(height: 24),
                _buildForm(context, controller),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AddClientController controller) {
    return Obx(() {
      return Text(
        controller.isEditMode.value ? 'Edit Client' : 'Add Client',
        style: Theme.of(context).textTheme.displayLarge,
      );
    });
  }

  Widget _buildForm(BuildContext context, AddClientController controller) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey[200]!,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Form(
        key: _formKey, // Use local unique key
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Name, Phone Number, Phone Number ID
            if (isMobile)
              Column(
                children: [
                  _buildTextField(
                    controller: controller.nameController,
                    label: 'Name',
                    hint: 'Enter name',
                    isRequired: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.phoneNumberController,
                    label: 'Phone Number',
                    hint: 'Enter here',
                    isRequired: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.phoneNumberIdController,
                    label: 'Phone Number ID',
                    hint: 'Enter here',
                    isRequired: true,
                    isDark: isDark,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: controller.nameController,
                      label: 'Name',
                      hint: 'Enter name',
                      isRequired: true,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: controller.phoneNumberController,
                      label: 'Phone Number',
                      hint: 'Enter here',
                      isRequired: true,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: controller.phoneNumberIdController,
                      label: 'Phone Number ID',
                      hint: 'Enter here',
                      isRequired: true,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Row 2: Waba ID, Webhook Verify Token
            if (isMobile)
              Column(
                children: [
                  _buildTextField(
                    controller: controller.wabaIdController,
                    label: 'Waba ID',
                    hint: 'Enter here',
                    isRequired: true,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.webhookVerifyTokenController,
                    label: 'Webhook Verify Token',
                    hint: 'Enter here',
                    isRequired: true,
                    isDark: isDark,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: controller.wabaIdController,
                      label: 'Waba ID',
                      hint: 'Enter here',
                      isRequired: true,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: controller.webhookVerifyTokenController,
                      label: 'Webhook Verify Token',
                      hint: 'Enter here',
                      isRequired: true,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Row 3: Subscription, Premium, Wallet
            if (isMobile)
              Column(
                children: [
                  _buildDatePicker(
                    context: context,
                    controller: controller,
                    label: 'Subscription End Date',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildCheckbox(
                    value: controller.isPremium,
                    label: 'Premium',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildCheckbox(
                    value: controller.isCRMEnabled,
                    label: 'CRM Enabled',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.walletController,
                    label: 'Wallet Balance',
                    hint: 'Enter amount',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.adminLimitController,
                    label: 'Admin Limit',
                    hint: 'Enter limit (e.g. 5)',
                    isDark: isDark,
                    isRequired: true,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      context: context,
                      controller: controller,
                      label: 'Subscription End Date',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: _buildCheckbox(
                        value: controller.isPremium,
                        label: 'Premium',
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: _buildCheckbox(
                        value: controller.isCRMEnabled,
                        label: 'CRM Enabled',
                        isDark: isDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: controller.walletController,
                      label: 'Wallet Balance',
                      hint: 'Enter amount',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: controller.adminLimitController,
                      label: 'Admin Limit',
                      hint: 'Enter limit',
                      isDark: isDark,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Row 4: Logo
            if (isMobile)
              Column(
                children: [
                  _buildFileUpload(
                    label: 'Logo',
                    fileName: controller.logoFileName,
                    onUpload: controller.pickLogoFile,
                    isDark: isDark,
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildFileUpload(
                      label: 'Logo',
                      fileName: controller.logoFileName,
                      onUpload: controller.pickLogoFile,
                      isDark: isDark,
                    ),
                  ),
                  const Expanded(
                    child: SizedBox(),
                  ), // Empty space for alignment
                ],
              ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                CustomButton(
                  label: 'Back to Search',
                  onPressed: controller.navigateBack,
                  type: ButtonType.secondary,
                ),
                const SizedBox(width: 12),
                Obx(() {
                  return CustomButton(
                    label: 'Save',
                    onPressed: controller.isLoading.value
                        ? null
                        : () => controller.saveClient(),
                    type: ButtonType.primary,
                    isLoading: controller.isLoading.value,
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? AppColors.gray500 : Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: isDark ? AppColors.cardDark : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : Colors.grey[200]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : Colors.grey[200]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildFileUpload({
    required String label,
    required RxString fileName,
    required VoidCallback onUpload,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Obx(() {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : Colors.grey[200]!,
                    ),
                  ),
                  child: Text(
                    fileName.value.isEmpty ? 'Choose File' : fileName.value,
                    style: TextStyle(
                      fontSize: 14,
                      color: fileName.value.isEmpty
                          ? (isDark ? AppColors.gray500 : Colors.grey[400])
                          : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ),
            const SizedBox(width: 8),
            CommonFilledButton(
              onPressed: onUpload,
              label: 'Upload',
              backgroundColor: AppColors.primary,
              height: 48,
              borderRadius: 10,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required AddClientController controller,
    required String label,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final date = controller.subscriptionEndDate.value;
          final dateText = date != null
              ? "${date.day}/${date.month}/${date.year}"
              : "Select Date";
          return InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: isDark ? ThemeData.dark() : ThemeData.light(),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                controller.subscriptionEndDate.value = picked;
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey[200]!,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.grey,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCheckbox({
    required RxBool value,
    required String label,
    required bool isDark,
  }) {
    return Row(
      children: [
        Obx(() {
          return Checkbox(
            value: value.value,
            onChanged: (val) {
              value.value = val ?? false;
            },
            activeColor: AppColors.primary,
          );
        }),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
