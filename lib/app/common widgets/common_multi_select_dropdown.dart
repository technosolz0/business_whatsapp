import 'package:adminpanel/app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonMultiSelectDropdown extends StatefulWidget {
  final String label;
  final List<String> items;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onSelectionChanged;
  final bool isRequired;
  final bool enabled;

  const CommonMultiSelectDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.initialSelected,
    required this.onSelectionChanged,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  State<CommonMultiSelectDropdown> createState() =>
      _CommonMultiSelectDropdownState();
}

class _CommonMultiSelectDropdownState extends State<CommonMultiSelectDropdown> {
  late List<String> selectedItems;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.initialSelected);
  }

  void toggleItem(String item) {
    if (!widget.enabled) return; // ❌ block all selection
    setState(() {
      if (selectedItems.contains(item)) {
        selectedItems.remove(item);
      } else {
        selectedItems.add(item);
      }
      widget.onSelectionChanged(selectedItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    Color borderColor = widget.enabled ? const Color(0xFFE0E0E0) : Colors.grey;
    Color focusedBorderColor = AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: GoogleFonts.publicSans(
                fontSize: 13,
                color: const Color(0xFF1A1A1A),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (widget.isRequired) const SizedBox(width: 3),
            if (widget.isRequired)
              Text("*", style: TextStyle(color: Color(0xFFE74C3C))),
          ],
        ),
        const SizedBox(height: 8),

        // MAIN FIELD
        GestureDetector(
          onTap: widget.enabled
              ? () => setState(() => isExpanded = !isExpanded)
              : null,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: selectedItems.isEmpty ? 11 : 8,
            ),
            decoration: BoxDecoration(
              color: widget.enabled ? Colors.white : Colors.grey.shade200,
              border: Border.all(
                color: isExpanded ? focusedBorderColor : borderColor,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: selectedItems.isEmpty
                      ? Text(
                          'Select Here',
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            color: widget.enabled
                                ? const Color(0xFFBDC3C7)
                                : Colors.grey,
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: selectedItems.map((item) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1A2B9B,
                                ).withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item,
                                    style: GoogleFonts.publicSans(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (widget.enabled)
                                    GestureDetector(
                                      onTap: () => toggleItem(item),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: widget.enabled ? Colors.grey[700] : Colors.grey,
                ),
              ],
            ),
          ),
        ),

        // ITEMS DROPDOWN
        if (isExpanded && widget.enabled)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = selectedItems.contains(item);

                return InkWell(
                  onTap: () => toggleItem(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item,
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
