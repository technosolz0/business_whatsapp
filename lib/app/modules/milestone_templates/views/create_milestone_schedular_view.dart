import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/create_milestone_schedular_controller.dart';
import 'package:business_whatsapp/app/data/models/milestone_element.dart';
import './widgets/milestone_variable_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../../Utilities/responsive.dart';
import '../../../common widgets/standard_page_layout.dart';
import '../../../common widgets/common_outline_button.dart';
import '../../../common widgets/common_filled_button.dart';

class CreateMilestoneSchedularView
    extends GetView<CreateMilestoneSchedularController> {
  const CreateMilestoneSchedularView({super.key});

  static const Map<String, List<String>> allowedExtensions = {
    "Image": ["jpg", "jpeg", "png"],
    "Video": ["mp4", "3gp"],
    "Document": ["txt", "pdf", "doc", "docx", "ppt", "pptx", "xls", "xlsx"],
  };

  String _buildSupportedText(String type) {
    // If type is empty/null, default to something generic or empty string
    if (type.isEmpty) return "Add a file to be sent along with your message.";

    final map = allowedExtensions;

    if (!map.containsKey(type) || map[type]!.isEmpty) {
      return "Add a file to be sent along with your message.";
    }

    final exts = map[type]!.map((e) => e.toUpperCase()).join(", ");
    return "Add a file to be sent along with your message. Supported: $exts. Max: 10MB.";
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'Create Milestone Schedular',
      subtitle: 'Design and schedule your milestone messages',
      showBackButton: true,
      onBack: () => Get.offNamed(Routes.MILESTONE_SCHEDULARS),
      isContentScrollable: false,
      child: Responsive(
        desktop: _buildDesktopLayout(context),
        tablet: _buildTabletLayout(context),
        mobile: _buildMobileLayout(context),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLeftPanel(context),
        const SizedBox(width: 24),
        Expanded(child: _buildPreviewPanel()),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildLeftPanel(context, isFullWidth: true),
          const SizedBox(height: 24),
          _buildPreviewPanel(isFullWidth: true),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildLeftPanel(context, isFullWidth: true),
          const SizedBox(height: 24),
          _buildPreviewPanel(isFullWidth: true),
        ],
      ),
    );
  }

  // ===========================================================================
  // LEFT PANEL - FORM CONTROLS
  // ===========================================================================

  Widget _buildLeftPanel(BuildContext context, {bool isFullWidth = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: isFullWidth ? double.infinity : 525,
      // Fill height in desktop Row, otherwise auto-height
      height: isFullWidth ? null : double.infinity,
      decoration: ShapeDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(31),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Name
            _buildTemplateNameSection(isDark),
            const SizedBox(height: 30),
            // Schedular Type
            _buildSchedularTypeSection(isDark),
            const SizedBox(height: 30),

            // Select Schedular
            _buildSelectSchedularSection(isDark),
            const SizedBox(height: 30),

            // Background
            Obx(() {
              if (controller.selectedTemplateId.value.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBackgroundSection(isDark),
                  const SizedBox(height: 30),
                ],
              );
            }),

            // Elements
            Obx(() {
              if (controller.backgroundBytes.value == null) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [_buildElementsSection(), const SizedBox(height: 30)],
              );
            }),

            // Text Styling (when text element selected)
            Obx(() {
              if (controller.selectedElement.value?.type == 'text') {
                return _buildTextStylingSection();
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 30),

            // Schedule Time
            _buildScheduleTimeSection(isDark),

            const SizedBox(height: 100),

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSchedularTypeSection(bool isDark) {
    return SizedBox(
      width: 465,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedular Type',
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your schedular should fall under one of these categories',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.26,
            ),
          ),
          const SizedBox(height: 15),
          Obx(
            () => Container(
              width: double.infinity,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: ShapeDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value:
                      controller.availableTypes.isNotEmpty &&
                          controller.availableTypes.any(
                            (item) =>
                                item.value == controller.schedularType.value,
                          )
                      ? controller.schedularType.value
                      : (controller.availableTypes.isNotEmpty
                            ? controller.availableTypes.first.value
                            : null),
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: isDark ? Colors.white70 : const Color(0xFF3D3D3D),
                  ),
                  dropdownColor: isDark
                      ? const Color(0xFF242424)
                      : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF3D3D3D),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                  hint: Text(
                    'No available types',
                    style: TextStyle(color: isDark ? Colors.grey[500] : null),
                  ),
                  items: controller.availableTypes,
                  onChanged: (value) {
                    if (value != null) controller.schedularType.value = value;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTimeSection(bool isDark) {
    return SizedBox(
      width: 465,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Time',
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select the time when the milestone message should be sent',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.26,
            ),
          ),
          const SizedBox(height: 15),
          Obx(
            () => GestureDetector(
              onTap: () async {
                // Parse current scheduleTime string to TimeOfDay
                TimeOfDay initialTime = TimeOfDay.now();
                try {
                  final String timeStr = controller.scheduleTime.value;
                  final parts = timeStr.split(' ');
                  final timeParts = parts[0].split(':');
                  int hour = int.parse(timeParts[0]);
                  int minute = int.parse(timeParts[1]);

                  if (parts.length > 1) {
                    if (parts[1].toUpperCase() == 'PM' && hour != 12) {
                      hour += 12;
                    } else if (parts[1].toUpperCase() == 'AM' && hour == 12) {
                      hour = 0;
                    }
                  }
                  initialTime = TimeOfDay(hour: hour, minute: minute);
                } catch (e) {
                  // debugPrint('Error parsing time: $e');
                }

                final picked = await showTimePicker(
                  context: Get.context!,
                  initialTime: initialTime,
                );
                if (picked != null) {
                  controller.scheduleTime.value = picked.format(Get.context!);
                }
              },
              child: Container(
                width: double.infinity,
                height: 40,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: ShapeDecoration(
                  color: isDark
                      ? const Color(0xFF242424)
                      : const Color(0xFFF6F7F8),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: isDark
                          ? const Color(0xFF4B5563)
                          : const Color(0xFFD6D6D6),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.scheduleTime.value,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 20,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectSchedularSection(bool isDark) {
    return SizedBox(
      width: 465,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Template',
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an approved template to use for this milestone',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.26,
            ),
          ),
          const SizedBox(height: 15),
          _schedularDropdown(isDark),
          const SizedBox(height: 20),
          Obx(() {
            final param = controller.selectedSchedularParams.value;
            if (param == null) return const SizedBox.shrink();

            final bool hasNoParams = param.bodyVars == 0;

            if (hasNoParams) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Schedular Parameters",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                GlobalChipList(chips: controller.availableChips),
                const SizedBox(height: 12),
                if (param.headerVars > 0) ...[
                  for (int i = 1; i <= param.headerVars; i++)
                    _paramField(num: i, keyName: "header_$i"),
                  const SizedBox(height: 20),
                ],
                if (param.bodyVars > 0) ...[
                  for (int i = 1; i <= param.bodyVars; i++)
                    _paramField(num: i, keyName: "body_$i"),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _schedularDropdown(bool isDark) {
    return Obx(() {
      final schedulars = controller.schedularList;

      return Container(
        width: double.infinity,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 0),
        decoration: ShapeDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedTemplateId.value.isEmpty
                ? null
                : controller.selectedTemplateId.value,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: isDark ? Colors.white70 : const Color(0xFF3D3D3D),
            ),
            dropdownColor: isDark ? const Color(0xFF242424) : Colors.white,
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
            hint: Text(
              "Select a schedular",
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            items: schedulars
                .map(
                  (t) => DropdownMenuItem(
                    value: t.id,
                    child:
                        // Text(t.name)
                        Text('${t.name} - ${t.category}'),
                  ),
                )
                .toList(),
            onChanged: (schedularId) {
              if (schedularId != null) {
                controller.onSchedularSelected(schedularId);
              }
            },
          ),
        ),
      );
    });
  }

  Widget _paramField({required int num, required String keyName}) {
    controller.ensureParamKey(keyName);

    return MilestoneVariableInput(
      num: num,
      ctrl: controller,
      controller: controller.paramControllers[keyName]!,
      errorText: controller.paramErrors[keyName]!,
      acceptedChips: controller.availableChips,
      onValueChanged: (type, value) {
        controller.variableValues[keyName] = {"type": type, "value": value};
        controller.previewRefresh.value++;
      },
    );
  }

  Widget _buildTemplateNameSection(bool isDark) {
    return SizedBox(
      width: 465,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedular Name',
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Give your schedular a name to identify it later',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.26,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: ShapeDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: TextField(
              controller: controller.nameCtrl,
              focusNode: controller.nameFocus,
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontSize: 14,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
              ),
              onChanged: (value) {
                controller.schedularName.value = value;
              },
              decoration: InputDecoration(
                hintText: 'Enter schedular name',
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          Obx(() {
            if (controller.nameError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text(
                  controller.nameError.value,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildBackgroundSection(bool isDark) {
    return SizedBox(
      width: 465,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Background',
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload background image for your schedular',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.26,
            ),
          ),
          const SizedBox(height: 15),
          Obx(() {
            final hasImage = controller.backgroundBytes.value != null;
            return GestureDetector(
              onTap: controller.pickBackgroundImage,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: ShapeDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      width: 1,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: hasImage
                    ? Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.image,
                            color: Color(0xFF287DE8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.backgroundFileName.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            onPressed: () {
                              controller.backgroundBytes.value = null;
                              controller.backgroundFileName.value = '';
                            },
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Click to Upload Background',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 13,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.26,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 20,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ],
                      ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            _buildSupportedText("Image"),
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Obx(() {
            if (controller.backgroundError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Text(
                  controller.backgroundError.value,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildElementsSection() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    return SizedBox(
      width: 465,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elements',
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Required : 1 image and 1 text box',
            style: TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              letterSpacing: -0.26,
            ),
          ),
          const SizedBox(height: 15),
          Obx(() {
            final hasImage = controller.milestoneElements.any(
              (e) => e.type == 'image',
            );
            final hasName = controller.milestoneElements.any(
              (e) => e.type == 'text' && e.content.value == 'Name',
            );
            return Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: hasImage ? null : controller.addImageBlock,
                    child: Container(
                      height: 45,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: hasImage
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: hasImage
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Profile Image',
                            style: TextStyle(
                              color: hasImage
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: hasName ? null : controller.addTextBlock,
                    child: Container(
                      height: 45,
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: hasName
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.text_fields,
                            color: hasName
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Name',
                            style: TextStyle(
                              color: hasName
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Obx(
            () => controller.selectedElement.value != null
                ? GestureDetector(
                    onTap: controller.removeSelectedElement,
                    child: Container(
                      width: double.infinity,
                      height: 45,
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF81519),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Delete Selected',
                            style: TextStyle(
                              color: AppColors.textPrimaryLight,
                              fontSize: 15,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextStylingSection() {
    return Container(
      width: 463,
      padding: const EdgeInsets.all(22),
      decoration: ShapeDecoration(
        color: const Color(0xFFF6F7F8),
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFD6D6D6)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Font Dropdown
          Obx(
            () => Container(
              width: double.infinity,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: ShapeDecoration(
                color: const Color(0xFFF6F7F8),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(width: 1, color: Color(0xFFD6D6D6)),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedElement.value!.font.value,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  style: const TextStyle(
                    color: Color(0xFF3D3D3D),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                  items:
                      ['Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Poppins']
                          .map(
                            (font) => DropdownMenuItem(
                              value: font,
                              child: Text(font),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) controller.updateTextFont(value);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Font Size and Color
          Row(
            children: [
              // Color Picker
              Obx(
                () => GestureDetector(
                  onTap: () => _showColorPicker(Get.context!),
                  child: Container(
                    width: 78,
                    height: 38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF6F7F8),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFD6D6D6),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Container(
                      decoration: ShapeDecoration(
                        color: controller.selectedElement.value!.color.value,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 13),

              // Font Size
              Expanded(
                child: Obx(
                  () => Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF6F7F8),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1,
                          color: Color(0xFFD6D6D6),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${controller.selectedElement.value!.fontSize.value}',
                          style: const TextStyle(
                            color: Color(0xFF3D3D3D),
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: controller
                                .selectedElement
                                .value!
                                .fontSize
                                .value
                                .toDouble(),
                            min: 10,
                            max: 72,
                            activeColor: const Color(0xFF287DE8),
                            onChanged: (value) =>
                                controller.updateTextSize(value.toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bold and Italic
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => GestureDetector(
                    onTap: controller.toggleBold,
                    child: Container(
                      height: 38,
                      decoration: ShapeDecoration(
                        color: controller.selectedElement.value!.isBold.value
                            ? const Color(0xFFE8EAEC)
                            : const Color(0xFFF6F7F8),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFFD6D6D6),
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'B',
                          style: TextStyle(
                            color: Color(0xFF3D3D3D),
                            fontSize: 13,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Obx(
                  () => GestureDetector(
                    onTap: controller.toggleItalic,
                    child: Container(
                      height: 38,
                      decoration: ShapeDecoration(
                        color: controller.selectedElement.value!.isItalic.value
                            ? const Color(0xFFE8EAEC)
                            : const Color(0xFFF6F7F8),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(
                            width: 1,
                            color: Color(0xFFD6D6D6),
                          ),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'I',
                          style: TextStyle(
                            color: Color(0xFF3D3D3D),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Times New Roman',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Text Alignment
          Obx(
            () => Row(
              children: [
                Expanded(
                  child: _buildAlignButton(Icons.format_align_left, 'left'),
                ),
                Expanded(
                  child: _buildAlignButton(Icons.format_align_center, 'center'),
                ),
                Expanded(
                  child: _buildAlignButton(Icons.format_align_right, 'right'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignButton(IconData icon, String align) {
    final isSelected =
        controller.selectedElement.value!.textAlign.value == align;
    BorderRadius borderRadius;

    if (align == 'left') {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(8),
        bottomLeft: Radius.circular(8),
      );
    } else if (align == 'right') {
      borderRadius = const BorderRadius.only(
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    } else {
      borderRadius = BorderRadius.zero;
    }

    return GestureDetector(
      onTap: () => controller.updateTextAlign(align),
      child: Container(
        height: 38,
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFFE8EAEC) : const Color(0xFFF6F7F8),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFD6D6D6)),
            borderRadius: borderRadius,
          ),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF3D3D3D)),
      ),
    );
  }

  Widget _buildSaveButton() {
    return CommonFilledButton(
      onPressed: controller.saveMilestoneSchedular,
      label: 'Save Schedular',
      width: double.infinity,
      height: 45,
      backgroundColor: AppColors.primary,
    );
  }

  Future<void> _showColorPicker(BuildContext context) async {
    Color pickedColor = controller.selectedElement.value!.color.value;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: pickedColor,
            onColorChanged: (color) => pickedColor = color,
            pickersEnabled: const {
              ColorPickerType.both: true,
              ColorPickerType.wheel: true,
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateTextColor(pickedColor);
              Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // RIGHT PANEL - PREVIEW
  // ===========================================================================

  Widget _buildPreviewPanel({bool isFullWidth = false, bool isDark = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: isFullWidth ? null : double.infinity,
      decoration: ShapeDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFD7D7D7)),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Preview Header
          Container(
            height: 81,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preview',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.40,
                  ),
                ),
                CommonOutlineButton(
                  onPressed: controller.resetForm,
                  label: 'Reset',
                  icon: Icons.refresh,
                  color: const Color(0xFFF81519),
                  width: 150,
                  height: 39,
                  borderRadius: 7,
                ),
              ],
            ),
          ),

          // Preview Canvas
          Obx(() {
            if (controller.selectedTemplateId.value.isEmpty) {
              return const SizedBox.shrink();
            }

            final content = Obx(() {
              final hasBackground = controller.backgroundBytes.value != null;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (controller.previewRefresh.value >= 0) ...[
                    if (!hasBackground)
                      Container(
                        width: 574,
                        height: 450,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          border: Border.all(
                            color: const Color(0xFFD1D5DB),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Upload a background image to start',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: controller.containerWidth.value,
                        height: controller.containerHeight.value,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.backgroundLight,
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                controller.backgroundBytes.value!,
                                width: controller.containerWidth.value,
                                height: controller.containerHeight.value,
                                fit: BoxFit.contain,
                              ),
                            ),
                            ...controller.milestoneElements.map((element) {
                              return _buildDraggableElement(element);
                            }),
                          ],
                        ),
                      ),
                    if (controller.schedularMessage.value.isNotEmpty)
                      Container(
                        width: controller.containerWidth.value,
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? AppColors.backgroundDark
                                  : AppColors.backgroundLight,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          controller.displayMessage,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            height: 1.5,
                          ),
                        ),
                      ),
                  ],
                ],
              );
            });

            if (isFullWidth) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(child: content),
              );
            } else {
              return Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: content),
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildDraggableElement(MilestoneElement element) {
    return Obx(() {
      final isSelected = controller.selectedElement.value?.id == element.id;

      return Positioned(
        left: element.position.value.dx,
        top: element.position.value.dy,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => controller.selectElement(element),
              onPanUpdate: (details) {
                final elementWidth = element.size.value.width;
                final elementHeight = element.size.value.height;
                final containerWidth = controller.containerWidth.value;
                final containerHeight = controller.containerHeight.value;

                double newX = element.position.value.dx + details.delta.dx;
                double newY = element.position.value.dy + details.delta.dy;

                // Constrain X
                if (newX < 0) newX = 0;
                if (newX + elementWidth > containerWidth) {
                  newX = containerWidth - elementWidth;
                }

                // Constrain Y
                if (newY < 0) newY = 0;
                if (newY + elementHeight > containerHeight) {
                  newY = containerHeight - elementHeight;
                }

                controller.updateElementPosition(element, Offset(newX, newY));
              },
              child: Container(
                width: element.size.value.width,
                height: element.size.value.height,
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border.all(color: const Color(0xFF287DE8), width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: element.type == 'text'
                    ? _buildTextElement(element)
                    : _buildImageElement(element),
              ),
            ),
            if (isSelected)
              Positioned(
                right: -8,
                bottom: -8,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final containerWidth = controller.containerWidth.value;
                    final containerHeight = controller.containerHeight.value;

                    double newWidth =
                        element.size.value.width + details.delta.dx;
                    double newHeight =
                        element.size.value.height + details.delta.dy;

                    // Min size constraints
                    if (newWidth < 40) newWidth = 40;
                    if (newHeight < 20) newHeight = 20;

                    // Bounds constraints
                    if (element.position.value.dx + newWidth > containerWidth) {
                      newWidth = containerWidth - element.position.value.dx;
                    }
                    if (element.position.value.dy + newHeight >
                        containerHeight) {
                      newHeight = containerHeight - element.position.value.dy;
                    }

                    controller.updateElementSize(
                      element,
                      Size(newWidth, newHeight),
                    );
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildTextElement(MilestoneElement element) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(8),
        alignment: element.textAlign.value == 'left'
            ? Alignment.centerLeft
            : element.textAlign.value == 'right'
            ? Alignment.centerRight
            : Alignment.center,
        child: Text(
          element.content.value,
          textAlign: element.textAlignEnum,
          style: GoogleFonts.getFont(
            element.font.value,
            fontSize: element.fontSize.value.toDouble(),
            color: element.color.value,
            fontWeight: element.fontWeight,
            fontStyle: element.fontStyle,
          ),
        ),
      ),
    );
  }

  Widget _buildImageElement(MilestoneElement element) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.image, size: 32, color: Colors.grey[400]),
      ),
    );
  }
}
