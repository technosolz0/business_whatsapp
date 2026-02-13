import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:adminpanel/app/common%20widgets/shimmer_widgets.dart';
import '../../../common widgets/custom_button.dart';
import '../../../common widgets/common_textfield.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utilities/responsive.dart';
import '../controllers/clients_controller.dart';
import 'widgets/clients_table.dart';

class ClientsListView extends GetView<ClientsController> {
  const ClientsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, isDark),
              const SizedBox(height: 24),

              // Search Bar & Actions
              _buildSearchSection(context, isMobile),
              const SizedBox(height: 20),

              // Table
              Obx(() {
                if (controller.isLoading.value) {
                  return const Expanded(
                    child: TableShimmer(rows: 10, columns: 5),
                  );
                }

                return ClientsTable(
                  clients: controller.filteredClients,
                  onEdit: controller.navigateToEditClient,
                  onDelete: (id, name) => controller.deleteClient(id, name),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final isMobile = Responsive.isMobile(context);

    // If mobile, we stack title and button below if needed, or keep row
    // Standard pattern uses Row for desktop, Column for mobile if tight,
    // but typically Row with spacer is fine or Column.
    // Let's use Column for mobile to ensure space.

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clients',
                      style: Theme.of(
                        context,
                      ).textTheme.displayLarge?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your client accounts',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _buildAddButton(context),
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clients', style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Manage your client accounts and configurations.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildSearchSection(BuildContext context, bool isMobile) {
    if (isMobile) {
      return CommonTextfield(
        controller: controller.searchController,
        hintText: 'Search clients...',
        prefixIcon: const Icon(Icons.search, size: 20),
        onChanged: controller.updateSearchQuery,
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CommonTextfield(
            controller: controller.searchController,
            hintText: 'Search by name or phone...',
            prefixIcon: const Icon(Icons.search, size: 20),
            onChanged: controller.updateSearchQuery,
          ),
        ),
        const Spacer(flex: 3), // Keep search compact on desktop
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return CustomButton(
      label: 'Add Client',
      icon: Icons.add,
      onPressed: controller.navigateToAddClient,
      type: ButtonType.primary,
      width: Responsive.isMobile(context) ? null : 160,
    );
  }
}
