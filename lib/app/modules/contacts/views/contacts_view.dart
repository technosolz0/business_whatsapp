import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import 'package:intl/intl.dart';
import '../../../common widgets/standard_page_layout.dart';
import '../../../common widgets/custom_button.dart';
import '../../../common widgets/contact_status_chip.dart';
import '../../../common widgets/custom_dropdown.dart';
import '../../../common widgets/no_data_found.dart';
import '../../../common widgets/common_alert_dialog_delete.dart';
import '../../../common widgets/common_pagination.dart';
import '../../../core/theme/app_colors.dart';
import '../../../Utilities/responsive.dart';
import '../../../Utilities/subscription_guard.dart';
import '../../../data/models/contact_model.dart';
import '../controllers/contacts_controller.dart';
import '../widgets/add_contact_form_widget.dart';
import '../widgets/contact_tags_widget.dart';

class ContactsView extends GetView<ContactsController> {
  const ContactsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isAddingContact.value) {
        return StandardPageLayout(
          title: controller.isEditingContact.value
              ? 'Edit Contact'
              : 'Add New Contact',
          subtitle: 'Store and manage your customer information.',
          showBackButton: true,
          onBack: controller.cancelAddContact,
          isContentScrollable: true,
          child: const AddContactFormWidget(),
        );
      }

      return StandardPageLayout(
        title: 'Contacts',
        subtitle: 'Manage your WhatsApp contacts, lists, and segments.',
        headerActions: [
          SizedBox(
            width: 140,
            child: CustomDropdown<String>(
              label: null,
              hint: "Import",
              value: null,
              items: const [
                DropdownMenuItem(value: "download", child: Text("Sample CSV")),
                DropdownMenuItem(value: "upload", child: Text("Upload Doc")),
              ],
              actions: {
                "upload": () => controller.importContacts(),
                "download": () => controller.downloadSampleCsv(),
              },
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => CustomButton(
              label: 'Add Contact',
              icon: Icons.add,
              onPressed: () {
                controller.clearSelection();
                controller.showAddContactForm();
              },
              isDisabled: !SubscriptionGuard.canEdit(),
              type: ButtonType.primary,
            ),
          ),
        ],
        toolbarWidgets: [
          Expanded(flex: 3, child: _buildSearchBar()),
          const SizedBox(width: 12),
          SizedBox(width: 200, child: _buildFilterDropdown()),
        ],
        child: Row(
          children: [
            Expanded(child: _buildContactsTable(context)),
            if (!Responsive.isMobile(context) && !Responsive.isTablet(context))
              Obx(
                () => controller.selectedContact.value != null
                    ? _buildDetailsPanel(context)
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return TextField(
      controller: controller.searchController,
      onChanged: controller.updateSearchQuery,
      decoration: InputDecoration(
        hintText: 'Search by name or phone number or email...',
        hintStyle: TextStyle(
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          size: 20,
        ),
        filled: true,
        fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Obx(
      () => SizedBox(
        // <-- ensures proper width constraints
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButtonFormField<String>(
            menuMaxHeight: 300, // 👈 enables scroll if items exceed height
            initialValue: controller.selectedTag.value == 'All'
                ? null
                : controller.selectedTag.value,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
            dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            hint: Text(
              'Filter by Tag',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.gray400 : Colors.black,
              ),
            ),

            items: [
              const DropdownMenuItem(value: 'All', child: Text("All")),
              ...controller.allTags
                  .where((tag) => tag != 'All')
                  .map(
                    (tag) => DropdownMenuItem(
                      value: tag,
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ),
            ],

            onChanged: (value) {
              controller.updateTagFilter(value ?? 'All');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContactsTable(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const TableShimmer(rows: 10, columns: 6);
        }
        if (controller.paginatedContacts.isEmpty &&
            controller.searchQuery.isNotEmpty) {
          return NoDataFound(
            icon: Icons.grid_view_outlined,
            label: 'No Contact Found',
            isDark: isDark,
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
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
          child: Column(
            children: [
              // Table Header
              if (!isMobile) _buildTableHeader(isDark),

              // Table Body
              Expanded(
                child: Obx(
                  () => ListView.separated(
                    itemCount: controller.paginatedContacts.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      final contact = controller.paginatedContacts[index];
                      return _buildTableRow(contact, context);
                    },
                  ),
                ),
              ),

              // Pagination Controls
              _buildPaginationControls(isDark),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTableHeader(bool isDark) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          // SizedBox(
          //   width: 40,
          //   child: Checkbox(
          //     value: false,
          //     onChanged: (value) {},
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(4),
          //     ),
          //     side: const BorderSide(
          //       color: Colors.grey, // Light grey border
          //       width: 1.6,
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'NAME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PHONE NUMBER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'TAGS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'STATUS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'LAST CONTACTED',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(ContactModel contact, BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        // Always select contact first for immediate visual feedback
        controller.selectContact(contact);

        // Then show bottom sheet on mobile/tablet
        if (isMobile || Responsive.isTablet(context)) {
          _showContactDetailsBottomSheet(context, contact);
        }
      },
      child: Obx(() {
        final selected = controller.selectedContact.value;
        final isSelected = selected != null && selected.id == contact.id;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: 16,
          ),
          color: isSelected
              ? isDark
                    ? Colors.black.withValues(alpha: 0.5)
                    : const Color.fromARGB(255, 243, 247, 252)
              : Colors.transparent,
          child: isMobile
              ? _buildMobileRow(contact)
              : _buildDesktopRow(contact),
        );
      }),
    );
  }

  void _showContactDetailsBottomSheet(
    BuildContext context,
    ContactModel contact,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contact Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a1a1a),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[200]),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: _buildContactDetailsContent(contact),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String contactDisplayName(ContactModel c) {
    String name = [
      c.fName,
      c.lName,
    ].where((e) => e!.trim().isNotEmpty).join(" ");

    return name.isEmpty ? "Unknown" : name;
  }

  Widget _buildMobileRow(ContactModel contact) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Row(
      children: [
        _buildAvatar(
          "${contact.fName} ${contact.lName}",
          contact.profilePhoto, // Add this parameter
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contactDisplayName(contact),

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${contact.countryCallingCode} ${contact.phoneNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.gray400 : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              StatusChip(
                label: contact.status == 1
                    ? 'Opted-In'
                    : contact.status == 0
                    ? 'Opted-Out'
                    : 'None',
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Action buttons
        Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                onPressed: SubscriptionGuard.canEdit()
                    ? () {
                        controller.showEditContactForm(contact);
                      }
                    : null,
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: AppColors.error,
                ),
                onPressed: SubscriptionGuard.canEdit()
                    ? () {
                        _showDeleteConfirmation(contact);
                      }
                    : null,
                tooltip: 'Delete',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(ContactModel contact) {
    Get.dialog(
      CommonAlertDialogDelete(
        title: 'Delete Contact',
        content:
            'Are you sure you want to delete ${contact.fName} ${contact.lName}? This action cannot be undone.',
        onConfirm: () async {
          await controller.deleteContact(contact.id);
        },
      ),
    );
  }

  Widget _buildDesktopRow(ContactModel contact) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Row(
      children: [
        // SizedBox(
        //   width: 40,
        //   child: Checkbox(
        //     value: false,
        //     onChanged: (value) {},
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(4),
        //     ),
        //     side: const BorderSide(color: Colors.grey, width: 1.6),
        //   ),
        // ),
        // const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              _buildAvatar(
                "${contact.fName} ${contact.lName}",
                contact.profilePhoto, // Add this parameter
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  contactDisplayName(contact),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${contact.countryCallingCode} ${contact.phoneNumber}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.gray400 : Colors.grey[700],
            ),
          ),
        ),
        Expanded(flex: 2, child: ContactTagsWidget(tags: contact.tags)),
        Expanded(
          flex: 1,
          child: StatusChip(
            label: contact.status == 1
                ? 'Opted-In'
                : contact.status == 0
                ? 'Opted-Out'
                : 'None',
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            contact.lastContacted != null
                ? DateFormat('yyyy-MM-dd').format(contact.lastContacted!)
                : 'Never',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          flex: 1,
          child: Obx(
            () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    onPressed: SubscriptionGuard.canEdit()
                        ? () {
                            controller.showEditContactForm(contact);
                          }
                        : null,
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Flexible(
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: SubscriptionGuard.canEdit()
                        ? () {
                            _showDeleteConfirmation(contact);
                          }
                        : null,
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(String? name, String? profilePhotoUrl) {
    // If null or empty → use "UK"
    final safeName = (name ?? "").trim();
    final initials = safeName.isEmpty
        ? "UK"
        : safeName
              .split(" ")
              .where((n) => n.trim().isNotEmpty)
              .map((n) => n.trim()[0])
              .take(2)
              .join()
              .toUpperCase();

    // Show profile photo if available
    if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          // color: AppColors.primary, // Background color while loading
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            profilePhotoUrl,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Show initials if image fails to load
              return Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              // Show initials while loading
              return Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Show initials avatar if no photo
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildContactDetailsContent(ContactModel contact) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and basic info
        Center(
          child: Column(
            children: [
              Responsive.isMobile(Get.context!)
                  ? Column(
                      children: [
                        _buildLargeAvatar("${contact.fName} ${contact.lName}"),
                        const SizedBox(height: 16),
                        Text(
                          "${contact.fName} ${contact.lName}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Color(0xFF1a1a1a),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${contact.countryCallingCode} ${contact.phoneNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildLargeAvatar("${contact.fName} ${contact.lName}"),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${contact.fName} ${contact.lName}",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : Color(0xFF1a1a1a),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${contact.countryCallingCode} ${contact.phoneNumber}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey
                                      : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Details Section
        _buildSectionTitle('DETAILS'),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Email',
          contact.email != null && contact.email!.isNotEmpty
              ? contact.email!
              : 'Not provided',
        ),
        _buildDetailRow(
          'Company',
          contact.company != null && contact.company!.isNotEmpty
              ? contact.company!
              : 'Not provided',
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            StatusChip(
              label: contact.status == 1
                  ? 'Opted-In'
                  : contact.status == 0
                  ? 'Opted-Out'
                  : 'None',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tags & Lists Section
        _buildSectionTitle('TAGS & LISTS'),
        const SizedBox(height: 12),
        ContactTagsWidget(tags: contact.tags),
        const SizedBox(height: 24),

        // Notes Section
        if (contact.notes != null && contact.notes!.isNotEmpty) ...[
          _buildSectionTitle('NOTES'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark.withValues(alpha: 0.5)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey[200]!,
              ),
            ),
            child: Text(
              contact.notes!,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.gray300 : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildDetailsPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final contact = controller.selectedContact.value;
      if (contact == null) return const SizedBox.shrink();

      return Container(
        width: 380,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          border: Border(
            left: BorderSide(
              color: isDark ? AppColors.borderDark : Colors.grey[200]!,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Contact Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF1a1a1a),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: controller.clearSelection,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildContactDetailsContent(contact),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLargeAvatar(String name) {
    final initials = name.trim().isEmpty
        ? 'UK'
        : name
              .split(' ')
              .where((n) => n.trim().isNotEmpty)
              .map((n) => n.trim()[0])
              .take(2)
              .join()
              .toUpperCase();
    final colors = [
      const Color(0xFF93C5FD),
      const Color(0xFFA78BFA),
      const Color(0xFFFBBF24),
      const Color(0xFF34D399),
      const Color(0xFFF87171),
    ];
    final color = colors[initials.length % colors.length];

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6b7280),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.gray400 : Colors.grey[600],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(bool isDark) {
    return Obx(
      () => CommonPagination(
        currentPage: controller.currentPage.value,
        totalPages: controller.totalPages,
        showingText:
            'Showing ${controller.startItem} to ${controller.endItem} of ${controller.filteredContacts.length} results',
        onPageChanged: (page) {
          if (page > controller.currentPage.value) {
            controller.goToNextPage();
          } else if (page < controller.currentPage.value) {
            controller.goToPreviousPage();
          }
        },
      ),
    );
  }
}
