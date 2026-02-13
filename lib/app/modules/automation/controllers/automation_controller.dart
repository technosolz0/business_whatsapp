import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:vyuh_node_flow/vyuh_node_flow.dart';

class AutomationNodeData {
  final String label;
  final String hint;
  String? content;
  final RxList<String> keywords;

  AutomationNodeData({
    required this.label,
    required this.hint,
    this.content,
    List<String>? keywords,
  }) : keywords = (keywords ?? []).obs;

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'hint': hint,
      if (content != null) 'content': content,
      if (keywords.isNotEmpty) 'keywords': keywords.toList(),
    };
  }
}

class AutomationController extends GetxController {
  late final NodeFlowController<AutomationNodeData, void> nodeFlowController;
  final Rx<NodeFlowTheme> currentTheme = Rx<NodeFlowTheme>(NodeFlowTheme.light);

  @override
  void onInit() {
    super.onInit();
    nodeFlowController = NodeFlowController<AutomationNodeData, void>();

    // Initial theme setup based on current brightness
    currentTheme.value = Get.isDarkMode
        ? NodeFlowTheme.dark
        : NodeFlowTheme.light;

    setupInitialNodes();
  }

  void setupInitialNodes() {
    // 1. Add Trigger Node
    nodeFlowController.addNode(
      Node<AutomationNodeData>(
        id: 'trigger-1',
        type: 'trigger',
        position: const Offset(100, 100),
        size: const Size(250, 220),
        data: AutomationNodeData(
          label: 'Incoming Message',
          hint: 'Triggers when a message is received',
          keywords: ['hello', 'hi', 'support'],
        ),
        ports: [
          Port(
            id: 'out',
            name: 'Trigger',
            type: PortType.output,
            position: PortPosition.right,

            offset: const Offset(0, 90),
          ),
        ],
      ),
    );

    // 2. Add Filter Node
    nodeFlowController.addNode(
      Node<AutomationNodeData>(
        id: 'filter-1',
        type: 'condition',
        position: const Offset(450, 100),
        size: const Size(250, 180),
        data: AutomationNodeData(
          label: 'Keyword Match',
          hint: 'Check if message contains "Support"',
        ),
        ports: [
          Port(
            id: 'in',
            name: 'Wait',
            type: PortType.input,
            position: PortPosition.left,
            offset: const Offset(0, 90),
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
            offset: const Offset(0, 90),
          ),
        ],
      ),
    );

    // 3. Add Action Node
    nodeFlowController.addNode(
      Node<AutomationNodeData>(
        id: 'action-1',
        type: 'action',
        position: const Offset(800, 50),
        size: const Size(250, 150),
        data: AutomationNodeData(
          label: 'Assign Dept',
          hint: 'Routes the chat to Support team',
        ),
        ports: [
          Port(
            id: 'in',
            name: 'Do',
            type: PortType.input,
            position: PortPosition.left,
          ),
        ],
      ),
    );

    // 4. Add Action Node (False branch)
    nodeFlowController.addNode(
      Node<AutomationNodeData>(
        id: 'action-2',
        type: 'action',
        position: const Offset(800, 250),
        size: const Size(250, 150),
        data: AutomationNodeData(
          label: 'Auto Reply',
          hint: 'Send "We will get back to you"',
        ),
        ports: [
          Port(
            id: 'in',
            name: 'Do',
            type: PortType.input,
            position: PortPosition.left,
          ),
        ],
      ),
    );

    // 5. Connect them
    nodeFlowController.createConnection('trigger-1', 'out', 'filter-1', 'in');
    nodeFlowController.createConnection('filter-1', 'true', 'action-1', 'in');
    nodeFlowController.createConnection('filter-1', 'false', 'action-2', 'in');
  }

  void setTheme(NodeFlowTheme theme) {
    currentTheme.value = theme;
  }

  void deployFlow() {
    final nodesList = nodeFlowController.nodes.values.map((node) {
      return {
        "id": node.id,
        "type": node.type,
        "x": node.position.value.dx,
        "y": node.position.value.dy,
        "width": node.size.value.width,
        "height": node.size.value.height,
        "ports": node.ports.map((port) {
          return {
            "id": port.id,
            "name": port.name,
            "multiConnections": port.multiConnections,
            "position": port.position.name,
            "offset": {"x": port.offset.dx, "y": port.offset.dy},
            "type": port.type.name,
            "isConnectable": port.isConnectable,
          };
        }).toList(),
        "data": (node.data).toJson(),
        "zIndex": node.zIndex.value,
        "selected": node.selected.value,
        "isVisible": node.isVisible,
        "locked": node.locked,
      };
    }).toList();

    final connectionsList = nodeFlowController.connections.map((conn) {
      return {
        "id": conn.id,
        "sourceNodeId": conn.sourceNodeId,
        "sourcePortId": conn.sourcePortId,
        "targetNodeId": conn.targetNodeId,
        "targetPortId": conn.targetPortId,
      };
    }).toList();

    final result = {
      "nodes": nodesList,
      "connections": connectionsList,
      "viewport": {"x": 0.0, "y": 0.0, "zoom": 1.0},
      "metadata": {},
    };

    // For debugging and user visibility
    debugPrint("--- DEPLOY WORKFLOW DATA ---");
    debugPrint(result.toString());
    debugPrint("----------------------------");

    Get.snackbar(
      'Deployed',
      'Workflow data printed to console!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
}
