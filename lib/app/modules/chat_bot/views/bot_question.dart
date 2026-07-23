import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:business_whatsapp/app/common%20widgets/dotted_border.dart';
import 'package:business_whatsapp/app/common%20widgets/standard_page_layout.dart';
import 'package:business_whatsapp/app/core/theme/app_colors.dart';
import 'package:business_whatsapp/app/modules/chat_bot/controllers/bot_question_controller.dart';

class BotQuestionView extends GetView<BotQuestionController> {
  const BotQuestionView({super.key});

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: "Questions",
      showBackButton: true,
      isContentScrollable: true,
      child: Obx(
        () => ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.questions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildQuestionCard(index, context);
          },
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, BuildContext context) {
    final question = controller.questions[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPending = question.status == 'pending';

    return Obx(() {
      final isExpanded = question.isExpanded.value;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: badge + question + timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBadge(question.status),
                        const SizedBox(height: 10),
                        Text(
                          question.question,
                          style: GoogleFonts.publicSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.timestamp.toLowerCase().contains("received")
                              ? question.timestamp
                              : "Received ${question.timestamp} via WhatsApp",
                          style: GoogleFonts.publicSans(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right: action buttons
                  if (!isExpanded) ...[
                    if (isPending)
                      _buildAnswerButton(index, isDark)
                    else
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => controller.toggleExpansion(index),
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                  ] else ...[
                    // Clear button (outlined)
                    _buildClearButton(index, isDark),
                    const SizedBox(width: 10),
                    // Submit button (filled blue)
                    Obx(
                      () => _buildSubmitButton(index, isDark),
                    ),
                  ],
                ],
              ),
            ),

            // ── Submitted answer preview (not expanded, answered) ────────
            if (!isPending && !isExpanded && question.answerText != null)
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.successDark.withValues(alpha: 0.05)
                        : AppColors.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: isDark ? AppColors.successDark : AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.answerText!,
                          style: GoogleFonts.publicSans(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Expanded response area ───────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildExpandedContent(index, isDark, context),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      );
    });
  }

  // ── Status badge ─────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    final isPending = status == 'pending';
    final color = isPending ? const Color(0xFFE07B00) : AppColors.success;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          status.toUpperCase(),
          style: GoogleFonts.publicSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  // ── "Answer" button (collapsed pending) ─────────────────────────────────
  Widget _buildAnswerButton(int index, bool isDark) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: () => controller.toggleExpansion(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: GoogleFonts.publicSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text("Answer"),
      ),
    );
  }

  // ── Clear button ────────────────────────────────────────────────────────
  Widget _buildClearButton(int index, bool isDark) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: () => controller.clearAndDownload(index),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : const Color(0xFF8A8A8A),
          side: BorderSide(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFD1D1D1),
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: GoogleFonts.publicSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: const Text("Clear"),
      ),
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton(int index, bool isDark) {
    final isLoading = controller.isLoading.value;
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => controller.submitResponse(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0066E2),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF0066E2).withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          textStyle: GoogleFonts.publicSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text("Submit"),
      ),
    );
  }

  // ── Expanded area ─────────────────────────────────────────────────────────
  Widget _buildExpandedContent(int index, bool isDark, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Obx(() {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: Text editor ──────────────────────────────────
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildTextToolbar(isDark, context),
                        Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller.responseTextController,
                            maxLength: 2000,
                            maxLengthEnforcement: MaxLengthEnforcement.enforced,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: "Type your response here...",
                              hintStyle: GoogleFonts.publicSans(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white30
                                    : const Color(0xFF94A3B8),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(14),
                            ),
                            style: GoogleFonts.publicSans(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // ── Right: Attachments Panel ───────────────────────────
                Container(
                  width: 260,
                  height: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Attachments",
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF4C739A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      
                      // Dotted upload area
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: controller.pickResponseFiles,
                                child: DottedBorderWrapper(
                                  color: isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFCBD5E1),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.cloud_upload_outlined,
                                          color: Color(0xFF94A3B8),
                                          size: 24,
                                        ),
                                        const SizedBox(height: 6),
                                        RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            style: GoogleFonts.publicSans(
                                              fontSize: 12,
                                              color: isDark
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF64748B),
                                            ),
                                            children: const [
                                              TextSpan(text: "Drop files or\n"),
                                              TextSpan(
                                                text: "Browse",
                                                style: TextStyle(
                                                  color: Color(0xFF0066E2),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            
                            // File list (if any file is attached)
                            if (controller.selectedResponseFiles.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 50,
                                child: ListView.builder(
                                  itemCount: controller.selectedResponseFiles.length,
                                  physics: const ClampingScrollPhysics(),
                                  itemBuilder: (context, fIndex) {
                                    return _buildResponseFileItem(fIndex, isDark, index);
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Toolbar ───────────────────────────────────────────────────────────────
  Widget _buildTextToolbar(bool isDark, BuildContext context) {
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _toolbarTextIcon("B", isDark, isBold: true, onTap: () => _wrapSelection("*", "*")),
            _toolbarTextIcon("I", isDark, isItalic: true, onTap: () => _wrapSelection("_", "_")),
            _toolbarIcon(Icons.format_strikethrough, isDark, onTap: () => _wrapSelection("~", "~")),
            _toolbarTextIcon("<>", isDark, fontSize: 12, onTap: () => _wrapSelection("`", "`")),
            _toolbarDivider(isDark),
            _toolbarIcon(Icons.format_list_bulleted, isDark, onTap: _toggleBulletedList),
            _toolbarIcon(Icons.format_list_numbered, isDark, onTap: _toggleNumberedList),
            _toolbarDivider(isDark),
            _toolbarIcon(Icons.sentiment_satisfied_alt_outlined, isDark, onTap: () => _showEmojiPicker(context)),
            _toolbarTextIcon("{}", isDark, fontSize: 13, onTap: () => _showVariablePicker(context)),
          ],
        ),
      ),
    );
  }

  Widget _toolbarTextIcon(String text, bool isDark, {bool isBold = false, bool isItalic = false, double fontSize = 14, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            text,
            style: GoogleFonts.publicSans(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarIcon(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Icon(
            icon,
            size: 18,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _toolbarDivider(bool isDark) {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = controller.responseTextController.text;
    final selection = controller.responseTextController.selection;
    
    if (!selection.isValid) {
      final newText = text + prefix + suffix;
      controller.responseTextController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length - suffix.length),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    
    final newSelectedText = prefix + selectedText + suffix;
    final newText = text.replaceRange(start, end, newSelectedText);
    
    controller.responseTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start + prefix.length,
        extentOffset: start + prefix.length + selectedText.length,
      ),
    );
  }

  void _toggleBulletedList() {
    final text = controller.responseTextController.text;
    final selection = controller.responseTextController.selection;
    
    if (!selection.isValid) {
      final newText = "$text\n* ";
      controller.responseTextController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }
    
    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    
    final lines = selectedText.split('\n');
    final formattedLines = lines.map((line) {
      if (line.trim().startsWith('* ')) return line;
      return '* $line';
    }).join('\n');
    
    final newText = text.replaceRange(start, end, formattedLines);
    controller.responseTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + formattedLines.length,
      ),
    );
  }

  void _toggleNumberedList() {
    final text = controller.responseTextController.text;
    final selection = controller.responseTextController.selection;
    
    if (!selection.isValid) {
      final newText = "$text\n1. ";
      controller.responseTextController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }
    
    final start = selection.start;
    final end = selection.end;
    final selectedText = text.substring(start, end);
    
    final lines = selectedText.split('\n');
    int count = 1;
    final formattedLines = lines.map((line) {
      final trimmed = line.trim();
      if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) return line;
      final formatted = '$count. $line';
      count++;
      return formatted;
    }).join('\n');
    
    final newText = text.replaceRange(start, end, formattedLines);
    controller.responseTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + formattedLines.length,
      ),
    );
  }

  void _insertText(String insertion) {
    final text = controller.responseTextController.text;
    final selection = controller.responseTextController.selection;
    
    if (!selection.isValid) {
      final newText = text + insertion;
      controller.responseTextController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      return;
    }

    final start = selection.start;
    final end = selection.end;
    
    final newText = text.replaceRange(start, end, insertion);
    controller.responseTextController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insertion.length),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final emojis = [
      "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", 
      "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", 
      "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", 
      "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", 
      "😖", "😫", "😩", "🥺", "😢", "😭", "😤", "😠", "😡", "🤬",
      "👍", "👎", "👏", "🙌", "👐", "🤲", "🤝", "🙏", "✍️", "💅",
      "🧠", "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "🤎"
    ];
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          height: 380,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Emoji",
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Get.back(),
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: emojis.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          _insertText(emojis[index]);
                          Get.back();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(
                            emojis[index],
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVariablePicker(BuildContext context) {
    final variables = {
      "Client Name": "{client_name}",
      "Client Phone": "{client_phone}",
      "Bot Name": "{bot_name}",
      "Current Date": "{current_date}",
      "Current Time": "{current_time}",
    };
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Get.dialog(
      Dialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          height: 420,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Insert Dynamic Variable",
                      style: GoogleFonts.publicSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Get.back(),
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: variables.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.shade50,
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          title: Text(
                            entry.key,
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            entry.value,
                            style: GoogleFonts.publicSans(
                              color: const Color(0xFF0066E2),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            _insertText(entry.value);
                            Get.back();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── File item ─────────────────────────────────────────────────────────────
  Widget _buildResponseFileItem(int fIndex, bool isDark, int qIndex) {
    final file = controller.selectedResponseFiles[fIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.4)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(file.name),
            size: 16,
            color: _getFileColor(file.name),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              style: GoogleFonts.publicSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 16,
              color: Colors.redAccent,
            ),
            onPressed: () => controller.removeResponseFile(fIndex, qIndex),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'txt':
      case 'md':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(String fileName) {
    switch (fileName.split('.').last.toLowerCase()) {
      case 'pdf':
        return Colors.redAccent;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'txt':
      case 'md':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
