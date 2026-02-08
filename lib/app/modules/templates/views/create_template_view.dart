import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import '../widgets/upload_media_widget.dart';

class CreateTemplateView extends GetView<CreateTemplateController> {
  const CreateTemplateView({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
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
              mobile: _buildMobileLayout(isDark),
              tablet: _buildTabletLayout(isDark),
              desktop: _buildDesktopLayout(isDark),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        _buildFormSection(isDark),
        const SizedBox(height: 32),
        const TemplatePreviewWidget(),
      ],
    );
  }

  Widget _buildTabletLayout(bool isDark) {
    return Column(
      children: [
        _buildFormSection(isDark),
        const SizedBox(height: 32),
        const TemplatePreviewWidget(),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _buildFormSection(isDark)),
        const SizedBox(width: 32),
        const Expanded(flex: 1, child: TemplatePreviewWidget()),
      ],
    );
  }

  Widget _buildFormSection(bool isDark) {
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
                  const SizedBox(height: 24),
                  _buildLanguageField(isDark),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),

        // Template Name
        _buildNameField(isDark),
        const SizedBox(height: 24),

        // Template Type
        _buildTypeField(isDark),
        const SizedBox(height: 24),
        Visibility(
          visible:
              ((controller.templateType.value == 'Text & Media' ||
                  controller.templateType.value == 'Interactive') &&
              controller.selectedMediaType != ''),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [DragDropUploadBox(), const SizedBox(height: 20)],
          ),
        ),
        // Template Format
        _buildFormatField(isDark),
        const SizedBox(height: 20),

        _buildHeaderField(isDark),
        const SizedBox(height: 20),

        // Template Footer
        _buildFooterField(isDark),
        const SizedBox(height: 24),

        // Interactive Actions
        if (controller.templateType.value == "Interactive")
          InteractiveActionsWidget(),
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
            _buildSubmitButton(isDark, controller.isEditMode.value),
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
        ),
        Obx(() {
          return CommonDropdownTextfield<String>(
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
          ),

          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
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
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
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
                onChanged: (value) {
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
          ),
          CommonTextfield(
            controller: controller.nameCtrl,
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

  Widget _buildTypeField(bool isDark) {
    return Obx(() {
      final isMedia =
          controller.templateType.value == 'Text & Media' ||
          controller.templateType.value == 'Interactive';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isMedia ? 1 : 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TemplateFormFieldLabel(
                      label: 'Template Type',
                      helpText:
                          'Your template type should fall under one of these categories.',
                    ),
                    CommonDropdownTextfield<String>(
                      items: const [
                        DropdownMenuItem(value: 'Text', child: Text('Text')),
                        DropdownMenuItem(
                          value: 'Text & Media',
                          child: Text('Text & Media'),
                        ),
                        DropdownMenuItem(
                          value: 'Interactive',
                          child: Text('Interactive'),
                        ),
                      ],
                      initialValue: controller.templateType.value.isEmpty
                          ? null
                          : controller.templateType.value,
                      onChanged: (v) {
                        controller.updateTemplateType(v);
                        if (v == 'Text') {
                          controller.selectedMediaType.value = '';
                        }
                      },
                      hintText: 'Select message type',
                    ),
                  ],
                ),
              ),
              if (isMedia) ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TemplateFormFieldLabel(
                        label: 'Media Sample',
                        helpText: 'Choose the media format for the header.',
                      ),
                      CommonDropdownTextfield<String>(
                        items: controller.mediaOptions
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
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
                  ),
                ),
              ],
            ],
          ),
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
          ),
          CommonTextfield(
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
                            final hasSampleError =
                                controller.sampleValueErrors[index].isNotEmpty;
                            return CommonTextfield(
                              controller: controller.variableControllers[index],
                              hintText: "Sample value",
                              onChanged: (value) {
                                controller.sampleValueErrors[index] = '';
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
    return Obx(() {
      final isDisabled =
          controller.templateType.value == 'Text & Media' ||
          controller.selectedMediaType.isNotEmpty;

      return Tooltip(
        message: isDisabled
            ? "Header is disabled for Text & Media templates"
            : "",
        waitDuration: const Duration(milliseconds: 300),
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TemplateFormFieldLabel(
                label: 'Template Header',
                helpText:
                    'Your message content. Upto 60 characters are allowed.',
                isOptional: true,
              ),
              CommonTextfield(
                enabled: !isDisabled,
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
              if (isDisabled)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Header is disabled for Media templates",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    });
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
}
