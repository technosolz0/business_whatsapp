import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:business_whatsapp/main.dart';
import 'package:business_whatsapp/app/common%20widgets/shimmer_widgets.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../../../Utilities/responsive.dart';
import '../../../controllers/theme_controller.dart';
import '../../../common widgets/standard_page_layout.dart';
import '../../../common widgets/common_textfield.dart';
import '../../../common widgets/common_dropdown_textfield.dart';
import '../../../common widgets/custom_button.dart';
import '../../../common widgets/common_outline_button.dart';
import '../../../core/constants/language_codes.dart';
import '../controllers/create_template_controller.dart';
import '../widgets/template_form_field_label.dart';
import '../widgets/template_preview_widget.dart';
import '../widgets/interactive_actions_widget.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/services.dart';
import '../widgets/upload_media_widget.dart';
import '../../../utilities/constants/app_constants.dart';

class CreateTemplateView extends GetView<CreateTemplateController> {
  final FocusNode _cardFormatFocusNode = FocusNode();
  final ValueNotifier<bool> _isCardFormatFocused = ValueNotifier<bool>(false);

  CreateTemplateView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        controller.cancelCreation();
      },
      child: StandardPageLayout(
        title: 'Create New Template',
        subtitle: 'Design a new WhatsApp message template for your campaigns.',
        showBackButton: true,
        onBack: controller.cancelCreation,
        isContentScrollable: true,
        child: Obx(() {
          final isDark = Get.find<ThemeController>().isDarkMode.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Disclaimer 1 - Review Time
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2D2010)
                      : const Color(0xFFFFEEDB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE87D03).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFE87D03),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Submitted templates are subject to review, and approval may take up to 24 hours.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFFFFB347)
                              : const Color(0xFFE87D03),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.templateCategory.value == 'Utility') ...[
                const SizedBox(height: 12),

                // Disclaimer 2 - Utility Reclassification
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1B0024)
                        : const Color(0xFFF7E5FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFBF00FF).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFBF00FF),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Templates submitted as UTILITY may be reclassified and approved as MARKETING if deemed appropriate.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFFE0B0FF)
                                : const Color(0xFFBF00FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Main content
              Responsive(
                mobile: _buildMobileLayout(context, isDark),
                tablet: _buildTabletLayout(context, isDark),
                desktop: _buildDesktopLayout(context, isDark),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildFormSection(context, isDark),
        const SizedBox(height: 32),
        const TemplatePreviewWidget(),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, bool isDark) {
    return Column(
      children: [
        _buildFormSection(context, isDark),
        const SizedBox(height: 32),
        const TemplatePreviewWidget(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildFormSection(context, isDark)),
        const SizedBox(width: 32),
        const Expanded(flex: 1, child: TemplatePreviewWidget()),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context, bool isDark) {
    final isMobile = Responsive.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category and Language in row
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCategoryField(isDark)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildLanguageField(isDark)),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildCategoryField(isDark),
                  const SizedBox(height: AppConstants.formSpacingMobile),
                  _buildLanguageField(isDark),
                ],
              );
            }
          },
        ),
        SizedBox(
          height: isMobile
              ? AppConstants.formSpacingMobile
              : AppConstants.formSpacing,
        ),

        // Template Name
        _buildNameField(isDark),
        SizedBox(
          height: isMobile
              ? AppConstants.formSpacingMobile
              : AppConstants.formSpacing,
        ),

        // Template Type
        _buildTypeField(context, isDark),
        SizedBox(
          height: isMobile
              ? AppConstants.formSpacingMobile
              : AppConstants.formSpacing,
        ),
        Visibility(
          visible:
              ((controller.templateType.value == 'Text & Media' ||
                  controller.templateType.value == 'Interactive') &&
              controller.selectedMediaType.value != ''),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DragDropUploadBox(),
              SizedBox(
                height: isMobile
                    ? AppConstants.formSpacingMobile
                    : AppConstants.formSpacing,
              ),
            ],
          ),
        ),
        // Template Format
        _buildFormatField(isDark),
        SizedBox(
          height: isMobile
              ? AppConstants.formSpacingMobile
              : AppConstants.formSpacing,
        ),

        if (controller.templateType.value != "Carousel") ...[
          Obx(() {
            final isMediaHeader =
                controller.templateType.value == 'Text & Media' ||
                controller.selectedMediaType.isNotEmpty;
            if (isMediaHeader) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderField(isDark),
                SizedBox(
                  height: isMobile
                      ? AppConstants.formSpacingMobile
                      : AppConstants.formSpacing,
                ),
              ],
            );
          }),
        ],

        // Template Footer
        if (controller.templateType.value != "Carousel") ...[
          _buildFooterField(isDark),
          SizedBox(
            height: isMobile
                ? AppConstants.formSpacingMobile
                : AppConstants.formSpacing,
          ),
        ],

        // Interactive Actions
        if (controller.templateType.value == "Interactive")
          Obx(
            () => AbsorbPointer(
              absorbing: controller.isViewMode.value,
              child: Opacity(
                opacity: controller.isViewMode.value ? 0.5 : 1.0,
                child: InteractiveActionsWidget(),
              ),
            ),
          ),

        // Carousel UI
        if (controller.templateType.value == "Carousel")
          Obx(
            () => AbsorbPointer(
              absorbing: controller.isViewMode.value,
              child: Opacity(
                opacity: controller.isViewMode.value ? 0.5 : 1.0,
                child: _buildCarouselUI(isDark),
              ),
            ),
          ),
        Obx(() {
          final isMarketing = controller.templateCategory.value == "Marketing";
          final isInteractive = controller.templateType.value == "Interactive";
          final isImage = controller.selectedMediaType.value == "Image";
          final hasUrlButton = controller.buttons.any((b) => b.type == "URL");

          if (isMarketing && isInteractive && isImage && hasUrlButton) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'As per change to the Meta guidelines: The image used will be linked to the attached URL.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
        const SizedBox(height: 32),

        // Submit Button
        Row(
          children: [
            CommonOutlineButton(
              label: 'Back to Templates',
              onPressed: controller.cancelCreation,
              icon: Icons.arrow_back,
            ),
            SizedBox(width: 20),
            Obx(
              () => controller.isViewMode.value
                  ? const SizedBox.shrink()
                  : _buildSubmitButton(isDark, controller.isEditMode.value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TemplateFormFieldLabel(
          label: 'Template Category',
          helpText: 'Your template should fall under one of these categories.',
          isRequired: true,
        ),
        Obx(() {
          return CommonDropdownTextfield<String>(
            enabled: !controller.isViewMode.value,
            items: controller.categoryOptions
                .skip(1)
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            initialValue: controller.templateCategory.value.isEmpty
                ? null
                : controller.templateCategory.value,
            onChanged: controller.updateTemplateCategory,
            hintText: 'Select message categories',
          );
        }),
      ],
    );
  }

  Widget _buildLanguageField(bool isDark) {
    return Obx(() {
      final hasError = controller.languageError.value.isNotEmpty;
      final allItems = LanguageCodes.languageList;

      String? dropdownValue =
          allItems.any(
            (langName) =>
                LanguageCodes.languageCodeMap[langName] ==
                controller.templateLanguage.value,
          )
          ? controller.templateLanguage.value
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TemplateFormFieldLabel(
            label: 'Template Language',
            helpText: 'Select or enter the language code manually.',
            isRequired: true,
          ),

          Container(
            decoration: BoxDecoration(
              color: controller.isViewMode.value
                  ? (isDark ? const Color(0xFF1A1A1A) : Colors.grey[200])
                  : (isDark ? const Color(0xFF2A2A2A) : Colors.white),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasError
                    ? Colors.red
                    : (isDark ? Colors.grey[700]! : const Color(0xFFE0E0E0)),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<String>(
                isExpanded: true,
                dropdownSearchData: DropdownSearchData(
                  searchController: controller.searchCtrl,
                  searchInnerWidgetHeight: 50,
                  searchMatchFn: (item, searchValue) {
                    final langName = allItems.firstWhere(
                      (name) =>
                          LanguageCodes.languageCodeMap[name] == item.value,
                      orElse: () => '',
                    );
                    final code = item.value.toString();
                    final search = searchValue.toLowerCase();
                    return langName.toLowerCase().contains(search) ||
                        code.toLowerCase().contains(search);
                  },
                  searchInnerWidget: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: controller.searchCtrl,
                      maxLength: 50,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: 'Search or enter language code...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey[700]!
                                : const Color(0xFFE0E0E0),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF137FEC), // Standard primary color
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1F2937)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                iconStyleData: IconStyleData(
                  icon: Icon(
                    Icons.keyboard_arrow_down_outlined,
                    size: 20,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                buttonStyleData: const ButtonStyleData(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  height: 48,
                ),
                value: dropdownValue,
                hint: Text(
                  'Select or type language code',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : const Color(0xFFBDC3C7),
                    fontSize: 14,
                  ),
                ),
                items: allItems.map((langName) {
                  final code = LanguageCodes.languageCodeMap[langName]!;
                  return DropdownMenuItem(
                    value: code,
                    child: Row(
                      children: [
                        Text(
                          langName,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "($code)",
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: controller.isViewMode.value
                    ? null
                    : (value) {
                        controller.templateLanguage.value = value!;
                        controller.searchCtrl.clear();
                      },
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 350,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                controller.languageError.value,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildNameField(bool isDark) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TemplateFormFieldLabel(
            label: 'Template Name',
            helpText:
                'Only lowercase letters, numbers, and underscores allowed. Spaces convert to underscores.',
            isRequired: true,
          ),
          CommonTextfield(
            enabled: !controller.isViewMode.value,
            controller: controller.nameCtrl,
            maxLength: 100,
            hintText: 'Enter name',
            onChanged: (value) async {
              String original = value;
              String newValue = original.toLowerCase().replaceAll(" ", "_");
              bool invalid = RegExp(r'[^a-z0-9_]').hasMatch(newValue);
              newValue = newValue.replaceAll(RegExp(r'[^a-z0-9_]'), '');

              if (invalid) {
                controller.nameError.value =
                    "Only lowercase letters, numbers & underscores allowed";
              } else {
                controller.nameError.value = "";
              }

              if (newValue != original) {
                controller.nameCtrl.value = TextEditingValue(
                  text: newValue,
                  selection: TextSelection.collapsed(offset: newValue.length),
                );
              }

              controller.templateName.value = newValue;
              controller.languageError.value = '';

              if (newValue.isNotEmpty && !invalid) {
                controller.isCheckingName.value = true;
                final valid = await controller.validateTemplateName(
                  requestFocus: false,
                );
                if (valid) controller.nameError.value = "";
                controller.isCheckingName.value = false;
              }
            },
            suffixIcon: Obx(() {
              if (controller.isCheckingName.value) {
                return const SizedBox(
                  width: 18,
                  height: 18,
                  child: Center(child: CircleShimmer(size: 18)),
                );
              }
              if (controller.nameError.value.isNotEmpty) {
                return const Icon(Icons.error, color: Colors.red, size: 20);
              }
              return const SizedBox.shrink();
            }),
            validator: (value) => controller.nameError.value.isNotEmpty
                ? controller.nameError.value
                : null,
          ),
          if (controller.nameError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                controller.nameError.value,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildTypeField(BuildContext context, bool isDark) {
    final isMobile = Responsive.isMobile(context);
    return Obx(() {
      final isCategorySelected =
          controller.templateCategory.value.isNotEmpty &&
          controller.templateCategory.value != 'Select message categories';

      final isMedia =
          controller.templateType.value == 'Text & Media' ||
          controller.templateType.value == 'Interactive';

      final typeField = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TemplateFormFieldLabel(
            label: 'Template Type',
            helpText:
                'Your template type should fall under one of these categories.',
            isRequired: true,
          ),
          CommonDropdownTextfield<String>(
            enabled: isCategorySelected && !controller.isViewMode.value,
            items: [
              const DropdownMenuItem(value: 'Text', child: Text('Text')),
              const DropdownMenuItem(
                value: 'Text & Media',
                child: Text('Text & Media'),
              ),
              const DropdownMenuItem(
                value: 'Interactive',
                child: Text('Interactive'),
              ),
              if (controller.templateCategory.value == 'Marketing' &&
                  isCarouselTemplateEnabled.value == true)
                const DropdownMenuItem(
                  value: 'Carousel',
                  child: Text('Carousel'),
                ),
            ],
            initialValue:
                controller.templateType.value.isEmpty || !isCategorySelected
                ? null
                : controller.templateType.value,
            onChanged: (v) {
              controller.updateTemplateType(v);
              if (v == 'Text') {
                controller.selectedMediaType.value = '';
              }
            },
            hintText: isCategorySelected
                ? 'Select message type'
                : 'Select category first',
          ),
        ],
      );

      final mediaField = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TemplateFormFieldLabel(
            label: 'Media Sample',
            helpText: 'Choose the media format for the header.',
          ),
          CommonDropdownTextfield<String>(
            enabled: !controller.isViewMode.value,
            items: controller.mediaOptions
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            initialValue: controller.selectedMediaType.value.isEmpty
                ? null
                : controller.selectedMediaType.value,
            onChanged: (v) {
              controller.updateMediaType(v);
              controller.selectedMediaType.value = v ?? "";
            },
            hintText: 'Select media type',
          ),
        ],
      );

      if (isMobile) {
        return Column(
          children: [
            typeField,
            if (isMedia) ...[
              const SizedBox(height: AppConstants.formSpacingMobile),
              mediaField,
            ],
          ],
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: isMedia ? 1 : 2, child: typeField),
          if (isMedia) ...[
            const SizedBox(width: 24),
            Expanded(flex: 1, child: mediaField),
          ],
        ],
      );
    });
  }

  Widget _buildFormatField(bool isDark) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TemplateFormFieldLabel(
            label: 'Template Format',
            helpText:
                'Use text formating. *bold*, _italic_, ~strikethrough~. Your message content. Upto 1024 characters are allowed. e.g - Hello {{1}}, your code will expire in {{2}} mins.',
            isRequired: true,
          ),
          CommonTextfield(
            enabled: !controller.isViewMode.value,
            controller: controller.formatCtrl,
            maxLines: 4,
            maxLength: 1024,
            hintText: 'Enter your message in here...',
            onChanged: (value) {
              controller.updateTemplateFormat(value);
              controller.formatError.value = '';
            },
            validator: (value) => controller.formatError.value.isNotEmpty
                ? controller.formatError.value
                : null,
          ),
          if (controller.formatError.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                controller.formatError.value,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          if (controller.variableControllers.isNotEmpty)
            const SizedBox(height: 20),

          // ---------------- SAMPLE VALUES SECTION ----------------
          Obx(() {
            if (controller.variableControllers.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION TITLE
                Text(
                  "Sample Values",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),

                const SizedBox(height: 6),

                // DESCRIPTION
                Text(
                  "Specify sample values for your parameters. "
                  "These values can be changed at the time of sending. "
                  "e.g. - {{1}}: Mohit, {{2}}: 5.",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),

                const SizedBox(height: 16),

                // REPEATING PARAMETER FIELDS
                ...List.generate(controller.variableControllers.length, (
                  index,
                ) {
                  final num = index + 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : const Color(0xFFE0E0E0),
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                          ),
                          child: Text(
                            "{{$num}}",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Obx(() {
                            // Guard: indices must still be valid after reactive rebuild
                            if (index >= controller.sampleValueErrors.length ||
                                index >=
                                    controller.variableControllers.length) {
                              return const SizedBox.shrink();
                            }
                            final hasSampleError =
                                controller.sampleValueErrors[index].isNotEmpty;
                            return CommonTextfield(
                              enabled: !controller.isViewMode.value,
                              controller: controller.variableControllers[index],
                              maxLength: 100,
                              hintText: "Sample value",
                              onChanged: (value) {
                                if (index <
                                    controller.sampleValueErrors.length) {
                                  controller.sampleValueErrors[index] = '';
                                }
                              },
                              validator: (value) => hasSampleError
                                  ? controller.sampleValueErrors[index]
                                  : null,
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      );
    });
  }

  Widget _buildHeaderField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TemplateFormFieldLabel(
          label: 'Template Header',
          helpText: 'Your message content. Upto 60 characters are allowed.',
          isOptional: true,
        ),
        CommonTextfield(
          enabled: !controller.isViewMode.value,
          controller: controller.headerCtrl,
          maxLength: 60,
          hintText: 'Enter header text here',
          onChanged: (value) {
            if (value.length > 60) {
              controller.headerError.value =
                  "Header must be under 60 characters";
            } else {
              controller.headerError.value = "";
            }
          },
          validator: (value) => controller.headerError.value.isNotEmpty
              ? controller.headerError.value
              : null,
        ),
      ],
    );
  }

  Widget _buildFooterField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TemplateFormFieldLabel(
          label: 'Template Footer',
          helpText: 'Your message content. Upto 60 characters are allowed.',
          isOptional: true,
        ),
        CommonTextfield(
          enabled: !controller.isViewMode.value,
          controller: controller.footerCtrl,
          maxLength: 60,
          hintText: 'Enter footer text here',
          onChanged: (value) {
            if (value.length > 60) {
              controller.footerError.value =
                  "Footer must be under 60 characters";
            } else {
              controller.footerError.value = "";
            }
          },
          validator: (value) => controller.footerError.value.isNotEmpty
              ? controller.footerError.value
              : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(bool isDark, bool isEdit) {
    return Obx(
      () => CustomButton(
        label: isEdit ? 'Update' : 'Submit',
        onPressed: controller.submitTemplate,
        type: ButtonType.primary,
        isLoading: controller.isSubmitting.value,
      ),
    );
  }

  Widget _buildCarouselUI(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cards',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100, // Increased slightly to accommodate scrollbar height
          child: Obx(() {
            return Scrollbar(
              key: ValueKey(controller.carouselCards.length),
              controller: controller.carouselScrollCtrl,
              thumbVisibility: true,
              trackVisibility: true,
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ), // Space for scrollbar
                child: ListView.separated(
                  controller: controller.carouselScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.carouselCards.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == controller.carouselCards.length) {
                      return _buildAddCardButton(isDark);
                    }
                    return _buildCardThumbnail(index, isDark);
                  },
                ),
              ),
            );
          }),
        ),
        // const SizedBox(height: 16),

        // Custom Bubble details panel with upward pointer composed in a Stack
        Obx(() {
          if (controller.carouselCards.isEmpty) return const SizedBox.shrink();

          // Animate the arrow pointer horizontally!
          // Thumbnail: width 100 + space 12 = 112px per item.
          // Thumbnail starts with some padding, let's say index * 112 + 40
          final cardIndex = controller.selectedCardIndex.value;
          final double thumbnailWidth = 130.0;
          final double spacing = 12.0;
          final double initialOffset = 57.0;

          double targetArrowOffset =
              initialOffset + (cardIndex * (thumbnailWidth + spacing));

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. White/Dark Bubble Card Panel (shifted down to leave space for pointer)
              Container(
                margin: const EdgeInsets.only(top: 12.0),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : const Color(0xFFE0E0E0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCardMediaSection(isDark),
                    const SizedBox(height: 32),
                    _buildCardFormatSection(isDark),
                    const SizedBox(height: 32),
                    _buildCardButtonsSection(isDark),
                  ],
                ),
              ),

              // 2. Pointer arrow (positioned at top, rendering on top of container to mask the border!)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                top: 0,
                left: targetArrowOffset.clamp(32.0, 600.0),
                child: CustomPaint(
                  size: const Size(16, 13),
                  painter: TrianglePainter(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderColor: isDark
                        ? Colors.grey[800]!
                        : const Color(0xFFE0E0E0),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAddCardButton(bool isDark) {
    return InkWell(
      onTap: controller.addCarouselCard,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Widget _buildCardThumbnail(int index, bool isDark) {
    return Obx(() {
      if (index < 0 || index >= controller.carouselCards.length) {
        return const SizedBox.shrink();
      }
      final card = controller.carouselCards[index];
      final isSelected = controller.selectedCardIndex.value == index;

      return InkWell(
        onTap: () => controller.selectCarouselCard(index),
        child: Stack(
          children: [
            Container(
              width: 130,
              height: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF137FEC)
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: isSelected ? 2 : 1,
                ),
                image: card.fileBytes.value != null
                    ? DecorationImage(
                        image: MemoryImage(card.fileBytes.value!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: card.fileBytes.value == null
                  ? Icon(
                      card.mediaType.value == 'Image'
                          ? Icons.image
                          : Icons.videocam,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    )
                  : null,
            ),
            if (isSelected)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: InkWell(
                onTap: () => controller.removeCarouselCard(index),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildCardMediaSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Media',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload either an image or video',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.carouselCards.isEmpty) return const SizedBox.shrink();
          final cardIndex = controller.selectedCardIndex.value;
          if (cardIndex < 0 || cardIndex >= controller.carouselCards.length) {
            return const SizedBox.shrink();
          }
          final card = controller.carouselCards[cardIndex];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Type Selection (only editable on Card 0)
              if (cardIndex == 0) ...[
                Row(
                  children: [
                    Text(
                      'Media Type: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 150,
                      child: CommonDropdownTextfield<String>(
                        enabled: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'Image',
                            child: Text('Image'),
                          ),
                          DropdownMenuItem(
                            value: 'Video',
                            child: Text('Video'),
                          ),
                        ],
                        initialValue: card.mediaType.value,
                        onChanged: controller.updateCardMedia,
                        hintText: 'Select media type',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Media Type: ${card.mediaType.value} (Locked from Card 1)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Custom Dashed Drag-Drop-Style Upload Box
              Obx(
                () => MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: controller.isUploadingMedia.value
                        ? null
                        : controller.pickCardFile,
                    child: CustomPaint(
                      painter: DashedBorderPainter(
                        color: isDark
                            ? Colors.grey.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.4),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 28,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.grey.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: controller.isUploadingMedia.value
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF137FEC),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "Uploading media... Please wait",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: Color(0xFF137FEC),
                                    size: 38,
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Upload Media",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Add an image or video to this card. Click below to start.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (card.fileName.value.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        "File Name: ${card.fileName.value}",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF137FEC),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCardFormatSection(bool isDark) {
    return Obx(() {
      if (controller.carouselCards.isEmpty) return const SizedBox.shrink();
      final cardIndex = controller.selectedCardIndex.value;
      if (cardIndex < 0 || cardIndex >= controller.carouselCards.length) {
        return const SizedBox.shrink();
      }
      final card = controller.carouselCards[cardIndex];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Template Format',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Use text formatting - *bold* , _italic_ & ~strikethrough~ . Your message content . Upto 1024 charachters are allowed',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Outer Rich Editor Container with dynamic blue border when focused
          Focus(
            onFocusChange: (focused) {
              _isCardFormatFocused.value = focused;
            },
            child: ValueListenableBuilder<bool>(
              valueListenable: _isCardFormatFocused,
              builder: (context, isFocused, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isFocused
                          ? const Color(0xFF137FEC)
                          : (isDark
                                ? Colors.grey[700]!
                                : const Color(0xFFE0E0E0)),
                      width: isFocused ? 1.5 : 1,
                    ),
                    color: isDark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF9FAFB),
                  ),
                  child: Column(
                    children: [
                      // Toolbar Row
                      Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF262626)
                              : const Color(0xFFF1F3F5),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(7),
                            topRight: Radius.circular(7),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildToolbarButton(
                              icon: Icons.format_bold,
                              onTap: () => _insertFormatting('*', '*'),
                              tooltip: 'Bold',
                              isDark: isDark,
                            ),
                            _buildToolbarButton(
                              icon: Icons.format_italic,
                              onTap: () => _insertFormatting('_', '_'),
                              tooltip: 'Italic',
                              isDark: isDark,
                            ),
                            _buildToolbarButton(
                              icon: Icons.format_underline,
                              onTap: () => _insertFormatting('', ''),
                              tooltip: 'Underline',
                              isDark: isDark,
                            ),
                            _buildToolbarButton(
                              icon: Icons.format_line_spacing,
                              onTap: () => _insertFormatting('~', '~'),
                              tooltip: 'Strikethrough',
                              isDark: isDark,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 20,
                              color: isDark
                                  ? Colors.grey[750]
                                  : Colors.grey[300],
                            ),
                            const SizedBox(width: 8),
                            _buildToolbarButton(
                              icon: Icons.link,
                              onTap: () => _insertFormatting(' https://', ''),
                              tooltip: 'Insert Link',
                              isDark: isDark,
                            ),
                            _buildToolbarButton(
                              icon: Icons.sentiment_satisfied_alt,
                              onTap: () => _insertFormatting('😊', ''),
                              tooltip: 'Insert Emoji',
                              isDark: isDark,
                            ),
                            const Spacer(),

                            // Reactive character counter
                            Obx(() {
                              final textLength = card.body.value.length;
                              return Text(
                                "$textLength/1024",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      // Text Field input
                      TextField(
                        controller: controller.cardFormatCtrl,
                        focusNode: _cardFormatFocusNode,
                        maxLines: 5,
                        maxLength: 1024,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter card message here...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        onChanged: controller.updateCardBody,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (card.variableControllers.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              "Sample Values",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Specify sample values for your parameters.",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(card.variableControllers.length, (index) {
              final num = index + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? Colors.grey[700]!
                              : const Color(0xFFE0E0E0),
                        ),
                        borderRadius: BorderRadius.circular(6),
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                      ),
                      child: Text("{{$num}}"),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonTextfield(
                        controller: card.variableControllers[index],
                        maxLength: 100,
                        hintText: "Sample value",
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      );
    });
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required bool isDark,
  }) {
    return Material(
      color: Colors.transparent,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onTap,
        tooltip: tooltip,
        splashRadius: 18,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
        color: isDark ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }

  void _insertFormatting(String prefix, String suffix) {
    final text = controller.cardFormatCtrl.text;
    final selection = controller.cardFormatCtrl.selection;

    int start = selection.start;
    int end = selection.end;

    if (start < 0 || end < 0) {
      start = text.length;
      end = text.length;
    }

    final selectedText = text.substring(start, end);
    final replacement = "$prefix$selectedText$suffix";

    final newText = text.replaceRange(start, end, replacement);
    controller.cardFormatCtrl.text = newText;
    controller.updateCardBody(newText);

    // Update selection
    controller.cardFormatCtrl.selection = TextSelection(
      baseOffset: start + prefix.length,
      extentOffset: start + prefix.length + selectedText.length,
    );
  }

  Widget _buildCardButtonsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            const Text(
              'Buttons',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Add upto two buttons to builder.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.carouselCards.isEmpty) return const SizedBox.shrink();
          final cardIndex = controller.selectedCardIndex.value;
          if (cardIndex < 0 || cardIndex >= controller.carouselCards.length) {
            return const SizedBox.shrink();
          }
          final card = controller.carouselCards[cardIndex];
          final hasUrlButton = card.buttons.any((btn) => btn.type == 'URL');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(card.buttons.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCardButtonRow(index, isDark),
                );
              }),
              if (card.buttons.length < 2) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: controller.addCardButton,
                    icon: const Icon(
                      Icons.add,
                      color: Color(0xFF137FEC),
                      size: 18,
                    ),
                    label: const Text(
                      'Add Button',
                      style: TextStyle(
                        color: Color(0xFF137FEC),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
              if (hasUrlButton) ...[
                const SizedBox(height: 16),
                _buildCommonLinkTrackingCheckbox(isDark),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _buildCardButtonRow(int index, bool isDark) {
    return Obx(() {
      if (controller.carouselCards.isEmpty) return const SizedBox.shrink();
      final cardIndex = controller.selectedCardIndex.value;
      if (cardIndex < 0 || cardIndex >= controller.carouselCards.length) {
        return const SizedBox.shrink();
      }
      final card = controller.carouselCards[cardIndex];
      if (index >= card.buttons.length) return const SizedBox.shrink();
      final btn = card.buttons[index];

      return Row(
        key: ValueKey("card_${cardIndex}_btn_$index"),
        children: [
          const Icon(Icons.drag_indicator, color: Colors.grey),
          const SizedBox(width: 12),

          // Dropdown for Button Type
          Expanded(
            flex: 2,
            child: CommonDropdownTextfield<String>(
              items: [
                const DropdownMenuItem(
                  value: 'QUICK_REPLY',
                  child: Text('Quick Reply'),
                ),
                const DropdownMenuItem(value: 'URL', child: Text('Link')),
                if (!card.buttons.any(
                  (b) =>
                      b.type == 'PHONE_NUMBER' &&
                      card.buttons.indexOf(b) != index,
                ))
                  const DropdownMenuItem(
                    value: 'PHONE_NUMBER',
                    child: Text('Phone'),
                  ),
              ],
              initialValue: btn.type.isEmpty ? null : btn.type,
              onChanged: (v) => controller.updateCardButtonType(index, v!),
              hintText: 'Choose your button type',
            ),
          ),
          const SizedBox(width: 12),

          // Conditional Input for Link/Phone
          if (btn.type != 'QUICK_REPLY')
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  if (btn.type == 'PHONE_NUMBER') ...[
                    CountryCodePicker(
                      onChanged: (code) => controller
                          .updateCardPhoneCountryCode(index, code.dialCode!),
                      initialSelection: index < card.countryCodes.length
                          ? card.countryCodes[index]
                          : "+91",
                      favorite: const ["+91", "+1"],
                      showDropDownButton: true,
                      padding: EdgeInsets.zero,
                      textStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommonTextfield(
                          hintText: btn.type == 'URL' ? 'Link' : 'Phone',
                          maxLength: 100,
                          onChanged: (v) =>
                              controller.updateCardButtonValue(index, v),
                          initialValue: btn.type == 'URL'
                              ? btn.url
                              : _getRawPhone(
                                  btn.phoneNumber,
                                  index < card.countryCodes.length
                                      ? card.countryCodes[index]
                                      : "+91",
                                ),
                          inputFormatter: btn.type == 'PHONE_NUMBER'
                              ? [FilteringTextInputFormatter.digitsOnly]
                              : null,
                          validator: (v) =>
                              (index < card.buttonValueErrors.length &&
                                  card.buttonValueErrors[index].isNotEmpty)
                              ? card.buttonValueErrors[index]
                              : null,
                        ),
                        if (index < card.buttonValueErrors.length &&
                            card.buttonValueErrors[index].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              card.buttonValueErrors[index],
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),

          // Button Label
          Expanded(
            flex: 2,
            child: CommonTextfield(
              hintText: 'Label',
              maxLength: 25,
              onChanged: (v) => controller.updateCardButtonText(index, v),
              initialValue: btn.text,
            ),
          ),
          const SizedBox(width: 12),

          // Delete icon button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => controller.removeCardButton(index),
            splashRadius: 20,
            tooltip: "Delete Button",
          ),
        ],
      );
    });
  }

  Widget _buildCommonLinkTrackingCheckbox(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Obx(
              () => Checkbox(
                side: BorderSide(color: Colors.black),
                value: !controller.ctaUrlLinkTrackingOptedOut.value,
                activeColor: const Color(0xFF137FEC),
                onChanged: (val) {
                  if (val != null) {
                    controller.ctaUrlLinkTrackingOptedOut.value = !val;
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "When tracking is enabled, WhatsApp may show a branded link to customers which will redirect to your website",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRawPhone(String? fullPhone, String countryCode) {
    if (fullPhone == null || fullPhone.isEmpty) return "";
    if (fullPhone.startsWith(countryCode)) {
      return fullPhone.substring(countryCode.length);
    }
    return fullPhone;
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = 1.5; // Radius for rounding the tip beautifully

    // 1. Draw the filled rounded triangle extending slightly downwards to overlap card top edge
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, h + 1.5)
      ..lineTo(w / 2 - r, r)
      ..quadraticBezierTo(w / 2, 0, w / 2 + r, r)
      ..lineTo(w, h + 1.5)
      ..close();

    canvas.drawPath(path, paint);

    // 2. Draw only the left and right slopes (borders) of the triangle
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final borderPath = Path()
      ..moveTo(-0.2, h + 0.5)
      ..lineTo(w / 2 - r, r)
      ..quadraticBezierTo(w / 2, 0, w / 2 + r, r)
      ..lineTo(w + 0.2, h + 0.5);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
