import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Node;
import 'package:vyuh_node_flow/vyuh_node_flow.dart';
import '../../../../main.dart';
import '../../../Utilities/api_endpoints.dart';
import '../../../Utilities/network_utilities.dart';
import '../../../Utilities/utilities.dart';
import '../../../common widgets/common_snackbar.dart';
import '../../../controllers/navigation_controller.dart';
import '../../../routes/app_pages.dart';
import '../models/automation_model.dart';

class AutomationController extends GetxController {
  late NodeFlowController<AutomationNodeData, void> nodeFlowController;
  final Rx<NodeFlowTheme> currentTheme = Rx<NodeFlowTheme>(NodeFlowTheme.light);

  // Listing state
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final RxList<AutomationFlowModel> automations = <AutomationFlowModel>[].obs;
  final RxList<AutomationFlowModel> _allAutomations =
      <AutomationFlowModel>[].obs;

  // Pagination state
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalRecords = 0.obs;
  final RxInt total = 0.obs;
  final int pageSize = 10;

  // Create / Edit state
  final RxnString editingFlowId = RxnString(null);
  final RxInt flowKey = 0.obs;
  final TextEditingController flowNameController = TextEditingController();
  final RxString flowNameError = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool hasTriggerNode = false.obs;
  final RxBool hasStopNode = false.obs;
  Timer? _statusTimer;

  bool get canDeploy => hasTriggerNode.value && hasStopNode.value;

  int get startItem {
    if (totalRecords.value == 0) return 0;
    return (currentPage.value - 1) * pageSize + 1;
  }

  int get endItem {
    if (totalRecords.value == 0) return 0;
    return ((currentPage.value - 1) * pageSize + automations.length).clamp(
      0,
      totalRecords.value,
    );
  }

  @override
  void onInit() {
    super.onInit();
    nodeFlowController = NodeFlowController<AutomationNodeData, void>();
    try {
      nodeFlowController.autoPan?.disable();
    } catch (_) {}
    currentTheme.value = Get.isDarkMode
        ? NodeFlowTheme.dark
        : NodeFlowTheme.light;

    setupInitialNodes();
    updateFlowStatus();
    loadAutomationsFromFirebase();
  }

  @override
  void onClose() {
    stopStatusTimer();
    super.onClose();
  }

  void updateFlowStatus() {
    final hasTrigger = nodeFlowController.nodes.values.any(
      (n) => n.type == 'trigger',
    );
    final hasStop = nodeFlowController.nodes.values.any(
      (n) => n.type == 'stop',
    );
    if (hasTriggerNode.value != hasTrigger) {
      hasTriggerNode.value = hasTrigger;
    }
    if (hasStopNode.value != hasStop) {
      hasStopNode.value = hasStop;
    }
  }

  void startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateFlowStatus();
    });
  }

  void stopStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = null;
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE LISTING & CRUD
  // ---------------------------------------------------------------------------

  Future<void> loadAutomationsFromFirebase() async {
    if (clientID.isEmpty) {
      debugPrint('AutomationController: clientID is empty, skipping load.');
      return;
    }

    try {
      isLoading.value = true;
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        '${ApiEndpoints.serverUrl}/api/automations',
        queryParameters: {'client_id': clientID},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['data'] ?? [];
        final all = list
            .map(
              (item) =>
                  AutomationFlowModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();

        _allAutomations.assignAll(all);
        _applyFilter(searchQuery.value);
      }
    } catch (e) {
      debugPrint('Error loading automations from backend: $e');
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to load automations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilter(String query) {
    final filtered = query.isEmpty
        ? _allAutomations.toList()
        : _allAutomations
              .where((a) => a.name.toLowerCase().contains(query.toLowerCase()))
              .toList();

    total.value = _allAutomations.length;
    totalRecords.value = filtered.length;
    totalPages.value = (totalRecords.value / pageSize).ceil().clamp(1, 999);

    final startIndex = (currentPage.value - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalRecords.value);
    automations.assignAll(
      startIndex < totalRecords.value
          ? filtered.sublist(startIndex, endIndex)
          : [],
    );
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    currentPage.value = 1;
    _applyFilter(query);
  }

  void goToNextPage() {
    if (currentPage.value < totalPages.value) {
      currentPage.value++;
      _applyFilter(searchQuery.value);
    }
  }

  void goToPreviousPage() {
    if (currentPage.value > 1) {
      currentPage.value--;
      _applyFilter(searchQuery.value);
    }
  }

  Future<void> deleteAutomation(AutomationFlowModel flow) async {
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.delete(
        '${ApiEndpoints.serverUrl}/api/automations/${flow.id}',
        queryParameters: {'client_id': clientID},
      );

      if (response.statusCode == 200) {
        _allAutomations.removeWhere((a) => a.id == flow.id);
        _applyFilter(searchQuery.value);
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          'Automation "${flow.name}" deleted successfully.',
        );
      }
    } catch (e) {
      debugPrint('Error deleting automation: $e');
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Failed to delete automation: $e',
      );
    }
  }

  Future<void> toggleAutomationStatus(AutomationFlowModel flow) async {
    final newStatus = !flow.isActive.value;
    try {
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        '${ApiEndpoints.serverUrl}/api/automations/${flow.id}/toggle',
        queryParameters: {'client_id': clientID},
        data: {'status': newStatus ? 'Active' : 'Inactive'},
      );

      if (response.statusCode == 200) {
        flow.isActive.value = newStatus;
        Utilities.showSnackbar(
          SnackType.SUCCESS,
          'Automation is now ${newStatus ? 'Active' : 'Inactive'}.',
        );
      }
    } catch (e) {
      debugPrint('Error toggling automation status: $e');
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to update status: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // CANVAS BUILDER & EDITING
  // ---------------------------------------------------------------------------

  void setTheme(NodeFlowTheme theme) {
    currentTheme.value = theme;
  }

  void resetFlow({bool clearSearch = true}) {
    editingFlowId.value = null;
    flowNameController.clear();
    flowNameError.value = '';
    if (clearSearch) {
      searchQuery.value = '';
      searchController.clear();
      currentPage.value = 1;
    }

    nodeFlowController = NodeFlowController<AutomationNodeData, void>();
    setupInitialNodes();
    startStatusTimer();
    updateFlowStatus();
    flowKey.value++;
  }

  Future<void> loadAutomationForEdit(AutomationFlowModel flow) async {
    try {
      Utilities.showOverlayLoadingDialog();
      final dio = NetworkUtilities.getDioClient();
      final response = await dio.get(
        '${ApiEndpoints.serverUrl}/api/automations/${flow.id}',
        queryParameters: {'client_id': clientID},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        final uiFlowRaw = data?['ui_flow'];

        editingFlowId.value = flow.id;
        flowNameController.text = flow.name;
        flowNameError.value = '';

        nodeFlowController = NodeFlowController<AutomationNodeData, void>();
        if (uiFlowRaw != null && uiFlowRaw.toString().isNotEmpty) {
          final Map<String, dynamic> jsonMap = uiFlowRaw is Map
              ? Map<String, dynamic>.from(uiFlowRaw)
              : jsonDecode(uiFlowRaw.toString());

          final graph = NodeGraph<AutomationNodeData, void>.fromJson(
            jsonMap,
            (n) => AutomationNodeData.fromJson(
              Map<String, dynamic>.from(n as Map),
            ),
            (_) {},
          );
          nodeFlowController.loadGraph(graph);
        } else {
          setupInitialNodes();
        }
        startStatusTimer();
        updateFlowStatus();
        flowKey.value++;

        Utilities.hideCustomLoader(Get.context!);

        if (Get.isRegistered<NavigationController>()) {
          final nav = Get.find<NavigationController>();
          nav.currentRoute.value = Routes.CREATE_AUTOMATION;
          nav.selectedIndex.value = 12;
          nav.routeTrigger.value++;
        }
      } else {
        Utilities.hideCustomLoader(Get.context!);
        Utilities.showSnackbar(SnackType.ERROR, 'Failed to load flow data.');
      }
    } catch (e) {
      Utilities.hideCustomLoader(Get.context!);
      debugPrint('Error loading automation for edit: $e');
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to load flow: $e');
    }
  }

  void setupInitialNodes() {
    try {
      nodeFlowController.autoPan?.disable();
    } catch (_) {}

    // 1. Trigger Node
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
            name: 'Success',
            type: PortType.output,
            position: PortPosition.right,
            offset: const Offset(0, 110),
          ),
        ],
      ),
    );

    // 2. Stop Node
    nodeFlowController.addNode(
      Node<AutomationNodeData>(
        id: 'stop-1',
        type: 'stop',
        position: const Offset(450, 100),
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
      ),
    );

    // 3. Connect Trigger -> Stop by default
    nodeFlowController.createConnection('trigger-1', 'out', 'stop-1', 'in');
  }

  // ---------------------------------------------------------------------------
  // FLOW DEPLOYMENT & LOGICAL TRANSLATION
  // ---------------------------------------------------------------------------

  Future<void> deployFlow() async {
    final name = flowNameController.text.trim();
    if (name.isEmpty) {
      flowNameError.value = 'Flow Name is required';
      Utilities.showSnackbar(SnackType.ERROR, 'Flow Name cannot be empty.');
      return;
    } else {
      flowNameError.value = '';
    }

    if (!canDeploy) {
      Utilities.showSnackbar(
        SnackType.ERROR,
        'Flow must have at least one Trigger node and one Stop node.',
      );
      return;
    }

    // Clean unconnected blocks (except Trigger)
    final connectedNodeIds = <String>{};
    for (var conn in nodeFlowController.connections) {
      connectedNodeIds.add(conn.sourceNodeId);
      connectedNodeIds.add(conn.targetNodeId);
    }

    final nodesToRemove = <String>[];
    for (var node in nodeFlowController.nodes.values) {
      if (node.type == 'trigger') continue;
      if (!connectedNodeIds.contains(node.id)) {
        nodesToRemove.add(node.id);
      }
    }

    if (nodesToRemove.isNotEmpty) {
      for (var id in nodesToRemove) {
        nodeFlowController.removeNode(id);
      }
      Utilities.showSnackbar(
        SnackType.INFO,
        'Cleaned ${nodesToRemove.length} unconnected block(s).',
      );
    }

    final graph = nodeFlowController.exportGraph();
    final result = graph.toJson((data) => data.toJson(), (_) => null);

    await _saveAutomationToFirebase(name: name, result: result);
  }

  Future<void> _saveAutomationToFirebase({
    required String name,
    required Map<String, dynamic> result,
  }) async {
    try {
      isLoading.value = true;
      final isEditing = editingFlowId.value != null;
      final String docId = isEditing
          ? editingFlowId.value!
          : DateTime.now().millisecondsSinceEpoch.toString();

      final logicalData = _convertToLogicalJson(docId, clientID);

      final Map<String, dynamic> automationData = {
        'id': docId,
        'clientId': clientID,
        'flowName': name,
        'status': 'Active',
        'ui_flow': jsonEncode(result),
        'trigger_keywords': logicalData['trigger_keywords'],
        'start_node': logicalData['start_node'],
        'nodes': logicalData['nodes'],
      };

      final dio = NetworkUtilities.getDioClient();
      final response = await dio.post(
        '${ApiEndpoints.serverUrl}/api/automations',
        data: automationData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        resetFlow();
        await loadAutomationsFromFirebase();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.closeAllSnackbars();
          if (Get.isRegistered<NavigationController>()) {
            Get.find<NavigationController>().currentRoute.value =
                Routes.AUTOMATION;
          }
          if (Get.key.currentState?.canPop() == true ||
              (Get.context != null && Navigator.canPop(Get.context!))) {
            Get.back();
          } else {
            Get.offNamed(Routes.AUTOMATION);
          }

          Future.delayed(const Duration(milliseconds: 250), () {
            Utilities.showSnackbar(
              SnackType.SUCCESS,
              isEditing
                  ? 'Automation updated successfully!'
                  : 'Automation deployed successfully!',
            );
          });
        });
      } else {
        throw Exception(
          response.data?['detail'] ?? 'Failed to save automation',
        );
      }
    } catch (e) {
      debugPrint('Error saving automation: $e');
      Utilities.showSnackbar(SnackType.ERROR, 'Failed to save automation: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _convertToLogicalJson(String flowId, String clientID) {
    final nodesJson = <String, Map<String, dynamic>>{};
    final List<String> triggerKeywords = [];
    String? startNodeId;

    // 1. Find trigger keywords & start_node
    for (var node in nodeFlowController.nodes.values) {
      if (node.type == 'trigger') {
        triggerKeywords.addAll(node.data.keywords);
        final connectionToTrigger = nodeFlowController.connections
            .where((c) => c.sourceNodeId == node.id)
            .firstOrNull;
        if (connectionToTrigger != null) {
          startNodeId = connectionToTrigger.targetNodeId;
        }
      }
    }

    // 2. Map every logical node
    for (var node in nodeFlowController.nodes.values) {
      if (node.type == 'trigger') continue;

      final nodeType = _mapNodeType(node.type);
      final Map<String, dynamic> logicalNode = {
        'type': nodeType,
        'label': node.data.label,
        'content': node.data.content ?? '',
      };

      final outgoingConnections = nodeFlowController.connections
          .where((c) => c.sourceNodeId == node.id)
          .toList();

      // Condition Node: True and False branches
      if (nodeType == 'condition') {
        logicalNode['operator'] = node.data.operator;
        logicalNode['condition_value'] =
            node.data.conditionValue ?? node.data.content ?? '';

        for (var conn in outgoingConnections) {
          if (conn.sourcePortId == 'true') {
            logicalNode['true_node'] = conn.targetNodeId;
          } else if (conn.sourcePortId == 'false') {
            logicalNode['false_node'] = conn.targetNodeId;
          }
        }
      }
      // Action Node
      else if (nodeType == 'action') {
        logicalNode['action_type'] = node.data.actionType;
        logicalNode['action_value'] =
            node.data.actionValue ?? node.data.content ?? '';
        if (outgoingConnections.isNotEmpty) {
          logicalNode['next_node'] = outgoingConnections.first.targetNodeId;
        }
      }
      // Menu / Question Node
      else if (nodeType == 'menu' || nodeType == 'question') {
        final options = <String, String>{};
        for (var conn in outgoingConnections) {
          final port = node.ports
              .where((p) => p.id == conn.sourcePortId)
              .firstOrNull;
          final optionLabel = port?.name ?? conn.sourcePortId;
          options[optionLabel] = conn.targetNodeId;
        }
        if (options.isNotEmpty) {
          logicalNode['options'] = options;
        }
        if (outgoingConnections.isNotEmpty) {
          logicalNode['next_node'] = outgoingConnections.first.targetNodeId;
        }
      }
      // Message / Text Field Node
      else {
        if (outgoingConnections.isNotEmpty) {
          logicalNode['next_node'] = outgoingConnections.first.targetNodeId;
        }
      }

      nodesJson[node.id] = logicalNode;
    }

    return {
      'flow_id': flowId,
      'client_id': clientID,
      'trigger_keywords': triggerKeywords,
      'start_node': startNodeId,
      'nodes': nodesJson,
    };
  }

  String _mapNodeType(String type) {
    switch (type) {
      case 'text_field':
        return 'message';
      case 'condition':
        return 'condition';
      case 'action':
        return 'action';
      case 'question':
        return 'menu';
      case 'stop':
        return 'stop';
      default:
        return type;
    }
  }
}
