import 'package:business_whatsapp/app/modules/milestone_templates/controllers/create_milestone_schedular_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MilestoneVariableInput extends StatefulWidget {
  final int num;
  final List<String> acceptedChips;
  final TextEditingController controller;
  final RxString errorText;
  final Function(String type, String value) onValueChanged;
  final CreateMilestoneSchedularController ctrl;

  const MilestoneVariableInput({
    super.key,
    required this.num,
    required this.acceptedChips,
    required this.ctrl,
    required this.controller,
    required this.errorText,
    required this.onValueChanged,
  });

  @override
  State<MilestoneVariableInput> createState() => _MilestoneVariableInputState();
}

class _MilestoneVariableInputState extends State<MilestoneVariableInput> {
  bool _isProgrammaticUpdate = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // {{n}}
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF4B5563) : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(6),
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
            ),
            child: Text(
              "{{${widget.num}}}",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Main text input
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (chipDetail) {
                final chipValue = chipDetail.data;
                if (!widget.acceptedChips.contains(chipValue)) return;

                _isProgrammaticUpdate = true;
                widget.controller.text = chipValue;
                _isProgrammaticUpdate = false;

                widget.errorText.value = "";
                widget.onValueChanged("dynamic", chipValue);

                widget.ctrl.previewRefresh.value++;
              },
              builder: (context, candidate, rejected) {
                return Obx(() {
                  return TextField(
                    controller: widget.controller,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onChanged: (value) {
                      if (_isProgrammaticUpdate) return;

                      widget.errorText.value = "";
                      widget.onValueChanged("static", value);
                      widget.ctrl.previewRefresh.value++;
                    },
                    decoration: InputDecoration(
                      hintText: "Sample value",
                      errorText: widget.errorText.value.isNotEmpty
                          ? widget.errorText.value
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF4B5563)
                              : Colors.grey[300]!,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalChipList extends StatelessWidget {
  final List<String> chips;

  const GlobalChipList({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((chip) {
        return Draggable<String>(
          data: chip,
          feedback: Material(
            color: Colors.transparent,
            child: _chip(chip, true, isDark),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _chip(chip, false, isDark),
          ),
          child: _chip(chip, false, isDark),
        );
      }).toList(),
    );
  }

  Widget _chip(String label, bool dragMode, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? const Color(0xFF242424) : const Color(0xFFF1F5F9),
        border: Border.all(
          color: isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: dragMode
              ? const Color(0xFF137FEC)
              : (isDark ? Colors.white : const Color(0xFF334155)),
        ),
      ),
    );
  }
}
