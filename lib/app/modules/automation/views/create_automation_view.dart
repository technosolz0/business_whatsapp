import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Node;
import 'package:mobx/mobx.dart' as mobx;
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import '../../../common widgets/custom_button.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../routes/app_pages.dart';
import '../controllers/automation_controller.dart';
import '../models/automation_model.dart';

class CreateAutomationView extends GetView<AutomationController> {
  const CreateAutomationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Get.isRegistered<NavigationController>()) {
          final nav = Get.find<NavigationController>();
          nav.currentRoute.value = Routes.AUTOMATION;
          nav.selectedIndex.value = 12;
          nav.routeTrigger.value++;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Automation Builder'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to automations',
            enableFeedback: false,
            onPressed: () {
              if (Get.isRegistered<NavigationController>()) {
                final nav = Get.find<NavigationController>();
                nav.currentRoute.value = Routes.AUTOMATION;
                nav.selectedIndex.value = 12;
                nav.routeTrigger.value++;
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset Flow',
              onPressed: () {
                controller.resetFlow();
              },
            ),
            IconButton(
              icon: const Icon(Icons.light_mode),
              tooltip: 'Light Theme',
              onPressed: () => controller.setTheme(NodeFlowTheme.light),
            ),
            IconButton(
              icon: const Icon(Icons.dark_mode),
              tooltip: 'Dark Theme',
              onPressed: () => controller.setTheme(NodeFlowTheme.dark),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final isEditing = controller.editingFlowId.value != null;
              final canDeploy = controller.canDeploy;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 16,
                ),
                child: CustomButton(
                  onPressed: canDeploy
                      ? () {
                          controller.deployFlow();
                        }
                      : null,
                  icon: isEditing ? Icons.save_outlined : Icons.cloud_upload,
                  label: isEditing ? 'Update' : 'Deploy',
                  type: isEditing ? ButtonType.success : ButtonType.primary,
                  isLoading: controller.isLoading.value,
                  isDisabled: !canDeploy,
                ),
              );
            }),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          ),
          child: Column(
            children: [
              // Flow Name Input
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Flow Name',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(
                        () => TextFormField(
                          controller: controller.flowNameController,
                          maxLength: 100,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          validator: (value) {
                            if (value != null && value.length > 100) {
                              return "Max 100 characters allowed";
                            }
                            return null;
                          },
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter a name for this automation...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white30 : Colors.black38,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                            ),
                            errorText: controller.flowNameError.value.isNotEmpty
                                ? controller.flowNameError.value
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) {
                            if (controller.flowNameError.value.isNotEmpty) {
                              controller.flowNameError.value = '';
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '* Required',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Toolbar for adding common nodes
              _buildToolbar(context, isDark),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.05,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Obx(
                      () => RepaintBoundary(
                        child: NodeFlowEditor<AutomationNodeData, void>(
                          key: ValueKey(
                            'automation_flow_${controller.flowKey.value}',
                          ),
                          controller: controller.nodeFlowController,
                          theme: controller.currentTheme.value,
                          nodeBuilder: (context, node) =>
                              _buildCustomNode(node, isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Obx(
            () => controller.hasTriggerNode.value
                ? const SizedBox.shrink()
                : _ToolbarItem(
                    icon: Icons.bolt,
                    label: 'Trigger',
                    color: Colors.amber,
                    onPressed: () => _addNode('trigger'),
                  ),
          ),
          Obx(
            () => controller.hasTriggerNode.value
                ? const SizedBox.shrink()
                : const SizedBox(width: 16),
          ),
          _ToolbarItem(
            icon: Icons.text_fields,
            label: 'Message',
            color: Colors.teal,
            onPressed: () => _addNode('text_field'),
          ),
          const SizedBox(width: 16),
          _ToolbarItem(
            icon: Icons.stop_circle_outlined,
            label: 'Stop',
            color: Colors.red,
            onPressed: () => _addNode('stop'),
          ),
          const SizedBox(width: 16),
          const Spacer(),
          Text(
            'Tip: Drag from ports to connect nodes',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _addNode(String type) {
    final id = '$type-${DateTime.now().millisecondsSinceEpoch}';
    late final Node<AutomationNodeData> node;

    switch (type) {
      case 'trigger':
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(50, 50),
          size: const Size(250, 240),
          data: AutomationNodeData(
            label: 'New Trigger',
            hint: 'Configure how this flow starts',
          ),
          ports: [
            Port(
              id: 'out',
              name: 'Success',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 120),
            ),
          ],
        );
        break;
      case 'condition':
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(50, 50),
          size: const Size(250, 200),
          data: AutomationNodeData(
            label: 'New Condition',
            hint: 'Decision logic for the flow',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'Input',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 100),
            ),
            Port(
              id: 'true',
              name: 'True',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 40),
            ),
            Port(
              id: 'false',
              name: 'False',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 100),
            ),
          ],
        );
        break;
      case 'text_field':
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(50, 50),
          size: const Size(250, 220),
          data: AutomationNodeData(
            label: 'Input Field',
            hint: 'User editable content',
            content: 'Thanks for reaching out!',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'In',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 110),
            ),
            Port(
              id: 'out',
              name: 'Out',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 110),
            ),
          ],
        );
        break;
      case 'question':
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(50, 50),
          size: const Size(250, 200),
          data: AutomationNodeData(
            label: 'New Question',
            hint: 'Ask user for input',
            content: 'Your question here...',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'In',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 100),
            ),
            Port(
              id: 'out',
              name: 'Response',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 100),
            ),
          ],
        );
        break;
      case 'stop':
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(50, 50),
          size: const Size(250, 120),
          data: AutomationNodeData(
            label: 'Stop Flow',
            hint: 'Terminates the automation',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'End',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 60),
            ),
          ],
        );
        break;
      default:
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(50, 50),
          size: const Size(250, 150),
          data: AutomationNodeData(
            label: 'New Action',
            hint: 'Perform a task in this step',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'Exec',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 75),
            ),
          ],
        );
    }

    controller.nodeFlowController.addNode(node);
    controller.updateFlowStatus();
  }

  Widget _buildCustomNode(Node<AutomationNodeData> node, bool isDark) {
    final color = _getNodeColor(node.type);
    final icon = _getNodeIcon(node.type);
    final data = node.data;

    return Container(
      width: node.size.value.width,
      height: node.size.value.height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  node.type.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (node.type != 'trigger')
                  GestureDetector(
                    onTap: () {
                      controller.nodeFlowController.removeNode(node.id);
                      controller.updateFlowStatus();
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.more_horiz,
                    size: 16,
                    color: color.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.hint,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (node.type == 'trigger') ...[
                    const SizedBox(height: 12),
                    Text(
                      'KEYWORDS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black45,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: data.keywords.map((kw) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  kw,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => data.keywords.remove(kw),
                                  child: Icon(
                                    Icons.close,
                                    size: 10,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _KeywordInput(
                      color: color,
                      isDark: isDark,
                      onAdd: (value) {
                        if (value.trim().isNotEmpty) {
                          data.keywords.add(value.trim());
                        }
                      },
                    ),
                  ],
                  if (node.type == 'text_field' || node.type == 'question') ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: data.content,
                      maxLength: 500,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      validator: (value) {
                        if (value != null && value.length > 500) {
                          return "Max 500 characters allowed";
                        }
                        return null;
                      },
                      maxLines: node.type == 'question' ? 3 : 2,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: node.type == 'question'
                            ? 'Ask a question...'
                            : 'Enter message text to send...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey[50],
                      ),
                      onChanged: (val) {
                        data.content = val;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Footer / Status
          Container(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  size: 12,
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.1),
                ),
                const SizedBox(width: 4),
                Text(
                  'Active Step',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onPanUpdate: (details) {
                    final newWidth = math.max(
                      200.0,
                      node.size.value.width + details.delta.dx,
                    );
                    final newHeight = math.max(
                      120.0,
                      node.size.value.height + details.delta.dy,
                    );
                    mobx.runInAction(() {
                      node.size.value = Size(newWidth, newHeight);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: Icon(
                      Icons.open_in_full,
                      size: 16,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getNodeColor(String type) {
    switch (type) {
      case 'trigger':
        return Colors.amber;
      case 'condition':
        return Colors.purple;
      case 'action':
        return Colors.blue;
      case 'text_field':
        return Colors.teal;
      case 'question':
        return Colors.orange;
      case 'stop':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNodeIcon(String type) {
    switch (type) {
      case 'trigger':
        return Icons.bolt;
      case 'condition':
        return Icons.alt_route;
      case 'action':
        return Icons.play_arrow;
      case 'text_field':
        return Icons.text_fields;
      case 'question':
        return Icons.help_outline;
      case 'stop':
        return Icons.stop_circle_outlined;
      default:
        return Icons.circle;
    }
  }
}

class _ToolbarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeywordInput extends StatefulWidget {
  final Color color;
  final bool isDark;
  final Function(String) onAdd;

  const _KeywordInput({
    required this.color,
    required this.isDark,
    required this.onAdd,
  });

  @override
  State<_KeywordInput> createState() => _KeywordInputState();
}

class _KeywordInputState extends State<_KeywordInput> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onAdd(_controller.text.trim());
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      maxLength: 30,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      decoration: InputDecoration(
        counterText: "",
        hintText: 'Add keyword...',
        hintStyle: TextStyle(
          fontSize: 11,
          color: widget.isDark ? Colors.white24 : Colors.black26,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: Icon(Icons.add, size: 14, color: widget.color),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _submit,
          splashRadius: 16,
        ),
      ),
      style: TextStyle(
        fontSize: 12,
        color: widget.isDark ? Colors.white : Colors.black87,
      ),
      onSubmitted: (_) => _submit(),
    );
  }
}
