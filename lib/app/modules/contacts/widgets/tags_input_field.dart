import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/tag_model.dart';
import '../../../data/services/tag_service.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';

class TagsInputField extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  final String? label;
  final bool required;

  const TagsInputField({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    this.label,
    this.required = false,
  });

  @override
  State<TagsInputField> createState() => _TagsInputFieldState();
}

class _TagsInputFieldState extends State<TagsInputField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final TagService _tagService = TagService();

  List<TagModel> _allTags = [];
  List<TagModel> _filteredTags = [];
  bool _isLoading = false;
  bool _showList = false;

  @override
  void initState() {
    super.initState();
    _loadTags();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showList = true;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // 🔥 Real-time Firestore tag stream
  Future<void> _loadTags() async {
    setState(() => _isLoading = true);
    _tagService.getTagsStream().listen((tags) {
      if (mounted) {
        setState(() {
          _allTags = tags;
          _filterTags(_searchController.text);
          _isLoading = false;
        });
      }
    });
  }

  void _filterTags(String query) {
    if (query.isEmpty) {
      _filteredTags = _allTags
          .where((tag) => !widget.selectedTags.contains(tag.name))
          .toList();
    } else {
      _filteredTags = _allTags
          .where(
            (tag) =>
                tag.name.toLowerCase().contains(query.toLowerCase()) &&
                !widget.selectedTags.contains(tag.name),
          )
          .toList();
    }
    setState(() {});
  }

  // ⭐ Ensure tags are always lowercase
  void _addTag(String tagName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lowerTag = tagName.toLowerCase(); // <-- 🔥 TAG LOWERCASE

    if (widget.selectedTags.contains(lowerTag)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tag "$lowerTag" is already added'),
          backgroundColor: isDark ? Colors.grey : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Add tag in lowercase
    final updated = [...widget.selectedTags, lowerTag];
    widget.onTagsChanged(updated);

    _searchController.clear();
    _filterTags('');
    _showList = false;
    FocusScope.of(context).unfocus();
  }

  void _removeTag(String tagName) {
    final updated = widget.selectedTags.where((t) => t != tagName).toList();
    widget.onTagsChanged(updated);

    _filterTags(_searchController.text); // Refresh list
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Row(
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              if (widget.required)
                const Text(' *', style: TextStyle(color: AppColors.error)),
            ],
          ),

        if (widget.label != null) const SizedBox(height: 8),

        // ⭐ Chips + Input Field ⭐
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.gray800.withValues(alpha: 0.5)
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey[300]!,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Chips
              ...widget.selectedTags.map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _removeTag(tag),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Input field
              SizedBox(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    _showList = true;
                    _filterTags(value.toLowerCase()); // <-- lowercase matching
                  },
                  decoration: InputDecoration(
                    hintText: "Search or add tags...",
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.gray500 : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ⭐ Dropdown list ⭐
        if (_showList && _searchController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 6),

          LayoutBuilder(
            builder: (context, constraints) {
              double itemHeight = 48;
              double listHeight = _filteredTags.length * itemHeight;

              final query = _searchController.text.trim().toLowerCase();
              final exactExists = _filteredTags.any(
                (t) => t.name.toLowerCase() == query,
              );

              if (query.isNotEmpty && !exactExists) {
                listHeight += itemHeight;
              }

              listHeight = listHeight.clamp(0, 200);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: listHeight,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : Colors.grey[300]!,
                  ),
                ),
                child: _isLoading
                    ? const Center(child: CircleShimmer(size: 20))
                    : _buildListContent(isDark),
              );
            },
          ),
        ],
      ],
    );
  }

  // ⭐ List Content
  Widget _buildListContent(bool isDark) {
    final query = _searchController.text.trim().toLowerCase();

    final exactExists = _filteredTags.any((t) => t.name.toLowerCase() == query);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        ..._filteredTags.map(
          (tag) => InkWell(
            onTap: () => _addTag(tag.name.toLowerCase()), // <-- lowerTag
            child: Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                tag.name,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textPrimaryDark : Colors.black87,
                ),
              ),
            ),
          ),
        ),

        // Add new tag option
        if (query.isNotEmpty && !exactExists)
          InkWell(
            onTap: () => _addTag(query.toLowerCase()), // <-- lowerCase
            child: Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Text(
                'Add new tag "$query"',
                style: const TextStyle(color: AppColors.primary, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }
}
