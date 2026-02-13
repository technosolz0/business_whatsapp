import 'package:adminpanel/app/modules/broadcasts/views/widgets/sample_variable_input.dart';
import 'package:adminpanel/app/modules/broadcasts/widgets/interactive_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/create_broadcast_controller.dart';

class TemplateCardWidget extends StatelessWidget {
  const TemplateCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = Get.find<CreateBroadcastController>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select Template",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),

          /// TEMPLATE DROPDOWN
          _templateDropdown(isDark, ctrl),

          const SizedBox(height: 24),

          Obx(() {
            final param = ctrl.selectedTemplateParams.value;

            // Nothing selected at all
            if (param == null) {
              return const Text("Select a template to load parameters.");
            }

            // Template selected but has ZERO parameters
            final bool hasNoParams =
                // param.headerVars == 0 ||
                param.bodyVars == 0;

            final bool hasNoButtonsParams = param.buttonVars == 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ONLY SHOW PARAMETER TITLE & CHIPS IF PARAMETERS EXIST
                if (!hasNoParams) ...[
                  Text(
                    "Template Parameters",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// GLOBAL CHIP LIST
                  GlobalChipList(chips: ctrl.availableChips),

                  const SizedBox(height: 12),

                  /// HEADER PARAMS
                  if (param.headerVars > 0) ...[
                    for (int i = 1; i <= param.headerVars; i++)
                      _paramField(num: i, keyName: "header_$i", ctrl: ctrl),
                    const SizedBox(height: 20),
                  ],

                  /// BODY PARAMS
                  if (param.bodyVars > 0) ...[
                    for (int i = 1; i <= param.bodyVars; i++)
                      _paramField(num: i, keyName: "body_$i", ctrl: ctrl),
                  ],

                  const SizedBox(height: 20),
                ],

                /// INTERACTIVE BUTTONS (Always visible)
                if (!hasNoButtonsParams)
                  BroadcastActionsWidget(isDark: isDark, controller: ctrl),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _templateDropdown(bool isDark, CreateBroadcastController ctrl) {
    return Obx(() {
      final templates = ctrl.templateList;

      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1A29) : const Color(0xFFF6F7F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        child: DropdownButtonFormField<String>(
          initialValue: ctrl.selectedTemplateId.value.isEmpty
              ? null
              : ctrl.selectedTemplateId.value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          dropdownColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          hint: const Text("Select a template"),
          items: templates
              .map(
                (t) => DropdownMenuItem(
                  value: t.id,
                  child: Text('${t.name} - ${t.category}'),
                ),
              )
              .toList(),
          onChanged: (templateId) {
            if (templateId != null) {
              ctrl.onTemplateSelected(templateId);
            }
          },
        ),
      );
    });
  }

  /// PARAM ROW USING SampleVariableInput
  Widget _paramField({
    required int num,
    required String keyName,
    required CreateBroadcastController ctrl,
  }) {
    ctrl.ensureParamKey(keyName); // make sure controller & error exist

    return SampleVariableInput(
      num: num,
      ctrl: ctrl,
      controller: ctrl.paramControllers[keyName]!,
      errorText: ctrl.paramErrors[keyName]!,
      acceptedChips: ctrl.availableChips,
      onValueChanged: (type, value) {
        ctrl.variableValues[keyName] = {"type": type, "value": value};
        ctrl.updatePreviewBody();
      },
    );
  }
}
