import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import '../controllers/automation_controller.dart';

class AutomationView extends GetView<AutomationController> {
  const AutomationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark =
          controller.currentTheme.value.backgroundColor.computeLuminance() <
          0.5;

      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Automation Builder'),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset Flow',
              onPressed: () {
                controller.onInit();
              },
            ),
            IconButton(
              icon: const Icon(Icons.light_mode),
              onPressed: () => controller.setTheme(NodeFlowTheme.light),
              tooltip: 'Light Theme',
            ),
            IconButton(
              icon: const Icon(Icons.dark_mode),
              onPressed: () => controller.setTheme(NodeFlowTheme.dark),
              tooltip: 'Dark Theme',
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () {
                  controller.deployFlow();
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Deploy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
          ),
          child: Column(
            children: [
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
                    child: NodeFlowEditor<AutomationNodeData, void>(
                      controller: controller.nodeFlowController,
                      theme: controller.currentTheme.value,
                      nodeBuilder: (context, node) =>
                          _buildCustomNode(node, isDark),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
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
          _ToolbarItem(
            icon: Icons.bolt,
            label: 'Trigger',
            color: Colors.amber,
            onPressed: () => _addNode('trigger'),
          ),
          const SizedBox(width: 16),
          _ToolbarItem(
            icon: Icons.alt_route,
            label: 'Condition',
            color: Colors.purple,
            onPressed: () => _addNode('condition'),
          ),
          const SizedBox(width: 16),
          _ToolbarItem(
            icon: Icons.play_arrow,
            label: 'Action',
            color: Colors.blue,
            onPressed: () => _addNode('action'),
          ),
          const SizedBox(width: 16),
          _ToolbarItem(
            icon: Icons.text_fields,
            label: 'Text Field',
            color: Colors.teal,
            onPressed: () => _addNode('text_field'),
          ),
          const SizedBox(width: 16),
          _ToolbarItem(
            icon: Icons.help_outline,
            label: 'Question',
            color: Colors.orange,
            onPressed: () => _addNode('question'),
          ),
          const SizedBox(width: 16),
          _ToolbarItem(
            icon: Icons.stop_circle_outlined,
            label: 'Stop',
            color: Colors.red,
            onPressed: () => _addNode('stop'),
          ),
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
            content: 'Default text...',
          ),
          ports: [
            Port(
              id: 'in',
              name: 'In',
              type: PortType.input,
              position: PortPosition.left,
            ),
            Port(
              id: 'out',
              name: 'Out',
              type: PortType.output,
              position: PortPosition.right,
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
            ),
            Port(
              id: 'out',
              name: 'Response',
              type: PortType.output,
              position: PortPosition.right,
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
            ),
          ],
        );
    }

    controller.nodeFlowController.addNode(node);
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
                      maxLines: node.type == 'question' ? 3 : 2,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: node.type == 'question'
                            ? 'Ask a question...'
                            : 'Enter value...',
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
      decoration: InputDecoration(
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
