import 'dart:math' as math;
import 'package:business_whatsapp/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:mobx/mobx.dart' as mobx;
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import '../../../common widgets/custom_button.dart';
import '../controllers/automation_controller.dart';
import '../models/automation_model.dart';

class CreateAutomationView extends GetView<AutomationController> {
  const CreateAutomationView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Obx(() {
          final isEditing = controller.editingFlowId.value != null;
          return Text(
            isEditing ? 'Edit Automation Flow' : 'Create Automation Flow',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          );
        }),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to automations',
          onPressed: () {
            if (Get.key.currentState?.canPop() == true) {
              Get.back();
            } else {
              Get.offNamed(Routes.AUTOMATION);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Flow',
            onPressed: () => controller.resetFlow(),
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: CustomButton(
                onPressed: canDeploy ? () => controller.deployFlow() : null,
                icon: isEditing ? Icons.save_outlined : Icons.cloud_upload,
                label: isEditing ? 'Update Flow' : 'Deploy Flow',
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
          color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
        ),
        child: Column(
          children: [
            // 1. Flow Name & Validation Bar
            _buildFlowNameHeader(isDark),

            // 2. Toolbar for adding all node types
            _buildToolbar(context, isDark),

            // 3. Node Flow Canvas Editor
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
                  child: Obx(() {
                    return NodeFlowEditor<AutomationNodeData, void>(
                      controller: controller.nodeFlowController,
                      theme: controller.currentTheme.value,
                      nodeBuilder: (context, node) =>
                          _buildCustomNode(node, isDark),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowNameHeader(bool isDark) {
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
          const Text(
            'Flow Name:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(
              () => TextField(
                controller: controller.flowNameController,
                maxLength: 100,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText:
                      'e.g., Welcome Bot, Support Qualifier, Lead Router...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white30 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: controller.flowNameError.value.isNotEmpty
                          ? Colors.red
                          : (isDark ? Colors.white10 : Colors.black12),
                    ),
                  ),
                  errorText: controller.flowNameError.value.isNotEmpty
                      ? controller.flowNameError.value
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Deployment constraints indicator
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: controller.canDeploy
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: controller.canDeploy
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    controller.canDeploy
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 14,
                    color: controller.canDeploy ? Colors.green : Colors.amber,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    controller.canDeploy
                        ? 'Valid Flow'
                        : 'Requires Trigger & Stop node',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: controller.canDeploy ? Colors.green : Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
          _ToolbarItem(
            icon: Icons.bolt,
            label: 'Trigger',
            color: Colors.amber,
            onPressed: () => _addNode('trigger'),
          ),
          const SizedBox(width: 12),
          _ToolbarItem(
            icon: Icons.alt_route,
            label: 'Condition',
            color: Colors.purple,
            onPressed: () => _addNode('condition'),
          ),
          const SizedBox(width: 12),
          _ToolbarItem(
            icon: Icons.play_arrow,
            label: 'Action',
            color: Colors.blue,
            onPressed: () => _addNode('action'),
          ),
          const SizedBox(width: 12),
          _ToolbarItem(
            icon: Icons.text_fields,
            label: 'Message',
            color: Colors.teal,
            onPressed: () => _addNode('text_field'),
          ),
          const SizedBox(width: 12),
          _ToolbarItem(
            icon: Icons.help_outline,
            label: 'Question',
            color: Colors.orange,
            onPressed: () => _addNode('question'),
          ),
          const SizedBox(width: 12),
          _ToolbarItem(
            icon: Icons.stop_circle_outlined,
            label: 'Stop',
            color: Colors.red,
            onPressed: () => _addNode('stop'),
          ),
          const Spacer(),
          Text(
            'Tip: Connect ports to build decision paths',
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
          position: const Offset(60, 60),
          size: const Size(270, 240),
          data: AutomationNodeData(
            label: 'Keyword Trigger',
            hint: 'Fires when user sends matching keywords',
            keywords: ['hello', 'hi'],
          ),
          ports: [
            Port(
              id: 'out',
              name: 'Trigger',
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
          position: const Offset(60, 60),
          size: const Size(280, 260),
          data: AutomationNodeData(
            label: 'Condition Check',
            hint: 'Branches based on user response',
            operator: 'contains',
            conditionValue: 'support',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'Input',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 130),
            ),
            Port(
              id: 'true',
              name: 'True',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 60),
            ),
            Port(
              id: 'false',
              name: 'False',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 180),
            ),
          ],
        );
        break;

      case 'action':
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(60, 60),
          size: const Size(270, 220),
          data: AutomationNodeData(
            label: 'Perform Action',
            hint: 'Assign department or set contact tag',
            actionType: 'assign_dept',
            actionValue: 'Support',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'Exec',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 110),
            ),
            Port(
              id: 'out',
              name: 'Next',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 110),
            ),
          ],
        );
        break;

      case 'text_field':
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(60, 60),
          size: const Size(270, 220),
          data: AutomationNodeData(
            label: 'Send Message',
            hint: 'Auto-reply sent to contact',
            content: 'Hello! Thank you for contacting us.',
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
          position: const Offset(60, 60),
          size: const Size(280, 250),
          data: AutomationNodeData(
            label: 'Question / Menu',
            hint: 'Asks a question and waits for answer',
            content: 'How can we help you today?\n1. Sales\n2. Support',
            options: {'1': '', '2': ''},
          ),
          ports: [
            Port(
              id: 'in',
              name: 'In',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 120),
            ),
            Port(
              id: 'out',
              name: 'Next',
              type: PortType.output,
              position: PortPosition.right,
              offset: const Offset(0, 120),
            ),
          ],
        );
        break;

      case 'stop':
        node = Node<AutomationNodeData>(
          id: id,
          type: type,
          position: const Offset(60, 60),
          size: const Size(250, 130),
          data: AutomationNodeData(
            label: 'Stop Flow',
            hint: 'Terminates this automation session',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'End',
              type: PortType.input,
              position: PortPosition.left,
              offset: const Offset(0, 65),
            ),
          ],
        );
        break;

      default:
        return;
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
        border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
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
                  _getNodeTitle(node.type),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                // Delete node button
                if (node.type != 'trigger')
                  GestureDetector(
                    onTap: () {
                      controller.nodeFlowController.removeNode(node.id);
                      controller.updateFlowStatus();
                    },
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),

          // 2. Node Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.hint,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  // A. TRIGGER: Keywords chip list
                  if (node.type == 'trigger') ...[
                    const SizedBox(height: 10),
                    Text(
                      'TRIGGER KEYWORDS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.black45,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(
                      () => Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: data.keywords.map((kw) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: color.withValues(alpha: 0.3),
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
                    const SizedBox(height: 8),
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

                  // B. CONDITION: Operator and Value
                  if (node.type == 'condition') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          'If message ',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        DropdownButton<String>(
                          value: data.operator,
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'contains',
                              child: Text('contains'),
                            ),
                            DropdownMenuItem(
                              value: 'equals',
                              child: Text('equals'),
                            ),
                            DropdownMenuItem(
                              value: 'starts_with',
                              child: Text('starts with'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              data.operator = val;
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: data.conditionValue,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Keyword or phrase...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey[50],
                      ),
                      onChanged: (val) {
                        data.conditionValue = val;
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'True ➜',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const Text(
                          'False ➜',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // C. ACTION: Action Type & Value
                  if (node.type == 'action') ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: data.actionType,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Action Type',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'assign_dept',
                          child: Text('Assign Department'),
                        ),
                        DropdownMenuItem(
                          value: 'add_tag',
                          child: Text('Add Tag to User'),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('Custom Event'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          data.actionType = val;
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: data.actionValue,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Value (e.g. Support, VIP)...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey[50],
                      ),
                      onChanged: (val) {
                        data.actionValue = val;
                      },
                    ),
                  ],

                  // D. MESSAGE & QUESTION: Content text area
                  if (node.type == 'text_field' || node.type == 'question') ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      initialValue: data.content,
                      maxLines: node.type == 'question' ? 3 : 2,
                      maxLength: 500,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: node.type == 'question'
                            ? 'Ask question / list options...'
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
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.grey[50],
                      ),
                      onChanged: (val) {
                        data.content = val;
                      },
                    ),
                  ],

                  // E. STOP node
                  if (node.type == 'stop') ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, size: 14, color: Colors.red),
                          SizedBox(width: 6),
                          Text(
                            'Closes session on finish',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 3. Footer / Resize Handle
          Container(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 4),
                Text(
                  node.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onPanUpdate: (details) {
                    final newWidth = math.max(
                      240.0,
                      node.size.value.width + details.delta.dx,
                    );
                    final newHeight = math.max(
                      130.0,
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
                      size: 14,
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

  String _getNodeTitle(String type) {
    switch (type) {
      case 'trigger':
        return 'TRIGGER';
      case 'condition':
        return 'CONDITION';
      case 'action':
        return 'ACTION';
      case 'text_field':
        return 'MESSAGE';
      case 'question':
        return 'QUESTION / MENU';
      case 'stop':
        return 'STOP';
      default:
        return type.toUpperCase();
    }
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
    final val = _controller.text.trim();
    if (val.isNotEmpty) {
      widget.onAdd(val);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: TextStyle(
              fontSize: 11,
              color: widget.isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Add keyword + Enter',
              hintStyle: TextStyle(
                fontSize: 11,
                color: widget.isDark ? Colors.white30 : Colors.black38,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: widget.color.withValues(alpha: 0.3),
                ),
              ),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.add, size: 16, color: widget.color),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: _submit,
        ),
      ],
    );
  }
}
